#!/usr/bin/env sh

echo ""
echo "#############################"
echo "# Running global npm setup from npm.sh"
echo "#############################"
echo ""

# *************************************
# node
#
echo $'installing node via nvm'
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.4/install.sh | bash
echo $'installed nvm\n'

# loading nvm for now
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install stable
nvm alias default stable
nvm use stable

echo $'updating npm\n'
npm i -g npm

echo -e "\n\nGlobal installed npm modules"
echo "=============================="
