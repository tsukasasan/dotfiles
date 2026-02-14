# ==============================================================================
# .zshrc - WSL2 zsh configuration
# ==============================================================================

# --- History ---
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# --- General options ---
setopt auto_pushd
setopt auto_cd
setopt pushd_ignore_dups

# --- PATH (early setup) ---
export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"

# --- Homebrew ---
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- Completion ---
autoload -Uz compinit
compinit

# --- Sheldon (plugin manager) ---
eval "$(sheldon source)"

# --- zsh-history-substring-search keybindings ---
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# --- Starship (prompt) ---
eval "$(starship init zsh)"

# --- mise (runtime manager) ---
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# --- zoxide (smart cd) ---
eval "$(zoxide init zsh)"

# --- thefuck ---
if command -v thefuck &> /dev/null; then
  eval "$(thefuck --alias)" 2>/dev/null || true
fi

# --- fzf ---
# keybindings: Ctrl+R (history), Ctrl+T (file), Alt+C (cd)
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi
# Use fd for fzf file search if available
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# --- Aliases ---
alias ls='eza'
alias la='eza -a --git -g -h --oneline'  # all files, one per line
alias ll='eza -l --git -g -h'            # long format with git status
alias cat='bat --paging=never'
alias catp='bat -pp'                  # plain output (no decorations)
catc() { bat -pp "$@" | clip.exe; }       # copy to clipboard
catcc() { bat -pp "$@" | tee >(clip.exe); }  # display and copy to clipboard
alias grep='rg'
alias find='fd'
alias diff='delta'

# rm safety: use trash-put instead of rm
alias rm='trash-put'
alias rmf='/bin/rm'  # use rmf to actually delete

# --- cheat command (quick reference) ---
cheat() {
  local sheet="${DOTFILES_DIR:-$HOME/dotfiles}/cheatsheet.md"
  if [[ ! -f "$sheet" ]]; then
    echo "cheatsheet.md not found at $sheet"
    return 1
  fi
  case "$1" in
    ""|-h|--help)
      echo "Usage: cheat [option|tool]"
      echo ""
      echo "Options:"
      echo "  -h, --help   Show this help"
      echo "  -l, --list   List available sections"
      echo "  -a, --all    Show full cheatsheet"
      echo "  <tool>       Show section for tool (case insensitive)"
      echo ""
      echo "Examples:"
      echo "  cheat fzf    Show fzf section"
      echo "  cheat git    Show git-related sections"
      ;;
    -l|--list)
      grep '^## ' "$sheet" | sed 's/^## //'
      ;;
    -a|--all)
      glow "$sheet"
      ;;
    *)
      # Extract section matching tool name (case-insensitive)
      awk -v tool="$1" '
        BEGIN { IGNORECASE=1; found=0 }
        /^## / { if (found) exit; if (tolower($0) ~ tolower(tool)) found=1 }
        found { print }
      ' "$sheet" | glow
      ;;
  esac
}

# --- Editor ---
export EDITOR='code --wait'
export VISUAL='code --wait'

# --- Pager ---
export PAGER='less'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# --- Locale ---
export LANG='en_US.UTF-8'
export LC_CTYPE='ja_JP.UTF-8'

# --- AWS ---
export AWS_DEFAULT_REGION='ap-northeast-1'

# --- GPG (for git commit -S) ---
export GPG_TTY=$(tty)

# --- WSL2: Windows integration ---
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  # Browser for aws login, etc.
  export BROWSER='explorer.exe'

  # Clipboard integration (macOS-style aliases)
  alias pbcopy='clip.exe'
  alias pbpaste='powershell.exe -noprofile -command "Get-Clipboard" | tr -d "\r"'

  # Open files/URLs with Windows default app
  alias open='explorer.exe'

  # Windows user and home directory
  export WIN_USER="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')"
  export WIN_HOME="/mnt/c/Users/$WIN_USER"

  # Windows Terminal: notify current directory for duplicate tab/pane
  _windows_terminal_osc_9_9() {
    printf '\e]9;9;%s\e\' "$(wslpath -w "$(pwd)")"
  }
  precmd_functions+=(_windows_terminal_osc_9_9)
fi
