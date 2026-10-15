# POSIX login shells; bash uses .bash_profile and zsh uses .zshenv.
if [ -r "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
