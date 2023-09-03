source $ZSH_CUSTOM/_spinner.sh

function spinner() {
  local pid=$1
  _spinner $pid
}
