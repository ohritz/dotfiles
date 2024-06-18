export White="$fg[white]"
export Red="$fg[red]"
export Green="$fg[green]"
export Yellow="$fg[yellow]"
export Color_End="$reset_color"

alias zshconfig="code ~/.zsh"
alias chezmoi-edit="code $HOME/.local/share/chezmoi"
greeting() {
  if [[ is_interactive ]]; then
    local myname=$(whoami)
    local f_msg=$(fortune -as)
    local msg="Hello ${myname}! \n\n ${f_msg}"

    printf ${Green}
    echo "${msg}" | cowsay -f tux -pn
    printf ${Color_End}
  fi
}

is_interactive() {
  if [[ -o login ]]; then
    return 0
  fi
  return 1
}

alias get-nemo-jwt="fetch-auth0-token"

# in your .bashrc/.zshrc/*rc
alias bathelp='bat --plain --language=help'
help() {
  "$@" --help 2>&1 | bathelp
}
