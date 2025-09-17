#!/usr/bin/env bash

main() {
    if [[ ! -d "${ZDOTDIR}/evals" ]] ; then
        mkdir -p "${ZDOTDIR}/evals"
    fi

    fzf --zsh > "${ZDOTDIR}/evals/fzf.zsh"
    zoxide init zsh > "${ZDOTDIR}/evals/zoxide.zsh"
}

main
