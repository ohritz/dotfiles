#!/usr/bin/env zsh

# Setup XDG directories for zsh state and cache files
# This script runs once to create directories and migrate existing files

set -euo pipefail

# Ensure XDG directories are defined (should be in dot_zprofile)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Create XDG directories for zsh
mkdir -p "${XDG_STATE_HOME}/zsh"
mkdir -p "${XDG_CACHE_HOME}/zsh"
mkdir -p "${HOME}/.local/share/zoxide"


echo "XDG directory setup complete!"
echo "History file: ${XDG_STATE_HOME}/zsh/history"
echo "Completion dump: ${XDG_CACHE_HOME}/zsh/.zcompdump"
echo "Command log: ${XDG_STATE_HOME}/zsh/command.log"
