#!/bin/bash
set -euo pipefail

# ==============================================================================
# Color output helpers
# ==============================================================================
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m   $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }

# ==============================================================================
# Remove symlinks
# ==============================================================================
info "Removing symlinks..."

remove_symlink() {
  local file="$1"
  if [[ -L "$file" ]]; then
    rm "$file"
    ok "Removed: $file"
  else
    warn "Not a symlink (skipped): $file"
  fi
}

remove_symlink "$HOME/.zshrc"
remove_symlink "$HOME/.config/starship.toml"
remove_symlink "$HOME/.config/sheldon/plugins.toml"
remove_symlink "$HOME/.gitconfig.delta"
remove_symlink "$HOME/.gitignore_global"

# ==============================================================================
# Remove git config entries
# ==============================================================================
info "Removing git config entries..."

# Remove delta include
if git config --global --get-all include.path 2>/dev/null | grep -q '.gitconfig.delta'; then
  git config --global --unset include.path "$HOME/.gitconfig.delta" 2>/dev/null || true
  ok "Removed git include.path for .gitconfig.delta"
fi

# Remove global gitignore
if [[ "$(git config --global core.excludesfile 2>/dev/null)" == "$HOME/.gitignore_global" ]]; then
  git config --global --unset core.excludesfile
  ok "Removed git core.excludesfile"
fi

# ==============================================================================
# Restore backups (optional)
# ==============================================================================
BACKUP_DIR="$HOME/.dotfiles_backup"
if [[ -d "$BACKUP_DIR" ]]; then
  echo ""
  info "Backups found in $BACKUP_DIR"
  echo "To restore, manually copy files from the latest backup directory."
  ls -1d "$BACKUP_DIR"/*/ 2>/dev/null | tail -5
fi

# ==============================================================================
# Done
# ==============================================================================
echo ""
echo -e "\033[1;32m========================================\033[0m"
echo -e "\033[1;32m  Uninstall complete.                   \033[0m"
echo -e "\033[1;32m========================================\033[0m"
echo ""
echo "Notes:"
echo "  - Installed packages (apt/brew) were NOT removed"
echo "  - To change shell back: chsh -s /bin/bash"
echo "  - To remove dotfiles repo: rm -rf ~/dotfiles"
