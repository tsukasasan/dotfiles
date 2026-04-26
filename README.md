# dotfiles

Dotfiles repository for WSL2 environment

## Prerequisites

- WSL2 with Ubuntu 24.04+ (or Debian-based distro)
- Git installed
- Sudo access

## Setup

```bash
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Secure WSL2 distro for AI agents

For running Claude Code and other AI agents in an isolated environment (no `/mnt/c`, no Windows interop), see [`docs/wsl-secure-setup.md`](docs/wsl-secure-setup.md). Create a separate distro and run `install-secure.sh` inside it.

## Included Files

- `.zshrc` - zsh configuration
- `.config/starship.toml` - Starship prompt configuration
- `.config/sheldon/plugins.toml` - Sheldon plugin configuration
- `.gitconfig.delta` - delta settings for git diff
- `.gitignore_global` - global gitignore (credentials, OS files, etc.)
- `.gitignore` - repository gitignore
- `.gitattributes` - git attributes (LF enforcement, diff settings)
- `.editorconfig` - editor configuration
- `cheatsheet.md` - Command cheatsheet
- `claude/hooks/pre-tool-use.sh` - Claude Code safety hook (blocks dangerous commands)
- `claude/scripts/safe-claude` - Claude Code wrapper with git snapshot
- `claude/scripts/claude-audit` - Claude Code session audit tool
- `claude/settings.template.json` - Claude Code permissions template
- `docs/claude-safe-usage.md` - Claude Code safe usage guide
- `docs/claude-safe-usage.ja.md` - Claude Code safe usage guide (JA)
- `docs/wsl-secure-setup.md` - Secure WSL2 distro setup guide for agent execution
- `docs/wsl-secure-setup.ja.md` - Secure WSL2 distro setup guide (JA)
- `install.sh` - Installation script
- `install-secure.sh` - Initialization script for the secure WSL2 distro
- `uninstall.sh` - Uninstallation script
- `LICENSE` - MIT License

## Installed Tools

- **Shell**: zsh, starship, sheldon, fzf
- **Zsh Plugins**: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search
- **Modern CLI**: eza, bat, ripgrep, fd, zoxide, delta, thefuck, glow
- **Utilities**: lazygit, mise, jq, yq, trash-cli, entr, btop
- **Git**: git, gh (GitHub CLI)
- **Cloud**: AWS CLI, SSM Plugin
- **AI**: Claude Code, safe-claude, claude-audit

Use `cheat -l` to list available cheatsheets, `cheat <tool>` to view.

## Updating

```bash
cd ~/dotfiles
git pull
./install.sh
```

## Uninstall

```bash
cd ~/dotfiles
./uninstall.sh
```

This removes symlinks and git config entries. Installed packages are not removed.

## Environment Variables

- `SKIP_UPGRADE=1` - Skip apt upgrade during installation
- `DOTFILES_DIR` - Override dotfiles location (default: `~/dotfiles`)

## Troubleshooting

- **Skip system upgrade**: `SKIP_UPGRADE=1 ./install.sh`
- **Homebrew not found**: Restart terminal or run `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`
- **Restore backups**: Check `~/.dotfiles_backup/` for previous configs
