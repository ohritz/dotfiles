#!/usr/bin/env zsh

ZDOTDIR="${ZDOTDIR:-"$HOME/.zsh"}"

gh completion --shell zsh >|"$ZDOTDIR/completions/_gh" && echo "gh completion installed"
docker completion zsh >|"$ZDOTDIR/completions/_docker" && echo "docker completion installed"
kubectl completion zsh >|"$ZDOTDIR/completions/_kubectl" && echo "kubectl completion installed"
oc completion zsh >|"$ZDOTDIR/completions/_oc" && echo "oc completion installed"

echo "Run to install completions: \n
    zinit creinstall "$TM_LOCAL_DEV_PATH"completions \ \r
    zinit creinstall /home/linuxbrew/.linuxbrew/share/zsh/site-functions \ \r
    zinit creinstall "$ZDOTDIR"/completions\n"
