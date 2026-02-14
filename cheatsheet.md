# Shell Cheatsheet

## cheat (quick reference)

```bash
cheat           # ヘルプを表示
cheat -l        # セクション一覧を表示
cheat -a        # 全体を表示
cheat fzf       # 特定ツールのセクションを表示
cheat keys      # 部分一致で検索（case insensitive）
```

---

## Keybindings (zsh + fzf)

| キー | 動作 |
|---|---|
| `Ctrl+R` | 履歴をfuzzy検索 |
| `↑` / `↓` | 入力中の文字列を含む履歴を検索 (substring-search) |
| `Ctrl+T` | カレント以下のファイルをfuzzy検索して挿入 |
| `Alt+C` | カレント以下のディレクトリにfuzzy移動 |
| `Tab` | 補完 |
| `→` / `End` | autosuggestion確定 |
| `Alt+→` | autosuggestion単語単位で確定 |
| `Ctrl+A` / `Ctrl+E` | 行頭 / 行末 |
| `Ctrl+W` | 直前の単語を削除 |
| `Ctrl+U` | カーソルより左を全削除 |
| `Ctrl+L` | 画面クリア |

---

## zoxide (cd代替)

```bash
z foo          # 過去に訪れた "foo" を含むディレクトリにジャンプ
z foo bar      # "foo" と "bar" 両方を含むパスにジャンプ
zi             # fzfで対話的に選択してジャンプ
z -            # 直前のディレクトリに戻る
zoxide query   # スコアDB確認
```

---

## eza (ls代替)

```bash
ls             # eza (エイリアス)
la             # eza -a --git -g -h --oneline (隠しファイル含む1行表示)
ll             # eza -l --git -g -h (詳細表示)
eza --tree     # ツリー表示
eza -l --sort=modified  # 更新日時順
```

---

## bat (cat代替)

```bash
cat file.py        # bat --paging=never (エイリアス)
catp file.py       # 装飾なし表示（コピーしやすい）
catc file.py       # クリップボードにコピー
catcc file.py      # 表示しつつクリップボードにもコピー
bat file.py        # シンタックスハイライト付き表示
bat -l json        # 言語を明示指定
bat --diff file.py # git diffハイライト付き
bat -A file.txt    # 非表示文字を可視化
```

---

## ripgrep (grep代替)

```bash
rg pattern            # カレント以下を再帰検索
rg pattern -t py      # .pyファイルのみ
rg pattern -g '*.ts'  # globパターン指定
rg pattern -i         # 大文字小文字無視
rg pattern -l         # マッチしたファイル名のみ
rg pattern -C 3       # 前後3行のコンテキスト表示
rg pattern --hidden    # 隠しファイルも検索
rg -F 'exact.string'  # 正規表現を無効化（完全一致）
```

---

## fd (find代替)

```bash
fd pattern            # カレント以下をファイル名で検索
fd -e py              # 拡張子で絞り込み
fd -t d pattern       # ディレクトリのみ
fd -t f pattern       # ファイルのみ
fd -H pattern         # 隠しファイルも検索
fd pattern --exec rm  # 見つかったファイルに対してコマンド実行
fd -e log --changed-within 1d  # 1日以内に変更されたlogファイル
```

---

## fzf (fuzzy finder)

```bash
# パイプで何でもfuzzy検索
cat file | fzf
rg pattern -l | fzf       # 検索結果からファイル選択
git branch | fzf           # ブランチ選択
docker ps | fzf            # コンテナ選択

# プレビュー付き
fzf --preview 'bat --color=always {}'
```

---

## lazygit

```bash
lazygit        # 起動（gitリポジトリ内で実行）
```

| キー | 画面 | 動作 |
|---|---|---|
| `Space` | Files | ステージ/アンステージ |
| `c` | Files | コミット |
| `p` | Files | プッシュ |
| `P` | Files | プル |
| `Enter` | Any | 詳細/展開 |
| `d` | Files | diff表示 |
| `[` / `]` | Any | パネル切替 |
| `?` | Any | ヘルプ表示 |
| `q` | Any | 終了 |

---

## delta (git diff強化)

```bash
# 自動適用される（gitconfigで設定すると有効）
git diff               # deltaが自動でハイライト
git log -p             # パッチ表示もdelta経由
diff file1 file2       # エイリアスでdelta実行
delta file1 file2      # 直接比較
```

---

## thefuck (タイポ修正)

```bash
# コマンドを間違えたら "fuck" で修正+再実行
gut push              # タイポ
fuck                  # → git push に修正して実行
```

---

## mise (ランタイム管理)

```bash
mise ls                    # インストール済み一覧
mise use node@22           # グローバルにnodeバージョン設定
mise use --path node@20    # プロジェクトローカルに設定（.mise.toml生成）
mise install               # .mise.toml記載のツールをインストール
mise outdated              # 更新可能なバージョン確認
mise self-update           # mise自体の更新
```

---

## jq (JSON処理)

```bash
jq '.' file.json              # 整形表示
jq '.key' file.json           # キーの値を取得
jq '.items[0]' file.json      # 配列の最初の要素
jq '.items[] | .name' file.json  # 配列の各要素からnameを抽出
jq -r '.name' file.json       # 生文字列出力（クォートなし）
jq -c '.' file.json           # 1行に圧縮
cat file.json | jq '.key'     # パイプ入力
jq -s '.' file1.json file2.json  # 複数ファイルを配列にマージ
```

