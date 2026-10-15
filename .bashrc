#!/bin/bash
#
# bash is the fallback shell here — zsh is the daily driver — but it should
# not be second-class. This mirrors .zshrc: same Homebrew prefix detection,
# same single PATH block, same lazy nvm.

# Shared helpers are installed as a symlink by ./install --link-only.
[ -r "$HOME/.shell-common.sh" ] && . "$HOME/.shell-common.sh"
if command -v _dt_brew_prefix >/dev/null 2>&1; then
    HOMEBREW_PREFIX="$(_dt_brew_prefix "$(uname -s)" "$(uname -m)")"
    if [ -n "$HOMEBREW_PREFIX" ]; then
        export HOMEBREW_PREFIX
    else
        unset HOMEBREW_PREFIX
    fi
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
    local entry out=
    local remaining="$PATH"
    while :; do
        entry="${remaining%%:*}"
        case "$remaining" in
            *:*) remaining="${remaining#*:}" ;;
            *) remaining= ;;
        esac
        if [ -n "$entry" ]; then
            case ":$out:" in
                *":$entry:"*) ;;
                *) out="${out:+$out:}$entry" ;;
            esac
        fi
        [ -n "$remaining" ] || break
    done
    PATH="$out"
}

if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    _path_prepend "$HOMEBREW_PREFIX/sbin"
    _path_prepend "$HOMEBREW_PREFIX/bin"
fi
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.opencode/bin"

export PATH

# ── Editor and history ───────────────────────────────────────────────────
export EDITOR='vim'
export VISUAL="$EDITOR"

HISTCONTROL=ignoreboth   # skip duplicates and lines starting with a space
HISTSIZE=50000
HISTFILESIZE=50000
shopt -s histappend      # append rather than overwrite on exit
shopt -s checkwinsize    # keep LINES/COLUMNS right after each command

[ ! -r "$HOME/.secret" ] || . "$HOME/.secret"

# ── Aliases ──────────────────────────────────────────────────────────────
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# ── Prompt ───────────────────────────────────────────────────────────────
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput setaf 1 &> /dev/null; then
    reset=$(tput sgr0)
    yellow=$(tput setaf 3)
else
    reset="\e[0m"
    yellow="\e[1;33m"
fi

# Completion. Reuses $HOMEBREW_PREFIX rather than calling `brew --prefix`
# twice as a subprocess, which is what this block used to do.
if [ -f "${HOMEBREW_PREFIX:-}/share/bash-completion/bash_completion" ]; then
    . "${HOMEBREW_PREFIX:-}/share/bash-completion/bash_completion"
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

if command -v _dt_nvm_default_bin >/dev/null 2>&1; then
    _path_prepend "$(_dt_nvm_default_bin)"
fi

if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() {
        unset -f nvm
        if [ ! -s "$NVM_DIR/nvm.sh" ]; then
            printf '%s\n' 'nvm: installation is missing' >&2
            return 127
        fi
        . "$NVM_DIR/nvm.sh"
        if ! declare -F nvm >/dev/null; then
            printf '%s\n' 'nvm: installation did not define nvm' >&2
            return 127
        fi
        [ ! -s "$NVM_DIR/bash_completion" ] || . "$NVM_DIR/bash_completion"
        nvm "$@"
    }
fi

# ── Functions ────────────────────────────────────────────────────────────
if [ -f ~/.functions ]; then
    . ~/.functions
fi
[ ! -r "$HOME/.cargo/env" ] || . "$HOME/.cargo/env"
_path_sanitize
export PATH
if [ -t 0 ]; then
    export GPG_TTY="$(tty 2>/dev/null)"
fi
:
