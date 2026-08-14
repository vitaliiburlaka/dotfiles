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

# Source .secret SHOULD GO BEFORE EVERYTHING ELSE
if [ -f ~/.secret ]; then
  source ~/.secret
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="agnoster"
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Auto-update checks cost ~180ms of every single shell start, and stall on
# the network. Update deliberately instead, with `omz update`.
zstyle ':omz:update' mode disabled

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Note: no `nvm` plugin here on purpose. It sources nvm.sh eagerly and always
# loads nvm's bash completion, which together cost ~1.9s. See the lazy nvm
# setup near the bottom of this file.
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

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Prompt config
[[ -n $SSH_CONNECTION ]] || export DEFAULT_USER=$(whoami)

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Source aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Source zsh-syntax-highlighting
if [ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Functions
# Source functions
if [ -f ~/.functions ]; then
  source ~/.functions
fi

# conda (lazy)
# The stock `conda init` block runs `conda shell.zsh hook`, which spawns
# Python and costs ~0.7s on every shell. Defer it: the first `conda` call
# replaces this stub with the real thing.
export CONDA_PREFIX_DIR="$HOMEBREW_PREFIX/Caskroom/miniconda/base"
conda() {
  unfunction conda
  local __conda_setup
  if __conda_setup="$("$CONDA_PREFIX_DIR/bin/conda" shell.zsh hook 2>/dev/null)"; then
    eval "$__conda_setup"
  elif [ -f "$CONDA_PREFIX_DIR/etc/profile.d/conda.sh" ]; then
    . "$CONDA_PREFIX_DIR/etc/profile.d/conda.sh"
  else
    path=("$CONDA_PREFIX_DIR/bin" $path)
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

# GPG_TTY is required for pinentry. The agent does not need an explicit
# launch — gpg and git start it on demand via its socket — and doing so here
# cost ~1.4s per shell.
export GPG_TTY=$(tty)
