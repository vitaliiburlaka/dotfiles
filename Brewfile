# Brewfile — declarative replacement for the old brew.sh / cask.sh / node.sh.
#
#   brew bundle --file=Brewfile          install everything listed here
#   brew bundle check --file=Brewfile    report what is missing or outdated
#   brew bundle cleanup --file=Brewfile  list installed things NOT listed here
#
# Only top-level intent is listed (generated from `brew leaves
# --installed-on-request` and `brew list --cask`, then annotated); transitive
# dependencies are left for Homebrew to resolve rather than pinned here.
#
# To refresh after installing something new:
#   brew bundle dump --file=Brewfile --force --describe

tap "homebrew/services"
tap "teamookla/speedtest"          # official Ookla speedtest CLI

# ── Shell ────────────────────────────────────────────────────────────────
brew "zsh-syntax-highlighting"     # fish-style highlighting; sourced by .zshrc

# ── Core CLI ─────────────────────────────────────────────────────────────
brew "git"                         # newer than the Xcode CLT version
brew "gh"                          # GitHub CLI; also the credential helper
                                   # configured in .gitconfig
brew "tree"                        # display directories as trees
brew "htop"                        # interactive process viewer
brew "bc"                          # arbitrary precision calculator
brew "yq"                          # YAML/JSON/XML processor, jq for YAML
brew "gnupg"                       # GNU Privacy Guard (OpenPGP)
brew "pinentry-mac"                # native passphrase prompt for gnupg

# ── Network ──────────────────────────────────────────────────────────────
brew "bind"                        # provides dig and host; `ip`/`ips`
                                   # aliases in .aliases depend on dig
brew "mtr"                         # traceroute and ping in one tool
brew "iperf3"                      # measure TCP/UDP/SCTP bandwidth
brew "httpie"                      # friendlier curl for HTTP APIs
brew "teamookla/speedtest/speedtest"  # speedtest.net CLI

# ── Media ────────────────────────────────────────────────────────────────
brew "ffmpeg"                      # convert/record/stream audio and video;
                                   # used by the *_to_alac functions
brew "flac"                        # free lossless audio codec + metaflac
brew "cuetools"                    # cuebreakpoints/cuetag, used by `functions`
brew "shntool"                     # shnsplit, used by `functions`
brew "exiftool"                    # read/write EXIF metadata

# ── Apple / iOS development ──────────────────────────────────────────────
brew "swiftformat"                 # Swift formatter
brew "swiftlint"                   # Swift style and conventions linter
brew "xcodegen"                    # generate .xcodeproj from a YAML spec

# ── Other development ────────────────────────────────────────────────────
brew "python@3.10"                 # pinned interpreter; note that
                                   # vscode-settings.json points at
                                   # /usr/local/bin/python3
brew "skaffold"                    # Kubernetes build/deploy dev loop
brew "molten-vk"                   # Vulkan implemented on top of Metal

# ── Security research ────────────────────────────────────────────────────
brew "aircrack-ng"                 # Wi-Fi security auditing
brew "hashcat"                     # password recovery / hash cracking

# ── macOS utilities ──────────────────────────────────────────────────────
brew "blueutil"                    # get/set bluetooth state from the CLI
brew "innoextract"                 # unpack Inno Setup (.exe) installers

# ── Fun ──────────────────────────────────────────────────────────────────
brew "cowsay"                      # used by nothing, kept for morale
brew "fortune"                     # fortune-cookie generator
brew "neofetch"                    # system info banner

# ── Applications ─────────────────────────────────────────────────────────
cask "iterm2"                      # terminal; loads its prefs from this repo
                                   # (Preferences > General > Preferences)
cask "miniconda"                   # conda; .zshrc loads it lazily from
                                   # $HOMEBREW_PREFIX/Caskroom/miniconda/base
cask "postman"                     # API development client
cask "github-copilot-for-xcode"    # Copilot as an Xcode extension
cask "discord"                     # voice and text chat
cask "obs"                         # live streaming and screen recording
cask "typora"                      # markdown editor
cask "musicbrainz-picard"          # music tagger, pairs with the flac/alac
                                   # conversion functions
cask "diffusionbee"                # run Stable Diffusion locally
cask "upscayl"                     # AI image upscaler
cask "monitorcontrol"              # external monitor brightness/volume
cask "iina"                        # modern macOS media player
cask "vlc"                         # plays everything else

# Note: node is deliberately absent. It is managed by nvm, installed via the
# official nvm-sh installer (see `install`), because the repo already has a
# ~/.nvm checkout and .zshrc puts the nvm default version on PATH and loads
# nvm itself lazily. Installing a node formula here would shadow it.
#
# Also absent, and previously listed in the old brew.sh despite never being
# installed on this machine: jq, zsh, zsh-completions, highlight, macvim.
