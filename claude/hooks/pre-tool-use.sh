#!/bin/bash
# PreToolUse safety hook for Claude Code
# Blocks dangerous Bash commands via regex matching
# Expected input: JSON on stdin with {"tool_name", "tool_input"}
# Output: JSON {"decision":"block","reason":"..."} on stdout + exit 0 to block
# Exit 0 with no output to allow

set -euo pipefail

# Read stdin
input="$(cat)"

# Fast path: only inspect Bash tool calls
tool_name="$(echo "$input" | jq -r '.tool_name // empty')"
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

command="$(echo "$input" | jq -r '.tool_input.command // empty')"
if [[ -z "$command" ]]; then
  exit 0
fi

block() {
  echo "{\"decision\":\"block\",\"reason\":\"$1\"}"
  exit 0
}

# --- Destructive filesystem operations ---
# rm -rf / or rm -rf ~ or rm -rf $HOME (with optional sudo)
if [[ "$command" =~ (^|[;|&[:space:]])sudo[[:space:]]+rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+(\/|~|\$HOME|\$\{HOME\})[[:space:]/]*($|[;|&]) ]] ||
   [[ "$command" =~ (^|[;|&[:space:]])rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+(\/|~|\$HOME|\$\{HOME\})[[:space:]/]*($|[;|&]) ]]; then
  block "Blocked: recursive force delete on root/home directory"
fi

# --- Device operations ---
if [[ "$command" =~ (^|[;|&[:space:]])(sudo[[:space:]]+)?dd[[:space:]].*of=/dev/ ]]; then
  block "Blocked: dd write to device"
fi
if [[ "$command" =~ (^|[;|&[:space:]])(sudo[[:space:]]+)?mkfs ]]; then
  block "Blocked: filesystem format command"
fi
if [[ "$command" =~ (^|[;|&[:space:]])(sudo[[:space:]]+)?fdisk ]]; then
  block "Blocked: disk partition command"
fi
if [[ "$command" =~ \>[[:space:]]*/dev/sd[a-z] ]] || [[ "$command" =~ \>[[:space:]]*/dev/nvme ]]; then
  block "Blocked: direct write to block device"
fi

# --- Git destructive operations ---
if [[ "$command" =~ git[[:space:]]+push[[:space:]].*--force[[:space:]].*(main|master) ]] ||
   [[ "$command" =~ git[[:space:]]+push[[:space:]].*-f[[:space:]].*(main|master) ]] ||
   [[ "$command" =~ git[[:space:]]+push[[:space:]]+--force-with-lease[[:space:]].*(main|master) ]]; then
  block "Blocked: force push to main/master"
fi
if [[ "$command" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
  block "Blocked: git reset --hard (destructive)"
fi
if [[ "$command" =~ git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f ]]; then
  block "Blocked: git clean -f (removes untracked files)"
fi

# --- Remote code execution ---
if [[ "$command" =~ (curl|wget)[[:space:]].*\|[[:space:]]*(bash|sh|zsh) ]]; then
  block "Blocked: download-and-execute pattern (curl/wget | shell)"
fi

# --- Credential file access (write operations) ---
if [[ "$command" =~ \>[[:space:]]*[~\$]*(HOME|\.ssh|\.aws|\.gnupg)/ ]] ||
   [[ "$command" =~ (cp|mv|tee|cat[[:space:]].*\>)[[:space:]].*\.(ssh|aws|gnupg)/ ]]; then
  block "Blocked: write to credential directory"
fi

# --- System commands ---
if [[ "$command" =~ (^|[;|&[:space:]])(sudo[[:space:]]+)?(shutdown|reboot|halt|poweroff)([[:space:]]|$|[;|&]) ]]; then
  block "Blocked: system shutdown/reboot command"
fi

# --- Dangerous process signals ---
if [[ "$command" =~ kill[[:space:]]+-9[[:space:]]+1($|[[:space:]]) ]] ||
   [[ "$command" =~ kill[[:space:]]+-9[[:space:]]+-1($|[[:space:]]) ]]; then
  block "Blocked: kill init process or all processes"
fi

# --- Dangerous permissions ---
if [[ "$command" =~ chmod[[:space:]]+(-R[[:space:]]+)?777[[:space:]]+/ ]]; then
  block "Blocked: chmod 777 on root filesystem"
fi

# --- Fork bomb ---
# Use variable to avoid bash regex parsing issues with special chars
fork_bomb_pattern1=':\(\)\{.*:\|:&'
fork_bomb_pattern2='\(\)[[:space:]]*\{.*\|.*&[[:space:]]*\}'
if [[ "$command" =~ $fork_bomb_pattern1 ]] ||
   [[ "$command" =~ $fork_bomb_pattern2 ]]; then
  block "Blocked: fork bomb pattern detected"
fi

# If nothing matched, allow
exit 0
