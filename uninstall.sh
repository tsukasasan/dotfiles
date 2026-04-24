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
remove_symlink "$HOME/.vimrc"
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
# Remove Claude Code safety layer
# ==============================================================================
info "Removing Claude Code safety layer..."

remove_symlink "$HOME/.claude/hooks/pre-tool-use.sh"
remove_symlink "$HOME/.local/bin/safe-claude"
remove_symlink "$HOME/.local/bin/claude-audit"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$DOTFILES_DIR/claude/settings.template.json"

if [[ -f "$CLAUDE_SETTINGS" && -f "$TEMPLATE" ]]; then
  info "Removing merged safety rules from Claude Code settings..."
  CLEANED="$(jq -s '
    (.[0].permissions.allow // []) as $tpl_allow |
    (.[0].permissions.deny // []) as $tpl_deny |
    .[1] | .permissions.allow = ([.permissions.allow // [] | .[] | select(. as $item | $tpl_allow | index($item) | not)]) |
    .permissions.deny = ([.permissions.deny // [] | .[] | select(. as $item | $tpl_deny | index($item) | not)]) |
    .hooks.PreToolUse = ([.hooks.PreToolUse // [] | .[] | select(.hooks[0].command != "~/.claude/hooks/pre-tool-use.sh")]) |
    if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end |
    if (.hooks | length) == 0 then del(.hooks) else . end |
    if (.permissions.allow | length) == 0 then del(.permissions.allow) else . end |
    if (.permissions.deny | length) == 0 then del(.permissions.deny) else . end |
    if (.permissions | length) == 0 then del(.permissions) else . end
  ' "$TEMPLATE" "$CLAUDE_SETTINGS")"
  echo "$CLEANED" | jq '.' > "$CLAUDE_SETTINGS.tmp"
  mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
  ok "Safety rules removed from settings.json"
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
