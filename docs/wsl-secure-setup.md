# Secure WSL2 Distro for Agent Execution

This guide walks through creating a separate WSL2 distro that is isolated from Windows, dedicated to running AI agents like Claude Code. This gives you a strong sandbox for `--dangerously-skip-permissions` and Auto Mode without putting your main development environment or Windows files at risk.

## Why a separate distro?

Even with the 3-layer safety hooks, your normal development WSL2 has many attack surfaces:

- **Interop**: `powershell.exe`, `cmd.exe`, and any Windows binary on `PATH` are reachable
- **Automount**: `/mnt/c/Users/...` exposes Windows files (browser sessions, credentials, source trees)
- **Shared kernel surface**: localhost forwarding, shared clipboard, etc.

A dedicated isolated distro removes all of these.

## Architecture

```
Windows
  ├─ WSL2: Ubuntu (normal dev)
  │    └─ Windows interop ON, /mnt/c accessible, dotfiles with pbcopy etc.
  │
  └─ WSL2: Ubuntu-secure (agent sandbox)
       └─ Interop OFF, no /mnt/c, isolated from Windows entirely
```

## Setup

### 1. Create the distro (Windows side)

In PowerShell or Windows Terminal:

```powershell
wsl --install -d Ubuntu-24.04 --name Ubuntu-secure
```

When prompted, create a Linux user account.

### 2. Clone dotfiles

Inside the new distro:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Run install-secure.sh

```bash
./install-secure.sh
```

This will:

- Install minimal packages (zsh, git, curl, jq, build-essential)
- Write `/etc/wsl.conf` to disable interop, automount, and Windows PATH
- Install Claude Code
- Apply the Claude Code safety layer (hooks, settings, scripts)
- Optionally run the full `install.sh` (zsh, starship, etc.)

### 4. Restart WSL to apply isolation

```bash
exit
```

From Windows:

```powershell
wsl --shutdown
wsl -d Ubuntu-secure
```

## Verification

After restart, verify isolation is in effect:

```bash
# Should fail — automount disabled
ls /mnt/c

# Should fail — interop disabled
powershell.exe -Command 1
cmd.exe /c dir

# Should be empty — no Windows PATH
echo $PATH | grep -i windows
```

If any of these succeed, `wsl --shutdown` was not run, or `/etc/wsl.conf` was not applied.

## Daily use

### Open the secure distro from Windows Terminal

Add a profile to Windows Terminal:

- Open Windows Terminal settings
- Add new profile
- Command line: `wsl.exe -d Ubuntu-secure`
- Set a distinctive icon/color so you don't confuse it with the dev distro

### Run agents safely

```bash
# Take a git snapshot before agent runs
safe-claude

# With --dangerously-skip-permissions, you still have:
#   - PreToolUse hook (blocks rm -rf /, force push, etc.)
#   - permissions.deny (blocks credential file access)
#   - No Windows side to escape to
safe-claude --dangerously-skip-permissions
```

## File transfer between distros

Since `/mnt/c` is disabled and the secure distro is fully isolated, transfer files via:

- **git**: push/pull through GitHub or other remotes
- **SSH**: enable sshd in one distro and `scp` between them via the WSL2 virtual NIC

Or, accept that the sandbox stays self-contained. The whole point is to keep the agent away from your data.

## Reverting

To remove the secure distro entirely:

```powershell
wsl --unregister Ubuntu-secure
```

This deletes the distro and its filesystem completely. The original development distro is untouched.

## Troubleshooting

### `/mnt/c` still works after running install-secure.sh

You didn't run `wsl --shutdown`. WSL caches the running instance — `/etc/wsl.conf` is only re-read on a cold start of the distro VM.

### Cannot install packages — DNS errors

If `network.generateResolvConf` is set to false in `/etc/wsl.conf`, you must provide your own `/etc/resolv.conf`. The default in `install-secure.sh` is `true`, so this should not happen unless you customized the config.

### Want to enable some interop temporarily

Edit `/etc/wsl.conf`, set `interop.enabled = true`, then `wsl --shutdown` and reopen. But this defeats the purpose of the secure distro — prefer doing the work in the regular dev distro instead.
