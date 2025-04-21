#!/bin/bash
sudo apt install -y zsh python3 python3-pip pipx
pipx ensurepath
pipx install keepercommander
pipx install --upgrade keepercommander
chsh -s $(which zsh)

echo "run keeper shell"
