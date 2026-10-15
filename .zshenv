# Cargo is optional, including in non-interactive shells.
if [ -r "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
