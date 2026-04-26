# CLAUDE.ja.md

このファイルはClaude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## 概要

WSL2環境用のdotfilesリポジトリ。シェル設定、プロンプト、プラグイン、モダンCLIツールのセットアップを管理。

## セットアップ

```bash
# ~/dotfiles にクローン（cheat関数で必要なパス）
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# システムアップグレードをスキップ
SKIP_UPGRADE=1 ./install.sh
```

## ファイル構成

- `.zshrc` - zshメイン設定（エイリアス、関数、ツール初期化）
- `.config/starship.toml` - Starshipプロンプト設定
- `.config/sheldon/plugins.toml` - Sheldon zshプラグイン定義
- `.gitconfig.delta` - delta使用のgit diff設定
- `cheatsheet.md` - インストール済みツールのクイックリファレンス（`cheat`コマンドでアクセス）
- `claude/hooks/pre-tool-use.sh` - PreToolUse安全フック（危険なBashコマンドをブロック）
- `claude/scripts/safe-claude` - gitスナップショット付き安全エージェントセッション用ラッパー
- `claude/scripts/claude-audit` - ツール使用履歴のセッション監査ツール
- `claude/settings.template.json` - 権限+フック設定テンプレート
- `docs/claude-safe-usage.md` - 包括的な安全使用ガイド（EN）
- `docs/claude-safe-usage.ja.md` - 包括的な安全使用ガイド（JA）
- `install.sh` - WSL2 Ubuntu用ワンショットセットアップスクリプト
- `install-secure.sh` - エージェント専用セキュアWSL2 Distro用初期化スクリプト（interop/automount/Windows PATH無効化）
- `uninstall.sh` - シンボリックリンクとgit設定を削除

## テスト

クリーン環境での変更テスト:

```bash
# 新しいWSL2インスタンスを作成
wsl --install -d Ubuntu-24.04 --name TestInstance

# または既存のディストロを使用
wsl -d TestInstance

# インストールスクリプトを実行
./install.sh

# 主要ツールの動作確認
zsh --version
starship --version
mise --version
```

## 主な規約

- `.zshrc`はsymlink方式ではなくsource方式（`source ~/dotfiles/.zshrc`）を使用。外部ツールが`~/.zshrc`に追記してもdotfilesリポジトリが汚れない
- その他の設定ファイルは`~/dotfiles/`から`$HOME`にシンボリックリンクを作成（例: `~/.vimrc` → `~/dotfiles/.vimrc`）
- aptにないツールはHomebrew経由でインストール（`eza`, `sheldon`, `lazygit`, `git-delta`, `fzf`, `bat`, `ripgrep`, `fd`, `thefuck`, `glow`）
- `yq`はpip3経由でインストール（apt/brewにないため）
- `cheat`関数は`$HOME/dotfiles/`または`$DOTFILES_DIR`にdotfilesがあることを想定
- WSL2固有の機能は`$WSL_DISTRO_NAME`が設定されている場合のみ読み込み
