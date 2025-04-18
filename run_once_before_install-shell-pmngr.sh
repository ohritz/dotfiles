#!/bin/bash
sudo apt install -y zsh python3 python3-pip
sudo pip3 install --upgrade pip
pip3 install keepercommander
pip3 install --upgrade keepercommander
chsh -s $(which zsh)
