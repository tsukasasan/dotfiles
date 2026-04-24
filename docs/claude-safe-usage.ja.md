# Claude Code 安全な使用ガイド

このガイドでは、dotfilesリポジトリに含まれる3層防御システムを活用して、Claude Codeの自律的機能を安全に使用する方法を説明します。

## Permission Mode（権限モード）

Claude Codeには、リスクレベルの異なる複数の権限モードがあります:

| モード | 説明 | リスク | 推奨用途 |
|---|---|---|---|
| `default` | 全てのツール呼び出しで確認 | 低 | 学習・初回利用 |
| `acceptEdits` | ファイル編集は自動許可、Bashは確認 | 低〜中 | 日常的な開発 |
| `auto` | 分類器で安全な操作を自動許可 | 中 | 安全フック設定済みの経験者 |
| `dontAsk` | deny以外は全て許可 | 高 | 強固なdenyルール設定時のみ |
| `bypassPermissions` | 全チェック無効 (`--dangerously-skip-permissions`) | 非常に高 | コンテナ/VM内のみ |

## 3層防御アーキテクチャ

```
リクエストの流れ:

  Claudeが実行したい: rm -rf /tmp/build

  Layer 1: permissions.deny (settings.json)
  +------------------------------------------+
  | 静的glob一致                              |
  | 最速チェック、スクリプト実行なし            |
  | ブロック: rm -rf /, dd, mkfs, shutdown... |
  +------------------------------------------+
           |
           | (denyに一致しない)
           v
  Layer 2: PreToolUse Hook (pre-tool-use.sh)
  +------------------------------------------+
  | bashの [[ =~ ]] による正規表現マッチ       |
  | globでは表現できない複雑なパターンを検出    |
  | ブロック: curl|bash, fork bomb など        |
  +------------------------------------------+
           |
           | (hookでブロックされない)
           v
  Layer 3: Permission Mode (auto / ユーザー)
  +------------------------------------------+
  | 分類器またはユーザーの判断                  |
  | エッジケースの最終決定                      |
  +------------------------------------------+
           |
           v
        実行
```

## Auto Modeの設定

Auto Modeは分類器を使って安全な操作を判断します。`~/.claude/settings.json`で動作をカスタマイズできます:

```json
{
  "autoMode": {
    "environment": ["npm test", "npm run build"],
    "allow": ["git commit *", "git push origin *"],
    "soft_deny": ["rm *", "git push --force *"]
  }
}
```

- **environment**: ワークフローの一部として常に許可されるコマンド
- **allow**: 分類器が自動承認できるコマンド
- **soft_deny**: Auto Modeでもユーザー確認が必要なコマンド

## `--dangerously-skip-permissions` について

このフラグは全ての権限チェックを無効化します。**使い捨て環境でのみ使用してください:**

- Dockerコンテナ
- 仮想マシン
- CI/CDパイプライン
- 一時的なWSLインスタンス

このフラグを使用しても、PreToolUseフックは設定されていれば実行されます。これが最後の防御線です。

## safe-claude ワークフロー

`safe-claude`は`claude`コマンドをgitセーフティネットでラップします:

```bash
# 基本的な使い方（claudeと同じ引数）
safe-claude

# 引数付き
safe-claude --model claude-sonnet-4-5-20250929
safe-claude "fix the failing tests"
```

### 動作の仕組み

1. **スナップショット**: 開始前に非破壊的なgit stash (`git stash create`) を作成
2. **実行**: 全引数を渡して`claude`を起動
3. **レビュー**: セッション終了後に`git diff --stat`を表示
4. **復元**: 必要に応じてスナップショットを復元するコマンドを表示

gitリポジトリ外ではスナップショットをスキップして通常実行します。

## claude-audit: セッション監査

Claude Codeが最近のセッションで行った操作をレビュー:

```bash
# 直近5セッションを表示（デフォルト）
claude-audit

# 直近10セッションを表示
claude-audit -n 10

# Bashコマンドのみ表示
claude-audit --commands

# ファイル編集のみ表示
claude-audit --edits
```

出力は色分けされます:
- **赤**: 潜在的に危険なコマンド（rm -rf, force push等）
- **緑**: 安全なコマンド
- **黄**: Bash以外のツール呼び出し（Read, Edit, Write）

## ルールのカスタマイズ

### allowルールの追加

安全なコマンドを`~/.claude/settings.json`に追加:

```json
{
  "permissions": {
    "allow": [
      "Bash(docker compose *)",
      "Bash(cargo *)"
    ]
  }
}
```

### denyルールの追加

特定のパターンをブロック:

```json
{
  "permissions": {
    "deny": [
      "Bash(docker rm -f *)",
      "Read(*.pem)"
    ]
  }
}
```

### カスタムフックの追加

`~/.claude/settings.json`にフックスクリプトを追加:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/my-custom-hook.sh"
          }
        ]
      }
    ]
  }
}
```

フックスクリプトはstdinでJSONを受け取り、`{"decision":"block","reason":"..."}`を出力してブロックできます。

## トラブルシューティング

### フックがコマンドをブロックしない

1. フックが実行可能か確認: `ls -la ~/.claude/hooks/pre-tool-use.sh`
2. `jq`がインストールされているか確認: `which jq`
3. 手動テスト:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | \
     ~/.claude/hooks/pre-tool-use.sh
   ```

### インストール後に設定が適用されない

1. `~/.claude/settings.json`が存在し有効なJSONか確認: `jq '.' ~/.claude/settings.json`
2. `install.sh`を再実行して設定をマージし直す

### safe-claudeが見つからない

`~/.local/bin`がPATHに含まれていることを確認。dotfilesの`.zshrc`は自動的に追加します。

### セッション後の変更を元に戻す

`safe-claude`がスナップショットrefを表示している場合:
```bash
git stash apply <ref>   # セッション前の状態を復元
git checkout .           # セッション中の全変更を破棄
```

または標準的なgit操作:
```bash
git diff                 # 変更をレビュー
git checkout -- <file>   # 特定ファイルを元に戻す
git stash                # 全変更をstashして後でレビュー
```
