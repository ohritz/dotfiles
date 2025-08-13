


# in your .bashrc/.zshrc/*rc
bathelp() {
  bat --plain --language=help "$@"
}

help() {
  "$@" --help 2>&1 | bathelp
}
