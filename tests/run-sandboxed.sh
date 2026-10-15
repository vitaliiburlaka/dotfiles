#!/usr/bin/env bash
# Retains a disposable copy and fixtures; never runs against the real home.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python_bin="$(command -v python3)"
case "$(uname -s)" in
  Darwin) task_root="$(mktemp -d /private/tmp/dotfiles-test.XXXXXX)" ;;
  Linux) task_root="$(mktemp -d /tmp/dotfiles-test.XXXXXX)" ;;
  *) echo 'Unsupported test host; use macOS or Linux.' >&2; exit 1 ;;
esac
"$python_bin" -I - "$repo_dir" "$task_root" "$HOME" <<'PY'
from pathlib import Path
import shutil, sys
repo, root, home = map(Path, sys.argv[1:])
shutil.copytree(repo, root/'repo', ignore=shutil.ignore_patterns('.git', '.secret', '.env', '.env.*', '.netrc', '*.local'))
# JSON encoding is also valid for quoting paths in this sandbox profile.
import json
(root/'sandbox.sb').write_text('(version 1)\n(allow default)\n(deny network*)\n(deny file-write*)\n(allow file-write* (subpath '+json.dumps(str(root))+') (literal "/dev/null"))\n(deny file-read* (subpath '+json.dumps(str(home))+'))\n')
PY
printf 'Test artifacts: %s\n' "$task_root"
case "$(uname -s)" in
  Darwin)
    exec /usr/bin/sandbox-exec -f "$task_root/sandbox.sb" \
      /usr/bin/env DOTFILES_TEST_ROOT="$task_root" "$python_bin" -I "$task_root/repo/tests/test_portability.py" "$@"
    ;;
  Linux)
    if ! command -v bwrap >/dev/null 2>&1; then
      echo 'Linux sandbox requires bubblewrap (bwrap); no unsandboxed fallback is run.' >&2
      exit 1
    fi
    exec bwrap --die-with-parent --unshare-net --ro-bind / / \
      --bind "$task_root" "$task_root" --tmpfs "$HOME" --proc /proc --dev /dev \
      /usr/bin/env DOTFILES_TEST_ROOT="$task_root" "$python_bin" -I "$task_root/repo/tests/test_portability.py" "$@"
    ;;
esac
