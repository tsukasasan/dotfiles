# エージェント実行用 セキュアWSL2 Distro

Claude Code等のAIエージェントの実行専用に、Windowsから隔離されたWSL2 Distroを作るためのガイドです。普段の開発環境やWindowsファイルにリスクを与えずに `--dangerously-skip-permissions` やAuto Modeを使える強力なサンドボックスになります。

## なぜ別Distroが必要か

3層防御フックを設定しても、通常の開発用WSL2には多くの攻撃面があります:

- **Interop**: `powershell.exe`, `cmd.exe`, PATH上のWindowsバイナリが到達可能
- **Automount**: `/mnt/c/Users/...` でWindowsファイル（ブラウザセッション、認証情報、ソースコード）が見える
- **共有カーネル**: localhost forwarding、共有クリップボード等

専用の隔離Distroを使えばこれら全てが消えます。

## アーキテクチャ

```
Windows
  ├─ WSL2: Ubuntu (通常開発用)
  │    └─ Windows interop ON, /mnt/c アクセス可, pbcopy等のdotfiles適用
  │
  └─ WSL2: Ubuntu-secure (エージェントsandbox)
       └─ Interop OFF, /mnt/c なし, Windowsから完全隔離
```

## セットアップ

### 1. Distro作成（Windows側）

PowerShellまたはWindows Terminalで:

```powershell
wsl --install -d Ubuntu-24.04 --name Ubuntu-secure
```

プロンプトに従ってLinuxユーザーアカウントを作成。

### 2. dotfilesをclone

新しいDistro内で:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. install-secure.shを実行

```bash
./install-secure.sh
```

実行内容:

- 最小パッケージのインストール（zsh, git, curl, jq, build-essential）
- `/etc/wsl.conf`を書き込み、interop / automount / Windows PATHを無効化
- Claude Codeをインストール
- Claude Code safety layer（hooks, settings, scripts）を適用
- 任意で完全な`install.sh`を実行（zsh, starship等）

### 4. WSLを再起動して隔離を適用

```bash
exit
```

Windows側で:

```powershell
wsl --shutdown
wsl -d Ubuntu-secure
```

## 動作確認

再起動後、隔離が有効化されているか確認:

```bash
# 失敗するはず（automount無効）
ls /mnt/c

# 失敗するはず（interop無効）
powershell.exe -Command 1
cmd.exe /c dir

# 空のはず（Windows PATHなし）
echo $PATH | grep -i windows
```

これらが成功する場合、`wsl --shutdown`が実行されていないか、`/etc/wsl.conf`が適用されていません。

## 日常運用

### Windows TerminalからセキュアDistroを開く

Windows Terminalにプロファイルを追加:

- Windows Terminal設定を開く
- 新しいプロファイルを追加
- コマンドライン: `wsl.exe -d Ubuntu-secure`
- 開発用Distroと混同しないよう、独自のアイコン/色を設定

### エージェントを安全に実行

```bash
# エージェント実行前にgitスナップショット
safe-claude

# --dangerously-skip-permissions を使っても以下が効く:
#   - PreToolUseフック（rm -rf /, force push等をブロック）
#   - permissions.deny（認証ファイルへのアクセスをブロック）
#   - Windowsへ脱出する手段がない
safe-claude --dangerously-skip-permissions
```

## Distro間のファイル転送

`/mnt/c`が無効化され、セキュアDistroは完全に隔離されているため、以下の方法で転送します:

- **git**: GitHub等のリモート経由でpush/pull
- **SSH**: 一方のDistroでsshdを起動し、WSL2仮想NIC経由で`scp`

または、サンドボックスは自己完結のまま使う方針もあります。エージェントをデータから遠ざけることが目的なので、これが最も安全です。

## 元に戻す

セキュアDistroを完全に削除:

```powershell
wsl --unregister Ubuntu-secure
```

これでDistroとそのファイルシステムが完全に消えます。元の開発用Distroには影響しません。

## トラブルシューティング

### install-secure.sh実行後も `/mnt/c` が見える

`wsl --shutdown` を実行していません。WSLは実行中のインスタンスをキャッシュするので、`/etc/wsl.conf` はDistro VMのコールドスタート時のみ再読み込みされます。

### パッケージインストール時にDNSエラー

`/etc/wsl.conf` の `network.generateResolvConf` が `false` の場合、自前で `/etc/resolv.conf` を提供する必要があります。`install-secure.sh` のデフォルトは `true` なので、カスタマイズしていなければ発生しません。

### 一時的にinteropを有効化したい

`/etc/wsl.conf` を編集し `interop.enabled = true` にして、`wsl --shutdown` 後に開き直します。ただしこれはセキュアDistroの目的を損ないます。通常の開発Distroで作業する方が望ましいです。
