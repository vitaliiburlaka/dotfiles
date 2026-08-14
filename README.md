# dotfiles

These are my dotfiles. Take anything you want, but at your own risk.

Targets macOS, on both Intel and Apple Silicon — Homebrew's prefix is
detected at runtime rather than hardcoded.

## Install

On a brand new Mac:

    sudo softwareupdate -i -a
    xcode-select --install

The Xcode Command Line Tools include `git` and `make`, which stock macOS does
not ship. Then install [Homebrew](https://brew.sh) and clone this repo:

    git clone https://github.com/vitaliiburlaka/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ./install

Or, with only `curl` available:

    bash -c "`curl -fsSL https://raw.githubusercontent.com/vitaliiburlaka/dotfiles/master/remote-install.sh`"

`install` is safe to run repeatedly. It reports `ok` for links that are
already correct, and never touches anything else without backing it up first.

    ./install --link-only   just the symlinks, skip Homebrew / nvm / VS Code
    ./install --no-zip      leave the backup as a folder instead of zipping
    ./install --help

## Backups

Anything already sitting at a target path — a real file, a directory, or a
symlink pointing somewhere other than this repo — is moved into a
timestamped, versioned backup before being replaced:

    ~/dotfiles-backup/dotfiles-backup-20260814-101500.zip   (default)
    ~/dotfiles-backup/20260814-101500/                      (with --no-zip)

Files keep their path relative to `$HOME`, so
`~/Library/Application Support/Code/User/settings.json` is stored under that
same path inside the archive rather than as a bare `settings.json`. Each
backup carries a `MANIFEST.txt` listing what was taken, whether it was a file
or a symlink (and where that symlink pointed), and how to restore it.

Symlinks are archived as symlinks, so a link into another dotfiles setup
comes back as a link rather than a copy of its target. Nothing is written
when there is nothing to back up, so re-running leaves no empty artifacts.
The zip is verified before the folder it came from is removed.

To restore a single file:

    unzip -p ~/dotfiles-backup/dotfiles-backup-20260814-101500.zip \
      '*/.zshrc' > ~/.zshrc

### Backing up on demand

`./backup` takes the same kind of archive whenever you want one. Unlike the
backup `install` takes, it **copies** — nothing on the system is moved or
changed:

    ./backup                    snapshot to ~/dotfiles-backup/<stamp>.zip
    ./backup --no-zip           leave it as a folder
    ./backup --include-secret   also include ~/.secret
    ./backup --output DIR       write somewhere else
    ./backup --help

It captures every file this repo manages (resolved through the symlinks, so
the archive holds real content rather than pointers back into the repo),
unmanaged shell config that exists but is not tracked here — `.zprofile`,
`.zshenv`, `.profile`, `.inputrc`, `.editorconfig`, `~/.ssh/config`,
`~/.config/git/ignore` — and snapshots of the installed Homebrew packages,
VS Code extensions, and the dotfiles commit it ran from.

`~/.secret` is **excluded by default**, since it holds API tokens and an
archive in `$HOME` is easy to copy somewhere less private without thinking.
With `--include-secret` the archive is written `chmod 600`.

`install` and `backup` share `lib/archive.sh`, so both write the same format
and agree on which files are managed.

## What goes where

| Repo file                            | Linked to                                                  |
| ------------------------------------ | ---------------------------------------------------------- |
| `.zshrc`                             | `~/.zshrc`                                                 |
| `.bashrc`, `.bash_profile`           | `~/.bashrc`, `~/.bash_profile`                             |
| `.aliases`                           | `~/.aliases`                                               |
| `functions`                          | `~/.functions`                                             |
| `.gitconfig`                         | `~/.gitconfig`                                             |
| `.npmrc`                             | `~/.npmrc`                                                 |
| `vscode-settings.json`               | `~/Library/Application Support/Code/User/settings.json`    |
| `sublime/Preferences.sublime-settings` | Sublime Text's `Packages/User/`                          |

Packages come from the `Brewfile` (`brew bundle`), VS Code extensions from
`code.sh`, and node from nvm's official installer.

`com.googlecode.iterm2.plist` is not symlinked. iTerm2 reads it directly:
**Preferences → General → Preferences → Load preferences from a custom
folder**, pointed at this repo.

## Commands

Defined in `functions` (linked as `~/.functions`). All take `--help`.

    pdf-compress <in.pdf> <out.pdf> [quality]

Compress a PDF. `quality` is either a ghostscript preset — `screen`
(default), `ebook`, `printer`, `prepress`, `default` — or a number, which is
taken as a target DPI and downsamples every image to it.

    pdf-merge <out.pdf> <in.pdf>...

Concatenate PDFs.

    flac-to-tracks [--cue FILE] [--keep-source]

Split one album-length FLAC into per-track FLACs using its cue sheet, tag
each track from the cue, and name them `NN - Title.flac`. The original moves
to `./backup/`.

    flac-to-alac [--cover FILE] [--cue FILE] [--cleanup]

Convert FLACs in the current directory to ALAC `.m4a` with embedded cover
art (default `folder.jpg`, skipped if absent). If a cue sheet is present the
album is split with `flac-to-tracks` first. Originals move to `./backup/`,
which `--cleanup` deletes.

The previous names — `pdfcomp2pres`, `pdfcomp2res`, `convert_flac_to_alac`,
`convert_cue_flac_to_alac` — still work as aliases.

Note that `.aliases` is sourced *after* oh-my-zsh, so anything defined there
overrides a plugin's alias of the same name. Check with `alias <name>` before
adding one; `gst`, `gco` and `gb` already come from the omz `git` plugin.

## Secrets

Nothing secret lives in this repo. `.zshrc` sources `~/.secret` first, before
anything else, and `install` creates an empty `chmod 600` one if it is
missing. Put API tokens and anything else private there:

```bash
export NPM_TOKEN="..."
```

`.npmrc` refers to `${NPM_TOKEN}` rather than containing a token, so it is
safe to commit.

## Notes

- **Shell startup** is kept around 0.2s. nvm and conda are both loaded
  lazily, and oh-my-zsh's auto-update check is disabled — run `omz update`
  by hand. Profile with:

      zsh -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -20

- **`node` works without loading nvm.** `.zshrc` puts the nvm default
  version's `bin` directory straight on `PATH`; `nvm` itself is a stub that
  loads the real thing on first call.

- **PATH** is built in exactly one place, at the top of `.zshrc`, and is
  de-duplicated with `typeset -U`. Never introduce an empty element (a
  leading, trailing, or doubled colon) — that puts the current directory on
  `PATH`.
