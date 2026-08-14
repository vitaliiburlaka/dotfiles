# dotfiles

Personal macOS development setup: zsh, git, Homebrew, node, VS Code, iTerm2.
Take anything you want, but at your own risk.

Works on both Intel and Apple Silicon — Homebrew's prefix is detected at
runtime rather than hardcoded, so nothing here assumes `/usr/local`.

**Contents**

- [Requirements](#requirements)
- [Install](#install)
- [Repo layout](#repo-layout)
- [What goes where](#what-goes-where)
- [Commands](#commands)
- [Aliases](#aliases)
- [Backups](#backups)
- [Secrets](#secrets)
- [Packages](#packages)
- [Git configuration](#git-configuration)
- [Shell startup](#shell-startup)
- [Editors and terminal](#editors-and-terminal)
- [Troubleshooting](#troubleshooting)
- [Design notes](#design-notes)

## Requirements

macOS, plus:

| Needed | For |
| ------ | --- |
| Xcode Command Line Tools | `git`, `make` — not in stock macOS |
| [Homebrew](https://brew.sh) | everything in the `Brewfile` |
| zsh + [oh-my-zsh](https://ohmyz.sh) | `.zshrc` (zsh is the macOS default since Catalina) |

bash is supported as a fallback shell but is not the daily driver.

## Install

On a brand new Mac:

```bash
sudo softwareupdate -i -a
xcode-select --install
```

Then install Homebrew, and clone and run:

```bash
git clone https://github.com/vitaliiburlaka/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

Or, with only `curl` available:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/vitaliiburlaka/dotfiles/master/remote-install.sh)"
```

`remote-install.sh` only clones the repo to `~/.dotfiles` — it deliberately
stops before running `./install`, so you can read what you just downloaded
first.

### What `install` does

1. Symlinks every managed file into `$HOME`, backing up anything already
   there (see [Backups](#backups)).
2. Creates an empty `chmod 600` `~/.secret` if none exists.
3. Runs `brew bundle` against the `Brewfile`.
4. Installs nvm and the latest LTS node, if `~/.nvm` is absent.
5. Runs `code.sh` to install VS Code extensions.

It is **safe to run repeatedly**. Links already pointing at the right place
are reported as `ok` and left alone; steps 3–5 are themselves idempotent.

| Flag | Effect |
| ---- | ------ |
| `--link-only` | Only step 1–2. Skips Homebrew, nvm and VS Code. |
| `--no-zip` | Leave the backup as a folder instead of zipping it. |
| `--help` | Usage. |

## Repo layout

```
.aliases                 shell aliases, sourced by both zsh and bash
.bash_profile            sources .bashrc
.bashrc                  bash config — fallback shell
.gitconfig               git identity, aliases and defaults
.gitignore               ignores for this repo
.npmrc                   npm defaults; token comes from the environment
.zshrc                   zsh config — the daily driver
Brewfile                 formulae, casks and taps (brew bundle)
backup                   on-demand snapshot script
code.sh                  VS Code extension installer
com.googlecode.iterm2.plist   iTerm2 preferences (read in place, not linked)
functions                shell functions, linked as ~/.functions
install                  the installer
lib/archive.sh           shared backup/archive helpers + the managed-file list
remote-install.sh        one-liner bootstrap for a fresh machine
sublime/                 Sublime Text preferences
vscode-settings.json     VS Code settings
```

## What goes where

| Repo file | Linked to |
| --------- | --------- |
| `.zshrc` | `~/.zshrc` |
| `.bashrc`, `.bash_profile` | `~/.bashrc`, `~/.bash_profile` |
| `.aliases` | `~/.aliases` |
| `functions` | `~/.functions` |
| `.gitconfig` | `~/.gitconfig` |
| `.npmrc` | `~/.npmrc` |
| `vscode-settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `sublime/Preferences.sublime-settings` | Sublime Text's `Packages/User/` |

The list lives in one place — `managed_pairs()` in `lib/archive.sh` — so
`install` links and `backup` snapshots exactly the same set.

`com.googlecode.iterm2.plist` is **not** symlinked. iTerm2 reads it directly;
see [Editors and terminal](#editors-and-terminal).

## Commands

Defined in `functions`, linked as `~/.functions`. All four accept `--help`.

### `pdf-compress <in.pdf> <out.pdf> [quality]`

Compress a PDF with ghostscript. `quality` is either a Distiller preset or a
number, which is read as a target DPI:

| Quality | Result |
| ------- | ------ |
| `screen` | 72 dpi, smallest — the default |
| `ebook` | 150 dpi |
| `printer` | 300 dpi |
| `prepress` | 300 dpi, preserves colour |
| `default` | broadly useful, larger files |
| *number* | downsample every image to that DPI |

```bash
pdf-compress big.pdf small.pdf ebook
pdf-compress big.pdf small.pdf 150
```

Note that compressing an already-small or text-only PDF can make it slightly
*larger* — the presets add structure that only pays off on image-heavy files.

### `pdf-merge <out.pdf> <in.pdf>...`

Concatenate PDFs into one.

### `flac-to-tracks [--cue FILE] [--keep-source]`

Split one album-length FLAC into per-track FLACs using its cue sheet, tag each
track from the cue, and rename them to `NN - Title.flac`. The original album
file moves to `./backup/` unless `--keep-source` is given.

The cue sheet is auto-detected in the current directory; `--cue` overrides.

Requires CD-quality source audio (44.1 kHz / 16-bit / stereo) — `shnsplit`
rejects `m:ss.ff` cue timestamps on anything else.

### `flac-to-alac [--cover FILE] [--cue FILE] [--cleanup]`

Convert every FLAC in the current directory to ALAC `.m4a`, embedding cover
art. If a cue sheet is present the album is split with `flac-to-tracks` first.

| Flag | Effect |
| ---- | ------ |
| `--cover FILE` | Artwork to embed. Default `folder.jpg`; skipped with a warning if missing. |
| `--cue FILE` | Force a specific cue sheet. |
| `--cleanup` | Delete `./backup/` afterwards instead of keeping the originals. |

Track numbers are normalised before use, so the common `TRACKNUMBER=3/12` and
zero-padded `08` forms do not break the output filenames.

### Older names

`pdfcomp2pres`, `pdfcomp2res`, `convert_flac_to_alac` and
`convert_cue_flac_to_alac` still work — they are aliases to the above.

## Aliases

From `.aliases`. Sourced by both zsh and bash.

**Navigation** — `..` `...` `....` `.....` walk up; `-` returns to the
previous directory; `home`, `p` (`~/Projects`), `apps`, `docs`, `dls`,
`pics`, `music`, `movies`, `desktop`; `o` opens the current directory in
Finder.

**Listing** — `ls` (coloured), `la` (hidden), `ll` (long), `l`, `l1`,
`total-files`.

**Files and system**

| Alias | Does |
| ----- | ---- |
| `dsclean` | Delete every `.DS_Store` below the current directory |
| `space` / `usage` | Directory sizes / disk free |
| `tu` | `top` sorted by CPU |
| `encode-file` | ISO-8859-1 → UTF-8 |
| `node-spotlight-ignore` | Stop Spotlight indexing `node_modules` |
| `showall` / `hideall` | Toggle hidden files in Finder |
| `showdesktop` / `hidedesktop` | Toggle desktop icons |
| `afk` | Sleep the display |
| `urlencode` | URL-encode an argument |

**Network**

| Alias | Does |
| ----- | ---- |
| `ip` | Public IP, via icanhazip with ifconfig.me as backup |
| `lip` | LAN IP of `en0` |
| `ips` | All interface addresses |
| `ifactive` | Interfaces that are actually up |
| `flushdns` | Flush the DNS cache (needs sudo) |

**Shell and tools** — `sz`/`ez` and `sb`/`eb` reload or edit the zsh/bash
config; `path` prints `$PATH` one entry per line; `syslog` tails the unified
log; `week` prints the ISO week number; `weather` and `moon` hit wttr.in.

**Homebrew** — `bup` (update, upgrade, cleanup), `bout` (outdated),
`bdump` (regenerate the `Brewfile` from what is installed).

**Git and containers** — `gti` (typo catcher), `public-key` (copy your SSH
public key to the clipboard), `dps`, `k`.

> **Adding an alias:** `.aliases` is sourced *after* oh-my-zsh, so a name
> defined here silently overrides a plugin's. Check `alias <name>` first.
> `gst`, `gco` and `gb` already come from the omz `git` plugin and are
> deliberately not redefined here.

## Backups

Anything already at a target path — a real file, a directory, or a symlink
pointing somewhere other than this repo — is moved into a timestamped,
versioned backup before being replaced:

```
~/dotfiles-backup/dotfiles-backup-20260814-101500.zip   (default)
~/dotfiles-backup/20260814-101500/                      (with --no-zip)
```

Files keep their path relative to `$HOME`, so
`~/Library/Application Support/Code/User/settings.json` is stored under that
same path inside the archive rather than as a bare `settings.json`. Each
archive carries a `MANIFEST.txt` recording every path, whether it was a file,
directory or symlink, where any symlink pointed, and how to restore it.

Symlinks are archived *as symlinks*, so a link into another dotfiles setup
comes back as a link rather than a copy of its target, and a dangling link
survives instead of vanishing. Nothing is written when there is nothing to
back up, so repeat runs leave no empty folders or archives. The zip is
verified with `unzip -t` before the folder it came from is deleted.

Restore a single file:

```bash
unzip -p ~/dotfiles-backup/dotfiles-backup-20260814-101500.zip \
  '*/.zshrc' > ~/.zshrc
```

Restore everything:

```bash
cd ~ && unzip -o ~/dotfiles-backup/dotfiles-backup-20260814-101500.zip
# then move the contents of the timestamped folder into place
```

### On demand

`./backup` takes the same kind of archive whenever you want one. Unlike the
backup `install` takes, it **copies** — nothing on the system is moved or
changed.

| Flag | Effect |
| ---- | ------ |
| `--no-zip` | Leave it as a folder. |
| `--include-secret` | Also include `~/.secret`; the archive becomes `chmod 600`. |
| `--output DIR` | Write somewhere other than `~/dotfiles-backup`. |
| `--help` | Usage. |

It captures:

- every managed file, resolved *through* its symlink so the archive holds
  real content rather than pointers back into this repo
- unmanaged shell config that exists but is tracked nowhere — `.zprofile`,
  `.zshenv`, `.profile`, `.inputrc`, `.editorconfig`, `~/.ssh/config`,
  `~/.config/git/ignore`
- snapshots of installed Homebrew formulae and casks, VS Code extensions, and
  the dotfiles commit it ran from

`~/.secret` is **excluded by default**: it holds API tokens, and an archive
sitting in `$HOME` is easy to copy somewhere less private without thinking.

## Secrets

Nothing secret is committed to this repo. `.zshrc` sources `~/.secret` early,
before anything that might need it, and `install` creates an empty `chmod 600`
one if it is missing. Put tokens there:

```bash
export NPM_TOKEN="..."
export SOME_API_KEY="..."
```

`.npmrc` refers to `${NPM_TOKEN}` rather than containing a token, which is
what makes it safe to commit. `.gitignore` also covers `.secret`, `.env`,
`*.local` and `.netrc` so a stray credential file inside the repo cannot be
committed by accident.

GitHub authentication goes through the `gh` CLI as a git credential helper,
so no token is stored in `.gitconfig` either.

## Packages

`Brewfile` lists 33 formulae, 13 casks and 2 taps — top-level intent only,
generated from `brew leaves --installed-on-request` and then annotated.
Transitive dependencies are left for Homebrew to resolve.

```bash
brew bundle --file=Brewfile          # install everything
brew bundle check --file=Brewfile    # what is missing or outdated
brew bundle cleanup --file=Brewfile  # installed but not listed
bdump                                # regenerate from this machine
```

Anything the shell config actually depends on is listed explicitly, even when
Homebrew would pull it in anyway — `ghostscript` for the PDF commands,
`cuetools`/`shntool`/`ffmpeg`/`flac` for the audio ones, `bind` for the `dig`
that the IP aliases use. A package present only as someone else's dependency
disappears on the next `brew autoremove`.

node is **not** in the `Brewfile`: it is managed by nvm, installed via the
official installer. A node formula would shadow it.

## Git configuration

Identity, credential helpers, aliases, and behavioural defaults.

| Setting | Why |
| ------- | --- |
| `init.defaultBranch = main` | New repos stop starting on `master` |
| `push.autoSetupRemote = true` | `git push` on a new branch sets upstream instead of erroring |
| `pull.rebase = true` | No merge commit for every routine pull |
| `fetch.prune = true` | Drop refs for branches deleted upstream |
| `rerere.enabled = true` | Replay a conflict resolution when it reappears |
| `diff.colorMoved = zebra` | Moved lines read differently from added/removed |
| `diff.algorithm = histogram` | Better hunk boundaries |
| `core.excludesfile` | `~/.config/git/ignore`, made explicit |

Aliases: `co` `br` `cm` `st` `unstage` `last` `poh` (push origin HEAD).

Credentials for `github.com` and `gist.github.com` are resolved by
`gh auth git-credential`.

## Shell startup

zsh starts in roughly **0.2s**, bash in under **0.1s**. Both were multi-second
before; the work to get there is worth not undoing by accident.

What keeps it fast:

- **nvm is never sourced at startup.** The default version's `bin` directory
  is put on `PATH` directly, so `node` and `npm` work immediately. `nvm`
  itself is a stub that loads the real thing on first call. Sourcing nvm plus
  its completions costs ~1.9s.
- **conda is lazy** the same way — its `shell.zsh hook` spawns Python and
  costs ~0.7s.
- **oh-my-zsh's auto-update check is disabled**; run `omz update` by hand.
- **No explicit `gpgconf --launch gpg-agent`** — gpg starts the agent on
  demand via its socket. The explicit launch cost ~1.4s per shell.

The oh-my-zsh plugin list — `git brew macos node npm yarn python` — was
measured and is effectively free (git +30ms, the rest within noise of zero),
so it does not need trimming.

`SHARE_HISTORY` is the one deliberate cost: ~40ms, because it re-reads the
history file so open tabs see each other's commands. Drop that line in
`.zshrc` if it ever stops being worth it.

Profile a change with:

```bash
zsh -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -20
for i in 1 2 3 4 5; do /usr/bin/time zsh -i -c exit; done
```

### PATH

`PATH` is built in exactly one place per shell — the top of `.zshrc`, and a
single guarded block in `.bashrc`. Both de-duplicate and both strip empty
elements inherited from a parent process.

> **Never introduce an empty element** — a leading, trailing or doubled colon.
> An empty `PATH` element means *the current directory*, so `./ls` would beat
> `/bin/ls` inside any untrusted checkout. This config used to have one.

## Editors and terminal

**VS Code** — `vscode-settings.json` is symlinked into place; `code.sh`
installs the extension list. Regenerate it with `code --list-extensions`.
`python.defaultInterpreterPath` is machine-specific: VS Code settings have no
shell expansion, so that absolute path needs editing on Apple Silicon.

**iTerm2** — the plist is not symlinked. iTerm2 loads it itself:
**Settings → General → Preferences → Load preferences from a custom folder**,
pointed at this repo. Set the save behaviour to manual there too, otherwise
iTerm rewrites the 59KB plist on every quit and every preference tweak shows
up as a large diff.

**Sublime Text** — preferences are linked into whichever support directory
exists; Sublime Text 4 dropped the `3` suffix from the folder name.

## Troubleshooting

**A command is missing after a fresh install.** `install` skips VS Code
extensions when `code` is not on `PATH` — enable it from VS Code's command
palette (*Shell Command: Install 'code' command in PATH*) and re-run.

**`node` not found.** `.zshrc` resolves the nvm default from
`~/.nvm/alias/default`. If that alias points at something unusual, it falls
back to the highest installed version. Run `nvm alias default node` to fix.

**Shell got slow.** Profile with `zprof` (above) before changing anything.
The usual cause is something new being sourced eagerly at startup.

**`install` says "File exists".** It should not — links are created with
`ln -sfn` and anything else is backed up first. If you see this, the target's
parent directory is likely not writable.

**Recovering an overwritten file.** Look in `~/dotfiles-backup/`; every run
that replaced something left a timestamped archive with a `MANIFEST.txt`.

**Reverting entirely.** Remove the symlinks and restore from the oldest
backup archive. The links are all listed in [What goes where](#what-goes-where).

## Design notes

A few decisions that are easy to undo without noticing why they were made:

- **Homebrew's prefix is detected with a directory test**, not
  `brew --prefix`. The latter is a subprocess and would put startup cost back.
- **The managed-file list lives in `lib/archive.sh`**, not in `install`, so
  `backup` cannot drift out of sync with it.
- **`zip -y`** is required when archiving: without it, zip follows symlinks,
  turning a link into a copy of its target and dropping dangling links from
  the archive entirely.
- **npm config uses dashed key names.** The dotted forms (`init.license`) are
  accepted silently and then ignored — `npm init` used ISC and 1.0.0 for years
  because of it.
- **`.aliases` loads after oh-my-zsh**, so it wins any name collision. That is
  convenient and also how a redefined `gbr` quietly shadowed the plugin's
  `git branch --remote` for a long time.
