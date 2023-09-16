# https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/

ensure_ssh() {
  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
  # Configure ssh forwarding
  # need ps -ww to get non-truncated command for matching
  # use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
  ALREADY_RUNNING=$(
    ps -auxww | grep -q "[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent"
    echo $?
  )
  if [[ $ALREADY_RUNNING != "0" ]]; then
    if [[ -S $SSH_AUTH_SOCK ]]; then
      # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
      echo "${Red}removing previous socket...${Color_End}"
      rm $SSH_AUTH_SOCK
    fi
    echo "${Green}Starting SSH-Agent relay...${Color_End}"
    # setsid to force new session to keep running
    # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
  else
    echo "${White}[${Green}SSH RELAY${White}]${Yellow} running${Color_End}"
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

wsl-vpnkit() {
  wsl.exe -d wsl-vpnkit service wsl-vpnkit start
}

wsl-vpnkit:stop() {
  wsl.exe -d wsl-vpnkit service wsl-vpnkit stop
}
