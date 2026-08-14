# PATH is built here and nowhere else.
#
# Keep `path` de-duplicated for the whole session: this file prepends to the
# inherited $PATH, so without -U a nested shell accumulates the same entries
# over and over. It stays in effect for nvm/conda/omz below too.
typeset -U path PATH

# Scrub empty elements inherited from a parent process. An empty PATH element
# means "current directory", which would let ./ls beat /bin/ls inside any
# untrusted checkout — which is exactly what a stray leading colon here used
# to do. Never reintroduce one.
path=("${(@)path:#}")

# Homebrew lives in /opt/homebrew on Apple Silicon and /usr/local on Intel.
# Detected with a directory test rather than `brew --prefix`, which is a
# subprocess and would put startup cost straight back.
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
else
  export HOMEBREW_PREFIX=/usr/local
fi

path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
[ -d "$HOME/bin" ] && path=("$HOME/bin" $path)
[ -d "$HOME/.local/bin" ] && path=("$HOME/.local/bin" $path)
export PATH

# Secrets (API tokens and anything else private) live outside this repo and
# are sourced early, so everything below can rely on them.
if [ -f ~/.secret ]; then
  source ~/.secret
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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
  macos
  node
  npm
  yarn
  python
)

source $ZSH/oh-my-zsh.sh

# ── User configuration ───────────────────────────────────────────────────

export EDITOR='vim'
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8

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
if [ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Functions
if [ -f ~/.functions ]; then
  source ~/.functions
fi

# conda (lazy)
# The stock `conda init` block runs `conda shell.zsh hook`, which spawns
# Python and costs ~0.7s on every shell. Defer it: the first `conda` call
# replaces this stub with the real thing.
_conda_root="$HOMEBREW_PREFIX/Caskroom/miniconda/base"
conda() {
  unfunction conda
  local __conda_setup
  if __conda_setup="$("$_conda_root/bin/conda" shell.zsh hook 2>/dev/null)"; then
    eval "$__conda_setup"
  elif [ -f "$_conda_root/etc/profile.d/conda.sh" ]; then
    . "$_conda_root/etc/profile.d/conda.sh"
  else
    path=("$_conda_root/bin" $path)
  fi
  conda "$@"
}

# nvm (lazy)
# Sourcing nvm.sh costs ~0.7s, and its bash completion another ~0.66s. Neither
# is needed just to run node: put the default version's bin on PATH directly
# (a glob, not a subprocess) and load nvm proper only when it is called.
export NVM_DIR="$HOME/.nvm"
() {
  local alias_file="$NVM_DIR/alias/default" want bin
  local -a versions
  [[ -r $alias_file ]] && want="$(<$alias_file)"
  for bin in "$NVM_DIR/versions/node/$want/bin" "$NVM_DIR/versions/node/v$want/bin"; do
    if [[ -d $bin ]]; then
      path=("$bin" $path)
      return
    fi
  done
  # Aliases like "node", "stable" or "lts/*" need nvm itself to resolve;
  # approximate with the highest installed version (numeric glob sort).
  versions=("$NVM_DIR"/versions/node/*(/Nn))
  (( $#versions )) && path=("${versions[-1]}/bin" $path)
}

nvm() {
  unfunction nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  if [[ -s "$NVM_DIR/bash_completion" ]]; then
    autoload -U +X bashcompinit && bashcompinit
    # Bypass the compinit call inside nvm's bash completion script.
    ZSH_VERSION= source "$NVM_DIR/bash_completion"
  fi
  nvm "$@"
}

# GPG_TTY is required for pinentry. zsh already knows the terminal in $TTY,
# so the usual $(tty) subprocess is only needed as a fallback.
#
# The agent does not need an explicit launch — gpg and git start it on
# demand via its socket — and doing so here cost ~1.4s per shell.
export GPG_TTY="${TTY:-$(tty)}"
