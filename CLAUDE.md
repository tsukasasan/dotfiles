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
- `install.sh` - One-shot setup script for fresh WSL2 Ubuntu
- `uninstall.sh` - Remove symlinks and git config entries

## Key Conventions

- Symlinks are created from `~/dotfiles/` to `$HOME` (e.g., `~/.zshrc` → `~/dotfiles/.zshrc`)
- Tools not in apt are installed via Homebrew (`eza`, `sheldon`, `lazygit`, `git-delta`, `fzf`, `bat`, `ripgrep`, `fd`, `thefuck`, `glow`)
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
