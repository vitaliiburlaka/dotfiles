#!/usr/bin/env bash
#
# Install VS Code extensions.
#
# Regenerate this list from the current machine with:
#   code --list-extensions
#
# Run via `./install`, or directly with `bash code.sh`.

set -uo pipefail

if ! command -v code > /dev/null 2>&1; then
  echo "\`code\` is not on PATH."
  echo "In VS Code, run: Shell Command: Install 'code' command in PATH"
  exit 1
fi

extensions=(
  # Editor
  editorconfig.editorconfig
  formulahendry.auto-close-tag
  aaron-bond.better-comments
  mikestead.dotenv
  streetsidesoftware.code-spell-checker
  alefragnani.project-manager
  pnp.polacode                            # code screenshots

  # JavaScript / TypeScript
  dbaeumer.vscode-eslint
  esbenp.prettier-vscode
  mgmcdermott.vscode-language-babel
  andys8.jest-snippets
  pflannery.vscode-versionlens
  jpoissonnier.vscode-styled-components

  # Python
  ms-python.python
  ms-python.vscode-pylance
  ms-python.debugpy
  ms-python.isort
  ms-python.vscode-python-envs

  # Jupyter
  ms-toolsai.jupyter
  ms-toolsai.jupyter-keymap
  ms-toolsai.jupyter-renderers
  ms-toolsai.vscode-jupyter-cell-tags
  ms-toolsai.vscode-jupyter-slideshow

  # Go
  golang.go

  # Swift / C++
  swiftlang.swift-vscode
  llvm-vs-code-extensions.lldb-dap
  theqtcompany.qt-core

  # GraphQL
  apollographql.vscode-apollo
  graphql.vscode-graphql
  graphql.vscode-graphql-syntax

  # Git / GitHub
  github.vscode-pull-request-github
  github.vscode-github-actions

  # Containers
  ms-azuretools.vscode-docker
  ms-azuretools.vscode-containers
  ms-vscode-remote.remote-containers

  # AI assistants
  anthropic.claude-code
  openai.chatgpt
  ms-vscode.vscode-copilot-vision

  # Collaboration
  ms-vsliveshare.vsliveshare-pack

  # Themes and icons
  mhartington.oceanic-next
  zhuangtongfa.material-theme
  anotherglitchinthematrix.monochrome
  pawelgrzybek.gatito-theme
  yummygum.city-lights-theme
  vscode-icons-team.vscode-icons
)

for ext in "${extensions[@]}"; do
  code --install-extension "$ext" --force
done

# Removed from this list, and why:
#   CoenraadS.bracket-pair-colorizer-2  built into VS Code; see
#                                       editor.bracketPairColorization.enabled
#   msjsdiag.debugger-for-chrome        folded into the built-in JS debugger
#   Prisma.vscode-graphql               republished as graphql.vscode-graphql
#   eamodio.gitlens                     no longer installed
#   formulahendry.auto-rename-tag       no longer installed
#   VisualStudioExptTeam.vscodeintellicode  no longer installed
