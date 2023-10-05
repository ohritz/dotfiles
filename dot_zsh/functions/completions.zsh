reload_completions() {
    zinit creinstall "${HOME}/data/projects/stena/tm-local-dev/completions"
    zinit creinstall /home/linuxbrew/.linuxbrew/share/zsh/site-functions
    zinit creinstall "${HOME}/.zsh/completions"
}
