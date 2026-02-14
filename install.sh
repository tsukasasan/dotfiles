#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_UPGRADE="${SKIP_UPGRADE:-0}"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ==============================================================================
# Color output helpers
# ==============================================================================
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m   $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERR]\033[0m  $*"; exit 1; }

# ==============================================================================
# Backup helper
# ==============================================================================
backup_if_exists() {
  local file="$1"
  if [[ -f "$file" && ! -L "$file" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$file" "$BACKUP_DIR/"
    warn "Backed up: $file -> $BACKUP_DIR/"
  fi
}

# ==============================================================================
# 1. Sudo NOPASSWD (WSL2 local development)
# ==============================================================================
SUDOERS_FILE="/etc/sudoers.d/$USER"
if [[ ! -f "$SUDOERS_FILE" ]]; then
  info "Configuring sudo NOPASSWD for $USER..."
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  ok "Sudo NOPASSWD configured"
else
  ok "Sudo NOPASSWD already configured"
fi

# ==============================================================================
# 2. System packages (apt)
# ==============================================================================
info "Updating apt..."
sudo apt update -qq

if [[ "$SKIP_UPGRADE" != "1" ]]; then
  info "Upgrading system packages (skip with SKIP_UPGRADE=1)..."
  sudo apt upgrade -y -qq
fi

info "Installing system packages..."
sudo apt install -y -qq \
  zsh \
  git \
  gh \
  curl \
  wget \
  unzip \
  zip \
  jq \
  build-essential \
  zoxide \
  entr \
  btop \
  trash-cli

ok "System packages installed"

# ==============================================================================
# 3. Homebrew (for packages not in apt)
# ==============================================================================
if ! command -v brew &> /dev/null; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

info "Installing brew packages..."
brew install eza sheldon lazygit git-delta fzf bat ripgrep fd thefuck glow

ok "Brew packages installed"

# ==============================================================================
# 3.5. yq (pip install - not available in apt/brew)
# ==============================================================================
if ! command -v yq &> /dev/null; then
  info "Installing yq (YAML/TOML processor)..."
  # Ensure pip3 is available
  if ! command -v pip3 &> /dev/null; then
    info "Installing python3-pip..."
    sudo apt install -y -qq python3-pip
  fi
  pip3 install yq --break-system-packages 2>/dev/null || pip3 install yq
fi
ok "yq installed"

# ==============================================================================
# 4. Starship
# ==============================================================================
if ! command -v starship &> /dev/null; then
  info "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
ok "Starship installed"

# ==============================================================================
# 5. mise
# ==============================================================================
if ! command -v mise &> /dev/null; then
  info "Installing mise..."
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

info "Installing Node.js (latest stable) via mise..."
mise use --global node@lts
ok "mise + Node.js installed"

# ==============================================================================
# 6. AWS CLI + SSM Plugin
# ==============================================================================
if ! command -v aws &> /dev/null; then
  info "Installing AWS CLI v2..."
  TMPDIR=$(mktemp -d)
  curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMPDIR/awscliv2.zip"
  unzip -q "$TMPDIR/awscliv2.zip" -d "$TMPDIR"
  sudo "$TMPDIR/aws/install"
  rm -rf "$TMPDIR"
fi

if ! command -v session-manager-plugin &> /dev/null; then
  info "Installing SSM Session Manager Plugin..."
  TMPDIR=$(mktemp -d)
  curl -sL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "$TMPDIR/ssm.deb"
  sudo dpkg -i "$TMPDIR/ssm.deb"
  rm -rf "$TMPDIR"
fi
ok "AWS CLI + SSM Plugin installed"

# ==============================================================================
# 7. Claude Code (native installer - recommended by Anthropic)
# ==============================================================================
if ! command -v claude &> /dev/null; then
  info "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  # Add to PATH so it works before shell reload
  export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"
fi
ok "Claude Code installed (run 'claude' to authenticate)"

# ==============================================================================
# 8. Symlinks
# ==============================================================================
info "Creating symlinks..."

# Backup existing files before creating symlinks
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.config/sheldon/plugins.toml"
backup_if_exists "$HOME/.gitconfig.delta"
backup_if_exists "$HOME/.gitignore_global"

ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
# cheatsheet.md is accessed directly via cheat() function, no symlink needed
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config/sheldon"
ln -sf "$DOTFILES_DIR/.config/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

# delta settings for git (include method, non-destructive to existing .gitconfig)
ln -sf "$DOTFILES_DIR/.gitconfig.delta" "$HOME/.gitconfig.delta"
if ! git config --global --get-all include.path 2>/dev/null | grep -q '.gitconfig.delta'; then
  git config --global --add include.path "$HOME/.gitconfig.delta"
fi

# global gitignore
ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesfile "$HOME/.gitignore_global"

ok "Symlinks created"

# ==============================================================================
# 9. Change default shell to zsh
# ==============================================================================
if [[ "$SHELL" != *"zsh"* ]]; then
  info "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi
ok "Default shell set to zsh"

# ==============================================================================
# 10. Initialize sheldon plugins
# ==============================================================================
info "Initializing sheldon plugins (this may take a moment)..."
zsh -c 'eval "$(sheldon source)"' 2>/dev/null || true
ok "Sheldon plugins initialized"

# ==============================================================================
# Done
# ==============================================================================
echo ""
echo -e "\033[1;32m========================================\033[0m"
echo -e "\033[1;32m  Setup complete! Open a new terminal.  \033[0m"
echo -e "\033[1;32m========================================\033[0m"
echo ""
echo "Installed:"
echo "  zsh, starship, sheldon, fzf, mise"
echo "  eza, bat, ripgrep, fd, zoxide, lazygit, delta, thefuck"
echo "  yq, trash-cli, entr, btop"
echo "  Claude Code, Node.js $(node --version 2>/dev/null || echo '(pending)'), AWS CLI, SSM Plugin"
