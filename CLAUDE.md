# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

- Follow `.editorconfig` for code formatting
- Write `*.md` files in English, then sync Japanese version to `*.ja.md`
- `install.sh` must be idempotent (safe to run multiple times)

## Overview

Dotfiles repository for WSL2 environment. Manages shell configuration, prompt, plugins, and modern CLI tool setup.

## Setup

```bash
# Clone to ~/dotfiles (required path for cheat function)
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# Skip system upgrade
SKIP_UPGRADE=1 ./install.sh
```

## File Structure

- `.zshrc` - Main zsh configuration (aliases, functions, tool initialization)
- `.config/starship.toml` - Starship prompt configuration
- `.config/sheldon/plugins.toml` - Sheldon zsh plugin definitions
- `.gitconfig.delta` - Git diff settings using delta
- `cheatsheet.md` - Quick reference for installed tools (accessed via `cheat` command)
- `claude/hooks/pre-tool-use.sh` - PreToolUse safety hook (blocks dangerous Bash commands)
- `claude/scripts/safe-claude` - Wrapper with git snapshot for safe agent sessions
- `claude/scripts/claude-audit` - Session audit tool for reviewing tool usage
- `claude/settings.template.json` - Curated permissions + hooks config template
- `docs/claude-safe-usage.md` - Comprehensive safe usage guide (EN)
- `docs/claude-safe-usage.ja.md` - Comprehensive safe usage guide (JA)
- `install.sh` - One-shot setup script for fresh WSL2 Ubuntu
- `uninstall.sh` - Remove symlinks and git config entries

## Key Conventions

- `.zshrc` uses source method (`source ~/dotfiles/.zshrc`) instead of symlink, so external tools can append to `~/.zshrc` without polluting the dotfiles repo
- Other config files use symlinks from `~/dotfiles/` to `$HOME` (e.g., `~/.vimrc` → `~/dotfiles/.vimrc`)
- Most CLI tools are installed via Homebrew (`eza`, `sheldon`, `lazygit`, `git-delta`, `fzf`, `bat`, `ripgrep`, `fd`, `thefuck`, `glow`, `gh`, `zoxide`, `entr`, `btop`, `trash-cli`, `jq`, `starship`, `mise`)
- `yq` is installed via pip3 (not in apt/brew)
- The `cheat` function expects dotfiles at `$HOME/dotfiles/` or `$DOTFILES_DIR`
- WSL2-specific features are conditionally loaded when `$WSL_DISTRO_NAME` is set

## Testing

To test changes on a fresh environment:

```bash
# Create a new WSL2 instance
wsl --install -d Ubuntu-24.04 --name TestInstance

# Or use existing distro
wsl -d TestInstance

# Run install script
./install.sh

# Verify key tools work
zsh --version
starship --version
mise --version
```
