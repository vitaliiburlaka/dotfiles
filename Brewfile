# Brewfile — declarative replacement for the old brew.sh / cask.sh / node.sh.
#
#   brew bundle --file=Brewfile          install everything listed here
#   brew bundle check --file=Brewfile    report what is missing
#   brew bundle cleanup --file=Brewfile  list installed things NOT listed here
#
# Only top-level intent is listed (from `brew leaves --installed-on-request`);
# transitive dependencies are resolved by Homebrew and deliberately omitted.

tap "homebrew/services"
tap "teamookla/speedtest"

# ── Shell ────────────────────────────────────────────────────────────────
brew "zsh-syntax-highlighting"   # sourced by .zshrc

# ── Core CLI ─────────────────────────────────────────────────────────────
brew "git"
brew "gh"                        # also the git credential helper (.gitconfig)
brew "tree"
brew "htop"
brew "bc"
brew "yq"
brew "gnupg"
brew "pinentry-mac"              # GPG pinentry on macOS

# ── Network ──────────────────────────────────────────────────────────────
brew "bind"                      # dig, host
brew "mtr"
brew "iperf3"
brew "httpie"
brew "teamookla/speedtest/speedtest"

# ── Media ────────────────────────────────────────────────────────────────
brew "ffmpeg"
brew "flac"
brew "cuetools"                  # cuebreakpoints/cuetag, used by `functions`
brew "shntool"                   # shnsplit, used by `functions`
brew "exiftool"

# ── Apple / iOS development ──────────────────────────────────────────────
brew "swiftformat"
brew "swiftlint"
brew "xcodegen"

# ── Other development ────────────────────────────────────────────────────
brew "python@3.10"
brew "skaffold"
brew "molten-vk"                 # Vulkan-on-Metal

# ── Security research ────────────────────────────────────────────────────
brew "aircrack-ng"
brew "hashcat"

# ── macOS utilities ──────────────────────────────────────────────────────
brew "blueutil"
brew "innoextract"

# ── Fun ──────────────────────────────────────────────────────────────────
brew "cowsay"
brew "fortune"
brew "neofetch"

# ── Applications ─────────────────────────────────────────────────────────
cask "iterm2"
cask "miniconda"
cask "postman"
cask "github-copilot-for-xcode"
cask "discord"
cask "obs"
cask "typora"
cask "musicbrainz-picard"
cask "diffusionbee"
cask "upscayl"
cask "monitorcontrol"
cask "iina"
cask "vlc"

# Note: node is managed by nvm (installed via the official nvm-sh installer,
# not Homebrew — see the `install` script), so no node formula here. .zshrc
# puts the nvm default version on PATH and loads nvm itself lazily.
