#!/usr/bin/env sh

echo ""
echo "#############################"
echo "# Installing applications via cask from cask.sh"
echo "#############################"
echo ""

# get current location
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# *********************************
# Visual studio code
brew cask uninstall --force visual-studio-code && brew cask install visual-studio-code

if [ -L ~/Library/Application\ Support/Code/user/settings.json ]; then
  echo "found old visual studio code settings. removing..."
  rm ~/Library/Application\ Support/Code/User/settings.json
fi

ln -s $DIR/vscode-settings.json ~/Library/Application\ Support/Code/User/settings.json

# *********************************
brew cask install chrome
brew cask install iterm2
brew cask install mpv
brew cask install discord
brew cask install obs
brew cask install spotify
brew cask install miniconda
# brew cask install alfred
# brew cask install zoomus
# brew cask install insomnia