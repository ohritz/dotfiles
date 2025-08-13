#!/usr/bin/env zsh

# Compile zsh files for better performance
# This script is run by chezmoi when zsh files change

set -e

ZDOTDIR="${ZDOTDIR:-$HOME/.zsh}"

echo "Compiling zsh files for better performance..."

# Compile main rc files
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    zcompile "$ZDOTDIR/.zshrc"
    echo "✓ Compiled .zshrc"
fi

if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
    zcompile "$ZDOTDIR/.p10k.zsh"
    echo "✓ Compiled .p10k.zsh"
fi

# Compile function files
if [[ -d "$ZDOTDIR/functions" ]]; then
    for func_file in "$ZDOTDIR"/functions/*.zsh(.N); do
        zcompile "$func_file"
    done
    echo "✓ Compiled function files"
fi

# Compile completion files
if [[ -d "$ZDOTDIR/completions" ]]; then
    for comp_file in "$ZDOTDIR"/completions/_*(.N); do
        zcompile "$comp_file"
    done
    echo "✓ Compiled completion files"
fi

echo "Zsh compilation complete!"
