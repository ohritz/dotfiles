#!/usr/bin/env zsh

ZDOTDIR="${ZDOTDIR:-"$HOME/.zsh"}"

# Current approach (works well):
command -v gh >/dev/null 2>&1 && gh completion --shell zsh >|"$ZDOTDIR/completions/_gh" && echo "gh completion installed" || echo "gh not found"
command -v docker >/dev/null 2>&1 && docker completion zsh >|"$ZDOTDIR/completions/_docker" && echo "docker completion installed" || echo "docker not found"
command -v kubectl >/dev/null 2>&1 && kubectl completion zsh >|"$ZDOTDIR/completions/_kubectl" && echo "kubectl completion installed" || echo "kubectl not found"
command -v oc >/dev/null 2>&1 && oc completion zsh >|"$ZDOTDIR/completions/_oc" && echo "oc completion installed" || echo "oc not found"
