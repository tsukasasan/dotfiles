# dotfiles

WSL2環境用のdotfilesリポジトリ

## 前提条件

- WSL2 + Ubuntu 24.04以上（またはDebian系ディストリビューション）
- Gitインストール済み
- Sudo権限

## セットアップ

```bash
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## 含まれるファイル

- `.zshrc` - zsh設定
- `.config/starship.toml` - Starshipプロンプト設定
- `.config/sheldon/plugins.toml` - Sheldonプラグイン設定
- `.gitconfig.delta` - git diff用delta設定
- `.gitignore_global` - グローバルgitignore（認証情報、OSファイル等）
- `.gitignore` - リポジトリ用gitignore
- `.gitattributes` - git属性（LF強制、diff設定）
- `.editorconfig` - エディタ設定
- `cheatsheet.md` - コマンドチートシート
- `install.sh` - インストールスクリプト
- `uninstall.sh` - アンインストールスクリプト
- `LICENSE` - MITライセンス

## インストールされるツール

- **シェル**: zsh, starship, sheldon, fzf
- **Zshプラグイン**: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search
- **モダンCLI**: eza, bat, ripgrep, fd, zoxide, delta, thefuck, glow
- **ユーティリティ**: lazygit, mise, jq, yq, trash-cli, entr, btop
- **Git**: git, gh (GitHub CLI)
- **クラウド**: AWS CLI, SSM Plugin
- **AI**: Claude Code

`cheat -l`でチートシート一覧、`cheat <tool>`で表示。

## 更新

```bash
cd ~/dotfiles
git pull
./install.sh
```

## アンインストール

```bash
cd ~/dotfiles
./uninstall.sh
```

シンボリックリンクとgit設定を削除します。インストールしたパッケージは削除されません。

## 環境変数

- `SKIP_UPGRADE=1` - インストール時のaptアップグレードをスキップ
- `DOTFILES_DIR` - dotfilesの場所を上書き（デフォルト: `~/dotfiles`）

## トラブルシューティング

- **システムアップグレードをスキップ**: `SKIP_UPGRADE=1 ./install.sh`
- **Homebrewが見つからない**: ターミナル再起動、または `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` を実行
- **バックアップを復元**: `~/.dotfiles_backup/`に以前の設定があります
