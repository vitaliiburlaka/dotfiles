#!/usr/bin/env sh

echo "\n"
echo "#############################"
echo "# Installing various programs from brew from brew.sh"
echo "#############################"
echo "\n"

# *********************************
# zsh
brew install zsh zsh-completions
# set it as default shell
chsh -s /bin/zsh

# *********************************
# highlight

echo $'installing highlight'
brew unlink highlight
brew install highlight

# *********************************
# jq command line json parser
brew install jq

brew install neofetch
brew install htop
brew install cowsay
brew install fortune
brew install httpie
brew install macvim
brew install tree
