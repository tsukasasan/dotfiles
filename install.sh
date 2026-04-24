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
  curl \
  wget \
  unzip \
  zip \
  build-essential \
  dnsutils \
  wslu

ok "System packages installed"

# Generate locales (en_US.UTF-8 for LANG, ja_JP.UTF-8 for LC_CTYPE)
LOCALES_TO_GEN=()
locale -a 2>/dev/null | grep -q 'en_US.utf8' || LOCALES_TO_GEN+=(en_US.UTF-8)
locale -a 2>/dev/null | grep -q 'ja_JP.utf8' || LOCALES_TO_GEN+=(ja_JP.UTF-8)
if [[ ${#LOCALES_TO_GEN[@]} -gt 0 ]]; then
  info "Generating locales: ${LOCALES_TO_GEN[*]}..."
  for loc in "${LOCALES_TO_GEN[@]}"; do
    sudo locale-gen "$loc"
  done
  ok "Locales generated"
else
  ok "Required locales already available"
fi

# ==============================================================================
# 3. Homebrew (primary package manager for CLI tools)
# ==============================================================================
if ! command -v brew &> /dev/null; then
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

info "Installing brew packages..."
brew install \
  eza sheldon lazygit git-delta fzf bat ripgrep fd thefuck glow \
  gh zoxide entr btop trash-cli jq starship mise

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
# 4. mise
# ==============================================================================
info "Installing Node.js (latest stable) via mise..."
mise use --global node@lts
ok "mise + Node.js installed"

# ==============================================================================
# 5. AWS CLI + SSM Plugin
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
# 6. Claude Code (native installer - recommended by Anthropic)
# ==============================================================================
if ! command -v claude &> /dev/null; then
  info "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  # Add to PATH so it works before shell reload
  export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"
fi
ok "Claude Code installed (run 'claude' to authenticate)"

# ==============================================================================
# 7. Symlinks
# ==============================================================================
info "Creating symlinks..."

# Backup existing files before creating symlinks
backup_if_exists "$HOME/.config/starship.toml"
backup_if_exists "$HOME/.config/sheldon/plugins.toml"
backup_if_exists "$HOME/.gitconfig.delta"
backup_if_exists "$HOME/.gitignore_global"

# .zshrc: source method instead of symlink (prevents external tools from polluting dotfiles repo)
ZSHRC_SOURCE="source \"$DOTFILES_DIR/.zshrc\""
if [[ ! -f "$HOME/.zshrc" ]] || ! grep -qF "$ZSHRC_SOURCE" "$HOME/.zshrc"; then
  # Prepend source line so dotfiles config loads first, external tool additions come after
  if [[ -f "$HOME/.zshrc" ]]; then
    backup_if_exists "$HOME/.zshrc"
    EXISTING="$(cat "$HOME/.zshrc")"
    echo "$ZSHRC_SOURCE" > "$HOME/.zshrc"
    echo "$EXISTING" >> "$HOME/.zshrc"
  else
    echo "$ZSHRC_SOURCE" > "$HOME/.zshrc"
  fi
fi
# Remove stale symlink if upgrading from symlink method
if [[ -L "$HOME/.zshrc" ]]; then
  rm "$HOME/.zshrc"
  echo "$ZSHRC_SOURCE" > "$HOME/.zshrc"
fi

ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
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
# 8. Change default shell to zsh
# ==============================================================================
if [[ "$SHELL" != *"zsh"* ]]; then
  info "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi
ok "Default shell set to zsh"

# ==============================================================================
# 9. Initialize sheldon plugins
# ==============================================================================
info "Initializing sheldon plugins (this may take a moment)..."
zsh -c 'eval "$(sheldon source)"' 2>/dev/null || true
ok "Sheldon plugins initialized"

# ==============================================================================
# 10. Claude Code Safety (hooks, scripts, permissions)
# ==============================================================================
info "Setting up Claude Code safety layer..."

CLAUDE_DIR="$HOME/.claude"
CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
TEMPLATE="$DOTFILES_DIR/claude/settings.template.json"

# Create directories
mkdir -p "$CLAUDE_HOOKS_DIR"
mkdir -p "$HOME/.local/bin"

# Symlink hook script
ln -sf "$DOTFILES_DIR/claude/hooks/pre-tool-use.sh" "$CLAUDE_HOOKS_DIR/pre-tool-use.sh"

# Symlink wrapper scripts
ln -sf "$DOTFILES_DIR/claude/scripts/safe-claude" "$HOME/.local/bin/safe-claude"
ln -sf "$DOTFILES_DIR/claude/scripts/claude-audit" "$HOME/.local/bin/claude-audit"

# Merge settings.template.json into existing settings.json (preserve existing rules)
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  info "Merging Claude Code safety settings (preserving existing rules)..."
  # Merge allow arrays (union), merge deny arrays (union), merge hooks
  MERGED="$(jq -s '
    # $template is .[0], $existing is .[1]
    (.[0].permissions.allow // []) as $tpl_allow |
    (.[1].permissions.allow // []) as $ext_allow |
    (.[0].permissions.deny // []) as $tpl_deny |
    (.[1].permissions.deny // []) as $ext_deny |
    (.[0].hooks // {}) as $tpl_hooks |
    (.[1].hooks // {}) as $ext_hooks |
    .[1] * {
      permissions: {
        allow: ($ext_allow + ($tpl_allow - $ext_allow)),
        deny: ($ext_deny + ($tpl_deny - $ext_deny))
      },
      hooks: (
        # Merge hook arrays by key
        ($ext_hooks | keys) as $ek |
        ($tpl_hooks | keys) as $tk |
        ($ek + ($tk - $ek)) | unique | map(
          . as $key |
          if ($ext_hooks[$key] // null) != null and ($tpl_hooks[$key] // null) != null then
            {($key): (($ext_hooks[$key] // []) + (($tpl_hooks[$key] // []) | map(
              select(. as $item | ($ext_hooks[$key] // []) | map(.matcher == $item.matcher and .hooks == $item.hooks) | any | not)
            )))}
          elif ($tpl_hooks[$key] // null) != null then
            {($key): $tpl_hooks[$key]}
          else
            {($key): $ext_hooks[$key]}
          end
        ) | add // {}
      )
    }
  ' "$TEMPLATE" "$CLAUDE_SETTINGS")"
  echo "$MERGED" | jq '.' > "$CLAUDE_SETTINGS.tmp"
  mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
else
  info "Creating Claude Code settings from template..."
  cp "$TEMPLATE" "$CLAUDE_SETTINGS"
fi

ok "Claude Code safety layer configured"

# ==============================================================================
# Done
# ==============================================================================
echo ""
echo -e "\033[1;32m========================================\033[0m"
echo -e "\033[1;32m  Setup complete! Open a new terminal.  \033[0m"
echo -e "\033[1;32m========================================\033[0m"
echo ""
echo "Installed:"
echo "  [apt] zsh, git, curl, wget, build-essential"
echo "  [brew] eza, sheldon, lazygit, delta, fzf, bat, ripgrep, fd, thefuck, glow"
echo "  [brew] gh, zoxide, entr, btop, trash-cli, jq, starship, mise"
echo "  [pip] yq"
echo "  [other] Claude Code, Node.js $(node --version 2>/dev/null || echo '(pending)'), AWS CLI, SSM Plugin"
