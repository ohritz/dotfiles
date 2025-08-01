# https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/

###
# OK: relay is running and GitHub SSH works

# STARTING: not running, starting for the first time

# RESTARTING: was running but broken, restarting

# FAILED: tried to start, but auth still failed

# UNKNOWN: relay looks alive but we skipped the test due to no TTY
###

ensure_ssh() {
  declare -g OHR_SSH_RELAY_STATUS
  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock

  local npiperelay_cmd="npiperelay.exe -ei -s //./pipe/openssh-ssh-agent"
  local relay_running=0
  local debug_enabled=false

  [[ "$1" == "debug" ]] && debug_enabled=true

  $debug_enabled && echo "[ensure_ssh] Checking for existing relay process..."

  if pgrep -f "$npiperelay_cmd" >/dev/null 2>&1; then
    relay_running=1
    $debug_enabled && echo "[ensure_ssh] Relay process is running."
  else
    $debug_enabled && echo "[ensure_ssh] Relay process is NOT running."
  fi

  if [[ $relay_running -eq 1 ]]; then
    $debug_enabled && echo "[ensure_ssh] Verifying SSH agent relay..."

    local ssh_output
    ssh_output=$(ssh -T git@github.com 2>&1)
    local ssh_exit=$?

    $debug_enabled && echo "[ensure_ssh] ssh exit code: $ssh_exit"
    $debug_enabled && echo "[ensure_ssh] ssh output: $ssh_output"

    if [[ $ssh_exit == 1 && "$ssh_output" == *"successfully authenticated"* ]]; then
      OHR_SSH_RELAY_STATUS="OK"
      $debug_enabled && echo "[ensure_ssh] SSH relay is working."
      return
    else
      OHR_SSH_RELAY_STATUS="RESTARTING"
      $debug_enabled && echo "[ensure_ssh] SSH relay not working. Restarting..."
      pkill -f "$npiperelay_cmd"
      rm -f $SSH_AUTH_SOCK
    fi
  else
    OHR_SSH_RELAY_STATUS="STARTING"
    $debug_enabled && echo "[ensure_ssh] Starting SSH relay..."
    rm -f $SSH_AUTH_SOCK
  fi

  (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$npiperelay_cmd",nofork &) >/dev/null 2>&1
  sleep 0.2

  $debug_enabled && echo "[ensure_ssh] Relay process started. Verifying again..."

  local ssh_output
  ssh_output=$(ssh -T git@github.com 2>&1)
  local ssh_exit=$?

  $debug_enabled && echo "[ensure_ssh] ssh exit code: $ssh_exit"
  $debug_enabled && echo "[ensure_ssh] ssh output: $ssh_output"

  if [[ $ssh_exit == 1 && "$ssh_output" == *"successfully authenticated"* ]]; then
    OHR_SSH_RELAY_STATUS="OK"
    $debug_enabled && echo "[ensure_ssh] SSH relay is now working."
  else
    OHR_SSH_RELAY_STATUS="FAILED"
    $debug_enabled && echo "[ensure_ssh] SSH relay failed to authenticate."
  fi
}

# keep track of the last git root seen
typeset -gA SEEN_GIT_REPOS

function maybe_ensure_ssh() {
  # Check if we're in a git repo
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return

  # Only run once per repo per session
  if [[ -z ${SEEN_GIT_REPOS[$git_root]} ]]; then
    SEEN_GIT_REPOS[$git_root]=1
    ensure_ssh
  fi
}


kill_ssh_pipe() {
  ALREADY_RUNNING=$(
    ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"
    echo $?
  )
  if [[ $ALREADY_RUNNING != "0" ]]; then
    echo "${Red}SSH-Agent relay is not running${Color_End}"
  else
    echo "${Green}Killing SSH-Agent relay...${Color_End}"
    pkill -f "npiperelay.exe -ei -s //./pipe/openssh-ssh-agent"
    rm $SSH_AUTH_SOCK 2>/dev/null
  fi
}

check_ssh() {
  local result

  result="$(ssh -T git@github.com 2>&1)"
  if [[ $? == 1 ]] && [[ "$result" == *"successfully authenticated"* ]]; then
    echo -e "[${Green}Success${Color_End}] - SSH Agent can authenticate to GitHub"
    return 0
  else
    echo -e "[${Red}Failed${Color_End}] - SSH agent cannot authenticate to GitHub"
    return 1
  fi
}

function prompt_my_ssh_relay_status() {
  declare -g OHR_SSH_RELAY_STATUS
  local _fg _text

  case $OHR_SSH_RELAY_STATUS in
    OK | "")
      return  # don't show segment
      ;;
    STARTING | RESTARTING)
      _fg=yellow
      ;;
    FAILED)
      _fg=red
      ;;
    UNKNOWN)
      _fg=magenta
      ;;
    *)
      _fg=blue
      ;;
  esac

  _text="SSH Relay: $OHR_SSH_RELAY_STATUS"
  p10k segment -c 0 -i $'\uf066' +r -t "$_text" -f $_fg
}

wsl-vpnkit() {
  wsl.exe -d wsl-vpnkit service wsl-vpnkit start
}

wsl-vpnkit:stop() {
  wsl.exe -d wsl-vpnkit service wsl-vpnkit stop
}

# Register the hook using zsh's precmd
autoload -Uz add-zsh-hook
add-zsh-hook precmd maybe_ensure_ssh
