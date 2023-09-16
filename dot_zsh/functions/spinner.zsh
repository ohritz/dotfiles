source $ZDOTDIR/functions/_spinner.sh

function spinner() {
  local pid=$1
  _spinner $pid
}
