# Claude Code Safe Usage Guide

This guide explains how to safely use Claude Code's autonomous features, leveraging the 3-layer defense system included in this dotfiles repository.

## Permission Modes

Claude Code offers several permission modes, each with different risk levels:

| Mode | Description | Risk | Recommended Use |
|---|---|---|---|
| `default` | Asks for every tool call | Low | Learning / first-time use |
| `acceptEdits` | Auto-allows file edits, asks for Bash | Low-Medium | Daily development |
| `auto` | Uses classifier to auto-allow safe operations | Medium | Experienced users with safety hooks |
| `dontAsk` | Allows everything except deny list | High | Only with strong deny rules |
| `bypassPermissions` | Skips all checks (`--dangerously-skip-permissions`) | Very High | Container/VM only |

## 3-Layer Defense Architecture

```
Request flow:

  Claude wants to run: rm -rf /tmp/build

  Layer 1: permissions.deny (settings.json)
  +------------------------------------------+
  | Static glob matching                     |
  | Fastest check, no script execution       |
  | Blocks: rm -rf /, dd, mkfs, shutdown...  |
  +------------------------------------------+
           |
           | (not matched by deny)
           v
  Layer 2: PreToolUse Hook (pre-tool-use.sh)
  +------------------------------------------+
  | Regex matching via bash [[ =~ ]]         |
  | Catches complex patterns globs can't     |
  | Blocks: curl|bash, fork bombs, etc.      |
  +------------------------------------------+
           |
           | (not blocked by hook)
           v
  Layer 3: Permission Mode (auto / user)
  +------------------------------------------+
  | Classifier or user judgment              |
  | Final decision for edge cases            |
  +------------------------------------------+
           |
           v
        Executed
```

## Auto Mode Configuration

Auto mode uses a classifier to decide which operations are safe. You can customize its behavior in `~/.claude/settings.json`:

```json
{
  "autoMode": {
    "environment": ["npm test", "npm run build"],
    "allow": ["git commit *", "git push origin *"],
    "soft_deny": ["rm *", "git push --force *"]
  }
}
```

- **environment**: Commands that are part of the expected workflow (always allowed)
- **allow**: Commands that the classifier can auto-approve
- **soft_deny**: Commands that require explicit user confirmation even in auto mode

## Using `--dangerously-skip-permissions`

This flag disables all permission checks. **Only use it in disposable environments:**

- Docker containers
- Virtual machines
- CI/CD pipelines
- Temporary WSL instances

Even with this flag, PreToolUse hooks still execute if configured. This is your last line of defense.

## safe-claude Workflow

`safe-claude` wraps the `claude` command with git safety:

```bash
# Basic usage (same arguments as claude)
safe-claude

# With arguments
safe-claude --model claude-sonnet-4-5-20250929
safe-claude "fix the failing tests"
```

### How it works

1. **Snapshot**: Creates a non-destructive git stash (`git stash create`) before starting
2. **Run**: Launches `claude` with all your arguments
3. **Review**: Shows `git diff --stat` after the session ends
4. **Revert**: Prints the command to restore the snapshot if needed

If you're not in a git repository, it skips the snapshot and runs normally.

## claude-audit: Session Review

Review what Claude Code did in recent sessions:

```bash
# Show last 5 sessions (default)
claude-audit

# Show last 10 sessions
claude-audit -n 10

# Show only Bash commands
claude-audit --commands

# Show only file edits
claude-audit --edits
```

Output is color-coded:
- **Red**: Potentially dangerous commands (rm -rf, force push, etc.)
- **Green**: Safe commands
- **Yellow**: Non-Bash tool calls (Read, Edit, Write)

## Customizing Rules

### Adding allow rules

Add safe commands to `~/.claude/settings.json`:

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

### Adding deny rules

Block specific patterns:

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

### Adding custom hooks

Add additional hook scripts in `~/.claude/settings.json`:

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

Hook scripts receive JSON on stdin and can block by outputting `{"decision":"block","reason":"..."}`.

## Troubleshooting

### Hook not blocking commands

1. Check the hook is executable: `ls -la ~/.claude/hooks/pre-tool-use.sh`
2. Check `jq` is installed: `which jq`
3. Test manually:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | \
     ~/.claude/hooks/pre-tool-use.sh
   ```

### Settings not applied after install

1. Check `~/.claude/settings.json` exists and is valid JSON: `jq '.' ~/.claude/settings.json`
2. Re-run `install.sh` to re-merge settings

### safe-claude not found

Ensure `~/.local/bin` is in your `PATH`. The dotfiles `.zshrc` adds it automatically.

### Reverting changes after a session

If `safe-claude` shows a snapshot ref:
```bash
git stash apply <ref>   # Restore pre-session state
git checkout .           # Discard all session changes
```

Or use standard git:
```bash
git diff                 # Review changes
git checkout -- <file>   # Revert specific file
git stash                # Stash all changes for later review
```
