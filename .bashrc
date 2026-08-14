#!/bin/bash
#
# bash is the fallback shell here — zsh is the daily driver — but it should
# not be second-class. This mirrors .zshrc: same Homebrew prefix detection,
# same single PATH block, same lazy nvm.

# ── Homebrew ─────────────────────────────────────────────────────────────
# /opt/homebrew on Apple Silicon, /usr/local on Intel. Detected with a
# directory test rather than `brew --prefix`, which is a subprocess. Defined
# first because the completion setup below needs it.
if [ -d /opt/homebrew ]; then
    export HOMEBREW_PREFIX=/opt/homebrew
else
    export HOMEBREW_PREFIX=/usr/local
fi

# ── PATH ─────────────────────────────────────────────────────────────────
# Built here and nowhere else. bash has no `typeset -U`, so each entry is
# guarded instead; without that, re-sourcing this file or opening a nested
# shell keeps growing PATH. Never introduce an empty element (a leading,
# trailing or doubled colon) — that puts the current directory on PATH.
_path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# Drop empty elements and duplicates inherited from a parent process. An
# empty element means "current directory", which would let ./ls beat /bin/ls
# inside an untrusted checkout. .zshrc gets this from `typeset -U` plus a
# glob filter; bash has neither, so it is spelled out.
_path_sanitize() {
    local entry out= saved_ifs="$IFS"
    IFS=:
    for entry in $PATH; do
        [ -n "$entry" ] || continue
        case ":$out:" in
            *":$entry:"*) ;;
            *) out="${out:+$out:}$entry" ;;
        esac
    done
    IFS="$saved_ifs"
    PATH="$out"
}

_path_prepend "$HOMEBREW_PREFIX/sbin"
_path_prepend "$HOMEBREW_PREFIX/bin"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"

# Miniconda is installed as a cask, so it lives under Caskroom.
_path_prepend "$HOMEBREW_PREFIX/Caskroom/miniconda/base/condabin"

export PATH

# ── Editor and history ───────────────────────────────────────────────────
export EDITOR='vim'
export VISUAL="$EDITOR"

HISTCONTROL=ignoreboth   # skip duplicates and lines starting with a space
HISTSIZE=50000
HISTFILESIZE=50000
shopt -s histappend      # append rather than overwrite on exit
shopt -s checkwinsize    # keep LINES/COLUMNS right after each command

# ── Aliases ──────────────────────────────────────────────────────────────
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# ── Prompt ───────────────────────────────────────────────────────────────
if tput setaf 1 &> /dev/null; then
    tput sgr0
    reset=$(tput sgr0)
    yellow=$(tput setaf 3)
else
    reset="\e[0m"
    yellow="\e[1;33m"
fi

# Completion. Reuses $HOMEBREW_PREFIX rather than calling `brew --prefix`
# twice as a subprocess, which is what this block used to do.
if [ -f "$HOMEBREW_PREFIX/share/bash-completion/bash_completion" ]; then
    . "$HOMEBREW_PREFIX/share/bash-completion/bash_completion"
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
elif [ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash ]; then
    . /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
fi

if [ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh ]; then
    . /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
    export CLICOLOR=1
    GIT_PS1_SHOWCOLORHINTS=1
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWUPSTREAM="auto"
    PROMPT_COMMAND='__git_ps1 "\u@\h:\[${yellow}\]\w\[${reset}\]" "\\\$ "'
fi

# ── node, via nvm (lazy) ─────────────────────────────────────────────────
# Sourcing nvm.sh plus its completion costs well over a second, and none of
# it is needed just to run node. Put the default version's bin directory on
# PATH directly and load nvm itself only when it is called. Same approach as
# .zshrc, which this file used to lack.
export NVM_DIR="$HOME/.nvm"

_nvm_default_bin() {
    local want bin
    [ -r "$NVM_DIR/alias/default" ] && want=$(cat "$NVM_DIR/alias/default")
    for bin in "$NVM_DIR/versions/node/$want/bin" "$NVM_DIR/versions/node/v$want/bin"; do
        [ -d "$bin" ] && { printf '%s' "$bin"; return 0; }
    done
    # Aliases like "node", "stable" or "lts/*" need nvm itself to resolve;
    # approximate with the highest installed version.
    bin=$(ls -1d "$NVM_DIR"/versions/node/*/ 2>/dev/null | sort -V | tail -1)
    [ -n "$bin" ] && printf '%s' "${bin%/}/bin"
}

_path_prepend "$(_nvm_default_bin)"
unset -f _nvm_default_bin

# Last word on PATH, after every addition above.
_path_sanitize
export PATH

nvm() {
    unset -f nvm
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    nvm "$@"
}

# ── Functions ────────────────────────────────────────────────────────────
if [ -f ~/.functions ]; then
    . ~/.functions
fi
