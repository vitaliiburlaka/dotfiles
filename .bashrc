#!/bin/bash

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=5000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Source bash specific aliases
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# Prompt Colors
if tput setaf 1 &> /dev/null; then
    tput sgr0; # reset colors
    reset=$(tput sgr0);
    green=$(tput setaf 2);
    yellow=$(tput setaf 3);
else
    reset="\e[0m";
    green="\e[1;32m";
    yellow="\e[1;33m";
fi;

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
    source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion;
elif [ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash ]; then
    source /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash;
fi;

# Add git prompt for bash
if [ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh ]; then
    . /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
    export CLICOLOR=1
    GIT_PS1_SHOWCOLORHINTS=1
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWUPSTREAM="auto"
    PROMPT_COMMAND='__git_ps1 "\u@\h:\[${yellow}\]\w\[${reset}\]" "\\\$ "'
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Miniconda path
export PATH="/usr/local/miniconda3/bin:$PATH"
