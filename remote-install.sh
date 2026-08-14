#!/usr/bin/env bash
#
# Bootstrap these dotfiles onto a fresh machine:
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/vitaliiburlaka/dotfiles/master/remote-install.sh)"
#
# Clones (or downloads) the repo to ~/.dotfiles. It deliberately stops
# there rather than running ./install, so you can look at what you just
# downloaded before it starts symlinking into $HOME.

set -euo pipefail

SOURCE="https://github.com/vitaliiburlaka/dotfiles"
TARBALL="$SOURCE/tarball/master"
TARGET="$HOME/.dotfiles"

is_executable() {
  command -v "$1" > /dev/null 2>&1
}

if [ -e "$TARGET" ]; then
  echo "$TARGET already exists. Update it with: git -C \"$TARGET\" pull"
  exit 1
fi

echo "Installing dotfiles into $TARGET..."
mkdir -p "$TARGET"

# Commands are run directly rather than assembled into a string and eval'd,
# so paths containing spaces cannot be re-split. The old version built
# TAR_CMD with nested double quotes, which closed the outer string and left
# $TARGET unquoted.
if is_executable git; then
  git clone "$SOURCE" "$TARGET"
elif is_executable curl; then
  # --exclude takes a single pattern; the old '{.gitignore}' matched a file
  # literally named "{.gitignore}" and so excluded nothing.
  curl -#L "$TARBALL" \
    | tar -xz -C "$TARGET" --strip-components=1 --exclude='.gitignore'
elif is_executable wget; then
  # No --no-check-certificate here: this pipes downloaded code straight into
  # tar, so certificate verification is exactly what must not be skipped.
  wget -O - "$TARBALL" \
    | tar -xz -C "$TARGET" --strip-components=1 --exclude='.gitignore'
else
  echo "No git, curl or wget available. Aborting." >&2
  exit 1
fi

echo
echo "Done. Review the repo, then run:"
echo "    cd \"$TARGET\" && ./install"
