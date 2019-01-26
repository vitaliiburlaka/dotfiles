# dotfiles

These are my dotfiles. Take anything you want, but at your own risk.

It targets macOS systems.

## Install

On a brand new Mac or fresh installed macOS:

    sudo softwareupdate -i -a
    xcode-select --install

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS).
Then, install this repo with `curl` available:

    bash -c "`curl -fsSL https://raw.githubusercontent.com/vitaliiburlaka/dotfiles/master/remote-install.sh`"

This will clone (using `git`), or download (using `curl` or `wget`), this repo to `~/.dotfiles`.

Alternatively, clone manually into the desired location:

    git clone https://github.com/vitaliiburlaka/dotfiles.git ~/.dotfiles


And then symlink files by doing this:

```bash
ln -s ~/.dotfiles/.bashrc ~/.bashrc
# others also
```