---

## gh (GitHub CLI)

```bash
gh auth login                 # 認証
gh repo clone owner/repo      # リポジトリをクローン
gh repo create name --public  # 新規リポジトリ作成
gh pr create                  # プルリクエスト作成
gh pr list                    # PR一覧
gh pr checkout 123            # PR #123をチェックアウト
gh pr merge 123               # PR #123をマージ
gh issue list                 # Issue一覧
gh issue create               # Issue作成
gh browse                     # ブラウザでリポジトリを開く
```

---

## yq / tomlq (YAML/TOML処理)

```bash
# YAML操作（jq構文が使える）
yq '.services.web.image' docker-compose.yml
yq -y '.metadata.name = "new-name"' manifest.yml   # YAML出力で書き戻し
yq -r '.items[].name' list.yml                      # 生文字列出力
cat file.yml | yq '.'                               # パイプ入力

# TOML操作（tomlqコマンド）
tomlq '.package.version' Cargo.toml
tomlq -r '.tool.poetry.name' pyproject.toml
tomlq '.plugins' ~/.config/sheldon/plugins.toml
```

---

## trash-cli (安全なrm)

```bash
rm file.txt           # trash-putエイリアス → ゴミ箱に移動
rmf file.txt          # /bin/rm → 本当に削除
trash-list            # ゴミ箱の中身を表示
trash-restore         # ゴミ箱から復元（対話式）
trash-empty           # ゴミ箱を空にする
trash-empty 30        # 30日以上前のものだけ削除
```

---

## entr (ファイル変更監視)

```bash
# ファイル変更時にコマンドを自動実行
fd -e py | entr pytest                    # Python: テスト自動実行
fd -e ts | entr npm test                  # TypeScript: テスト自動実行
fd -e md | entr pandoc doc.md -o doc.pdf  # Markdown変更でPDF再生成
fd -e go | entr -r go run main.go         # -r: プロセス再起動

# 便利なフラグ
# -c  実行前に画面クリア
# -r  前のプロセスをkillして再起動
# -s  シェル経由で実行（パイプ等が使える）
fd -e js | entr -cs 'npm test && echo OK'
```

---

## btop (システム監視)

```bash
btop               # 起動
```

| キー | 動作 |
|---|---|
| `h` | ヘルプ |
| `Esc` / `q` | 終了 |
| `f` | プロセスフィルター |
| `k` | プロセスkill |
| `m` | メモリソート |
| `p` | CPUソート |
| `←` `→` | タブ切替 |

---

## AWS CLI

```bash
aws configure                        # 初期設定
aws sts get-caller-identity          # 現在の認証確認
aws s3 ls                            # S3バケット一覧
aws ssm start-session --target i-xxx # SSMセッション開始
export AWS_PROFILE=prod              # プロファイル切替
```

---

## WSL2 Windows連携

```bash
# クリップボード (macOS風エイリアス)
pbcopy            # stdin → Windowsクリップボード (例: cat file | pbcopy)
pbpaste           # Windowsクリップボード → stdout
echo "test" | pbcopy && pbpaste   # コピー→ペースト確認

# ファイル/URL
open file.pdf     # Windows既定アプリで開く (explorer.exe)
open https://...  # Windowsブラウザで開く

# 環境変数
$EDITOR           # code --wait (git commit等で使用)
$BROWSER          # explorer.exe (aws login等で使用)
$PAGER            # less (manページ等)
$MANPAGER         # bat (manページをシンタックスハイライト)
$AWS_DEFAULT_REGION  # ap-northeast-1
$WIN_USER         # Windowsユーザー名
$WIN_HOME         # Windowsホームディレクトリのパス (/mnt/c/Users/$WIN_USER)
```

---

## sheldon (プラグイン管理)

```bash
sheldon lock          # plugins.tomlからロックファイル生成
sheldon lock --update # プラグイン更新
```

---

## Claude Code

```bash
claude                # 起動（プロジェクトディレクトリで実行）
claude --model claude-sonnet-4-5-20250929  # モデル指定
claude --resume       # 前回セッションを再開
claude "explain this codebase"             # ワンショット実行
```

| コマンド | 動作 |
|---|---|
| `/help` | コマンド一覧 |
| `/config` | 設定 |
| `/compact` | 会話を要約して圧縮 |
| `/clear` | 会話リセット |
| `/bug` | バグ報告 |
| `/quit` | 終了 |
| `claude doctor` | インストール診断 |
| `claude update` | アップデート |

---

## starship (プロンプト)

プロンプト表示の意味:

```
14:30 ~/projects/myapp (main) ✓ aws:prod took 5s ✗ 1
$
```

| 要素 | 意味 |
|---|---|
| `14:30` | 現在時刻 |
| `~/projects/myapp` | ディレクトリ（短縮） |
| `(main)` | gitブランチ |
| `✓` / `!` / `?` | clean / modified / untracked |
| `aws:prod` | AWSプロファイル |
| `took 5s` | コマンド実行時間（3秒以上） |
| `✗ 1` | 終了コード（エラー時のみ） |
