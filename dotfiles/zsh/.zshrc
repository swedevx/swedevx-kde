# ---- Zsh bootstrap ---- #

# ---- XDG (define early, safe) ---- #
export XDG_CONFIG_HOME="$HOME/.config"

# ---- History ---- #
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

# ---- History behavior ---- #
setopt APPEND_HISTORY        # don't overwrite history
setopt SHARE_HISTORY         # share history across sessions
setopt INC_APPEND_HISTORY    # write immediately, not on exit
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# ---- ZSH Completions, Syntax highlighting and Auto suggestions ---- #
autoload -Uz compinit
compinit
fpath+=(/usr/share/zsh/site-functions)

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---- Modular config ----
ZSHRC_D="$HOME/.zshrc.d"
[[ -d "$ZSHRC_D" ]] && for f in "$ZSHRC_D"/*.zsh; do
  source "$f"
done

# ---- Run fastfetch if exist ----
if command -v fastfetch &>/dev/null 2>&1; then
  fastfetch
fi
