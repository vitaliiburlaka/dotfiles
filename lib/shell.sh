# Shared startup helpers for bash 3.2+ and zsh. No installs or network calls.
_dt_is_brew_prefix() { [ -x "$1/bin/brew" ]; }

_dt_brew_prefix() {
  local os="$1" machine="$2" candidate
  case "$os:$machine" in
    Darwin:arm64|Darwin:aarch64) set -- /opt/homebrew ;;
    Darwin:*) set -- /usr/local ;;
    Linux:*) set -- /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew" ;;
    *) return 0 ;;
  esac
  for candidate in "$@" "${HOMEBREW_PREFIX:-}"; do
    # Do not inherit a different architecture's standard prefix after migration.
    case "$os:$machine:$candidate" in
      Darwin:arm64:/usr/local|Darwin:aarch64:/usr/local) continue ;;
      Darwin:x86_64:/opt/homebrew|Linux:*:/opt/homebrew|Linux:*:/usr/local) continue ;;
    esac
    if [ -n "$candidate" ] && _dt_is_brew_prefix "$candidate"; then
      printf '%s' "$candidate"
      return 0
    fi
  done
}

_dt_nvm_default_bin() {
  [ -z "${ZSH_VERSION:-}" ] || setopt localoptions nonomatch
  local want= alias_file bin depth=0
  alias_file="$NVM_DIR/alias/default"
  while [ -r "$alias_file" ] && [ "$depth" -lt 8 ]; do
    IFS= read -r want < "$alias_file" || :
    depth=$((depth + 1))
    case "$want" in
      ''|/*|*..*) break ;;
    esac
    alias_file="$NVM_DIR/alias/$want"
  done
  for bin in "$NVM_DIR/versions/node/$want/bin" "$NVM_DIR/versions/node/v$want/bin"; do
    if [ -n "$want" ] && [ -d "$bin" ]; then
      printf '%s' "$bin"
      return 0
    fi
  done
  # Numeric comparison works with BSD tools as well as GNU tools. Match a
  # major/minor default when possible; symbolic defaults use the latest local.
  (
    for bin in "$NVM_DIR"/versions/node/v*/bin; do
      [ -d "$bin" ] || continue
      printf '%s\n' "${bin%/bin}"
    done
  ) | awk -v want="$want" '
    BEGIN { sub(/^v/, "", want); partial = want ~ /^[0-9]+([.][0-9]+)*$/ }
    {
      count = split($0, path, "/"); version = path[count]; sub(/^v/, "", version)
      if (version !~ /^[0-9]+[.][0-9]+[.][0-9]+$/) next
      if (partial && version != want && index(version, want ".") != 1) next
      split(version, v, ".")
      if (!best || v[1]+0 > major || (v[1]+0 == major && v[2]+0 > minor) ||
          (v[1]+0 == major && v[2]+0 == minor && v[3]+0 > patch)) {
        best = $0; major = v[1]+0; minor = v[2]+0; patch = v[3]+0
      }
    }
    END { if (best) printf "%s/bin", best }
  '
}
