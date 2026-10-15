#!/usr/bin/env bash
#
# Shared helpers for `install` and `backup`. Sourced, never executed.
#
# Both scripts write timestamped backups into the same place and in the same
# format, so the naming, the collision guard and the zip step live here — the
# alternative is two copies that drift, which is how the `zip -y` bug below
# would have come back.
#
# The caller must set BACKUP_ROOT before sourcing.

# Render a path with $HOME collapsed to ~, for readable output. Paths outside
# $HOME are printed as-is — prefixing them with ~ would be a lie (--output can
# point anywhere).
short() {
  case "$1" in
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *)         printf '%s' "$1" ;;
  esac
}

# archive_new_stamp
#
# Echo a YYYYMMDD-HHMMSS timestamp that is not already taken inside
# $BACKUP_ROOT. Two runs in the same second would otherwise share a name, and
# the second would be merged into the first one's archive.
archive_new_stamp() {
  local stamp n=2
  stamp="$(date +%Y%m%d-%H%M%S)"
  if [ -e "$BACKUP_ROOT/$stamp" ] || [ -e "$BACKUP_ROOT/dotfiles-backup-$stamp.zip" ]; then
    while [ -e "$BACKUP_ROOT/$stamp-$n" ] || [ -e "$BACKUP_ROOT/dotfiles-backup-$stamp-$n.zip" ]; do
      n=$((n + 1))
    done
    stamp="$stamp-$n"
  fi
  printf '%s' "$stamp"
}

# archive_manifest_header <backup-dir> <description>
#
# Start a MANIFEST.txt. Entries are appended with archive_manifest_add.
archive_manifest_header() {
  local dir="$1" desc="$2"
  mkdir -p "$dir"
  {
    echo "$desc"
    echo "Taken $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "Paths are relative to \$HOME. To restore one:"
    echo "    cp -R <path-from-this-list> ~/<path-from-this-list>"
    echo
  } > "$dir/MANIFEST.txt"
}

# archive_manifest_add <backup-dir> <relative-path> <description>
archive_manifest_add() {
  printf '%-58s %s\n' "$2" "$3" >> "$1/MANIFEST.txt"
}

# archive_describe <path>
#
# Echo what a path is, recording where a symlink points.
archive_describe() {
  if [ -L "$1" ]; then
    printf 'symlink -> %s' "$(readlink "$1")"
  elif [ -d "$1" ]; then
    printf 'directory'
  else
    printf 'regular file'
  fi
}

# archive_relpath <absolute-path>
#
# Echo the path relative to $HOME. Anything outside $HOME is filed under
# outside-home/ rather than escaping the archive root.
archive_relpath() {
  local rel="${1#"$HOME"/}"
  [ "$rel" = "$1" ] && rel="outside-home/${1#/}"
  printf '%s' "$rel"
}

# archive_finalize <backup-dir> <stamp> <count> <do-zip>
#
# Compress the backup folder into a timestamped zip and report where it went.
# Does nothing when count is 0, so a run with nothing to back up leaves no
# empty folder or archive behind.
archive_finalize() {
  local dir="$1" stamp="$2" count="$3" do_zip="$4"
  local archive="$BACKUP_ROOT/dotfiles-backup-$stamp.zip"

  [ "$count" -eq 0 ] && return 0

  if [ "$do_zip" = false ] || ! command -v zip > /dev/null 2>&1; then
    [ "$do_zip" = true ] && echo "  (zip not found; keeping the backup folder)"
    echo "backed up $count item(s) to $(short "$dir")/"
    return 0
  fi

  # -y stores symlinks as symlinks. Without it zip follows them, which turns
  # a link into a copy of its target and drops a broken link from the archive
  # altogether — exactly the cases most worth preserving.
  #
  # The folder is removed only after unzip -t confirms the archive reads
  # back, because at that point it is the only copy of those files.
  if ( cd "$BACKUP_ROOT" && zip -q -r -y "$archive" "$stamp" ) \
     && unzip -tqq "$archive" > /dev/null 2>&1; then
    rm -rf "$dir"
    echo "backed up $count item(s) to $(short "$archive")"
  else
    rm -f "$archive"
    echo "  (zip failed verification; keeping the folder instead)"
    echo "backed up $count item(s) to $(short "$dir")/"
  fi
}

# managed_pairs
#
# Echo "<repo-relative source>|<absolute target>" for every file this repo
# manages, one per line. Single source of truth: `install` links these and
# `backup` copies them, so the two can never disagree about the list.
managed_pairs() {
  local st_dir app_support
  case "$(uname -s)" in
    Darwin) app_support="$HOME/Library/Application Support" ;;
    *) app_support="${XDG_CONFIG_HOME:-$HOME/.config}" ;;
  esac
  cat <<EOF
.zshrc|$HOME/.zshrc
.zshenv|$HOME/.zshenv
.profile|$HOME/.profile
.bashrc|$HOME/.bashrc
.bash_profile|$HOME/.bash_profile
.aliases|$HOME/.aliases
functions|$HOME/.functions
.gitconfig|$HOME/.gitconfig
.npmrc|$HOME/.npmrc
lib/shell.sh|$HOME/.shell-common.sh
vscode-settings.json|$app_support/Code/User/settings.json
EOF
  # Sublime Text 4 dropped the version suffix from its support directory; use
  # whichever layout this machine actually has, rather than inventing one for
  # a version that is not installed.
  for st_dir in "Sublime Text" "Sublime Text 3" "sublime-text" "sublime-text-3"; do
    if [ -d "$app_support/$st_dir" ]; then
      echo "sublime/Preferences.sublime-settings|$app_support/$st_dir/Packages/User/Preferences.sublime-settings"
    fi
  done
}
