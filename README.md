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
- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script
- `LICENSE` - MIT License

## Installed Tools

- **Shell**: zsh, starship, sheldon, fzf
- **Zsh Plugins**: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search
- **Modern CLI**: eza, bat, ripgrep, fd, zoxide, delta, thefuck, glow
- **Utilities**: lazygit, mise, jq, yq, trash-cli, entr, btop
- **Git**: git, gh (GitHub CLI)
- **Cloud**: AWS CLI, SSM Plugin
- **AI**: Claude Code

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
