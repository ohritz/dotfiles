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

# Migrate history file if it exists in old location
OLD_HISTFILE="${ZDOTDIR:-$HOME/.zsh}/.zsh_history"
NEW_HISTFILE="${XDG_STATE_HOME}/zsh/history"

if [[ -f "$OLD_HISTFILE" && ! -f "$NEW_HISTFILE" ]]; then
    echo "Migrating history file from $OLD_HISTFILE to $NEW_HISTFILE"
    cp "$OLD_HISTFILE" "$NEW_HISTFILE"
    echo "History file migrated successfully"
fi

# Migrate completion dump files if they exist in old location
OLD_COMPDUMP="${ZDOTDIR:-$HOME/.zsh}/.zcompdump"
NEW_COMPDUMP="${XDG_CACHE_HOME}/zsh/.zcompdump"

if [[ -f "$OLD_COMPDUMP" && ! -f "$NEW_COMPDUMP" ]]; then
    echo "Migrating completion dump from $OLD_COMPDUMP to $NEW_COMPDUMP"
    cp "$OLD_COMPDUMP" "$NEW_COMPDUMP"
    echo "Completion dump migrated successfully"
fi

# Also migrate any .zcompdump-* files
for old_dump in "${ZDOTDIR:-$HOME/.zsh}"/.zcompdump-*; do
    if [[ -f "$old_dump" ]]; then
        filename=$(basename "$old_dump")
        new_dump="${XDG_CACHE_HOME}/zsh/${filename}"
        if [[ ! -f "$new_dump" ]]; then
            echo "Migrating completion dump from $old_dump to $new_dump"
            cp "$old_dump" "$new_dump"
        fi
    fi
done

# Migrate command log if it exists in old location
OLD_CMDLOG="$HOME/.zsh_cmdlog"
NEW_CMDLOG="${XDG_STATE_HOME}/zsh/command.log"

if [[ -f "$OLD_CMDLOG" && ! -f "$NEW_CMDLOG" ]]; then
    echo "Migrating command log from $OLD_CMDLOG to $NEW_CMDLOG"
    cp "$OLD_CMDLOG" "$NEW_CMDLOG"
    echo "Command log migrated successfully"
fi

echo "XDG directory setup complete!"
echo "History file: ${XDG_STATE_HOME}/zsh/history"
echo "Completion dump: ${XDG_CACHE_HOME}/zsh/.zcompdump"
echo "Command log: ${XDG_STATE_HOME}/zsh/command.log"
