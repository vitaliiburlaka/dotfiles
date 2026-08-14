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
already correct, and moves any real file that is in the way into
`~/dotfiles-backup/<timestamp>/` before replacing it. To create the symlinks
without touching Homebrew, nvm or VS Code:

    ./install --link-only

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
