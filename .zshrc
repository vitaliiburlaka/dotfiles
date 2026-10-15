# PATH is built here and nowhere else.
#
# Keep `path` de-duplicated for the whole session: this file prepends to the
# inherited $PATH, so without -U a nested shell accumulates the same entries
# over and over. It stays in effect for nvm/omz below too.
typeset -U path PATH

# Scrub empty elements inherited from a parent process. An empty PATH element
# means "current directory", which would let ./ls beat /bin/ls inside any
# untrusted checkout — which is exactly what a stray leading colon here used
# to do. Never reintroduce one.
path=("${(@)path:#}")

# Shared helpers are installed as a symlink by ./install --link-only.
[[ -r "$HOME/.shell-common.sh" ]] && source "$HOME/.shell-common.sh"
if (( $+functions[_dt_brew_prefix] )); then
  HOMEBREW_PREFIX="$(_dt_brew_prefix "$(uname -s)" "$(uname -m)")"
  if [[ -n $HOMEBREW_PREFIX ]]; then
    export HOMEBREW_PREFIX
    path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
  else
    unset HOMEBREW_PREFIX
  fi
fi
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PATH

# Secrets (API tokens and anything else private) live outside this repo and
# are sourced early, so everything below can rely on them.
if [ -f ~/.secret ]; then
  source ~/.secret
fi

# Path to your oh-my-zsh installation.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

ZSH_THEME="robbyrussell"
HIST_STAMPS="yyyy-mm-dd"

# Auto-update checks cost ~180ms of every shell start and stall on the
# network. Update deliberately instead, with `omz update`.
zstyle ':omz:update' mode disabled

# Plugins. Measured against a no-plugin baseline (minimum of five runs):
# git +30ms, macos and npm +10ms, the rest within noise — so this list is
# effectively free and does not need trimming.
#
# No `nvm` plugin on purpose: it sources nvm.sh eagerly and always loads
# nvm's bash completion, ~1.9s together. See the lazy nvm setup below.
plugins=(
  git
  brew
  node
  npm
  yarn
  python
)

[[ $(uname -s) == Darwin ]] && plugins+=(macos)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -i -d "${ZDOTDIR:-$HOME}/.zcompdump"
  PROMPT='%n@%m:%~%# '
fi

# ── User configuration ───────────────────────────────────────────────────

export EDITOR='vim'
export VISUAL="$EDITOR"

# History. oh-my-zsh already sets HISTSIZE/SAVEHIST, but with SAVEHIST an
# order of magnitude smaller than HISTSIZE, so most of an in-memory history
# is discarded at exit. Keep them aligned and large.
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS    # a repeated command replaces its older copy
setopt HIST_IGNORE_SPACE       # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY             # expand !! and friends for review, do not run

# SHARE_HISTORY re-reads the history file on every prompt so open tabs see
# each other's commands. Measured cost: ~40ms of startup (0.19s -> 0.23s)
# against a 308K history. Kept deliberately — drop this one line to get it
# back if the history file ever grows enough to be felt.
setopt SHARE_HISTORY

# Aliases are sourced AFTER oh-my-zsh, so anything defined there overrides
# the plugins. Keep that in mind before adding a name a plugin already uses.
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Source zsh-syntax-highlighting
if [ -f "${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Functions
if [ -f ~/.functions ]; then
  source ~/.functions
fi

# nvm (lazy)
# Sourcing nvm.sh costs ~0.7s, and its bash completion another ~0.66s. Neither
# is needed just to run node: put the default version's bin on PATH directly
# (a glob, not a subprocess) and load nvm proper only when it is called.
export NVM_DIR="$HOME/.nvm"
if (( $+functions[_dt_nvm_default_bin] )); then
  _dt_node_bin="$(_dt_nvm_default_bin)"
  [[ -n $_dt_node_bin ]] && path=("$_dt_node_bin" $path)
  unset _dt_node_bin
fi

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  nvm() {
    unfunction nvm
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
      print -u2 'nvm: installation is missing'
      return 127
    fi
    source "$NVM_DIR/nvm.sh"
    if (( ! $+functions[nvm] )); then
      print -u2 'nvm: installation did not define nvm'
      return 127
    fi
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
      autoload -U +X bashcompinit && bashcompinit
      ZSH_VERSION= source "$NVM_DIR/bash_completion"
    fi
    nvm "$@"
  }
fi

# GPG_TTY is required for pinentry. zsh already knows the terminal in $TTY,
# so the usual $(tty) subprocess is only needed as a fallback.
#
# The agent does not need an explicit launch — gpg and git start it on
# demand via its socket — and doing so here cost ~1.4s per shell.
if [[ -n ${TTY:-} ]]; then
  export GPG_TTY="$TTY"
elif [[ -t 0 ]]; then
  export GPG_TTY="$(tty 2>/dev/null)"
fi
