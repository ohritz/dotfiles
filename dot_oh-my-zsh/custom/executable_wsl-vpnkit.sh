#! /bin/sh

USERPROFILE=$(wslpath "$(/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe -c '$env:USERPROFILE' | tr -d '\r')")
CONF_PATH="$USERPROFILE/wsl-vpnkit/wsl-vpnkit.conf"
SOCKET_PATH="/var/run/wsl-vpnkit.sock"
PIPE_PATH="//./pipe/wsl-vpnkit"

VPNKIT_PATH="$USERPROFILE/wsl-vpnkit/wsl-vpnkit.exe"
# NPIPERELAY_PATH="$USERPROFILE/wsl-vpnkit/npiperelay.exe"
NPIPERELAY_PATH="$(which npiperelay.exe)"
TAP_NAME="eth1"
VPNKIT_GATEWAY_IP="192.168.67.1"
VPNKIT_HOST_IP="192.168.67.2"
VPNKIT_LOWEST_IP="192.168.67.3"
VPNKIT_HIGHEST_IP="192.168.67.14"
VPNKIT_WSL2_IP="$VPNKIT_LOWEST_IP"
VPNKIT_DEBUG=
WSL2_GATEWAY_IP="$(cat /etc/resolv.conf | awk '/^nameserver/ {print $2}')"
USE_IPTABLES=1


echo "starting wsl-vpnkit"
if [ -f "$CONF_PATH" ]; then
    . "$CONF_PATH"
    echo "loaded $CONF_PATH"
fi

install () {
    if [ ! -f "$VPNKIT_PATH" ]; then
        mkdir -p "$(dirname $VPNKIT_PATH)"
        cp /files/vpnkit/vpnkit.exe "$VPNKIT_PATH"
        echo "copied vpnkit.exe to $VPNKIT_PATH"
    else
        echo "vpnkit.exe exists at $VPNKIT_PATH"
    fi

    if [ ! -f "$NPIPERELAY_PATH" ]; then
        mkdir -p "$(dirname $NPIPERELAY_PATH)"
        cp /files/npiperelay/npiperelay.exe "$NPIPERELAY_PATH"
        echo "copied npiperelay.exe to $NPIPERELAY_PATH"
    else
        echo "npiperelay.exe exists at $NPIPERELAY_PATH"
    fi
}

relay () {
    socat UNIX-LISTEN:$SOCKET_PATH,fork,umask=007 EXEC:"$NPIPERELAY_PATH -ep -s $PIPE_PATH",nofork
}

relay_wait () {
    echo "waiting for $SOCKET_PATH ..."
    while [ ! -S "$SOCKET_PATH" ]; do
        sleep 0.1
    done
    echo "found $SOCKET_PATH"
}

vpnkit () {
    WIN_PIPE_PATH=$(echo $PIPE_PATH | sed -e "s:/:\\\:g")
    CMD='"$VPNKIT_PATH" \
        --ethernet $WIN_PIPE_PATH \
        --gateway-ip $VPNKIT_GATEWAY_IP \
        --host-ip $VPNKIT_HOST_IP \
        --lowest-ip $VPNKIT_LOWEST_IP \
        --highest-ip $VPNKIT_HIGHEST_IP \
    '
    if [ "$VPNKIT_DEBUG" ]; then
        CMD="$CMD"' --debug'
    fi
    eval "$CMD"
}

tap () {
    vpnkit-tap-vsockd --tap $TAP_NAME --path $SOCKET_PATH
}

tap_wait () {
    echo "waiting for $TAP_NAME ..."
    while [ ! -e "/sys/class/net/$TAP_NAME" ]; do
        sleep 0.1
    done
    echo "found $TAP_NAME"
}

ipconfig () {
    ip a add $VPNKIT_WSL2_IP/255.255.255.0 dev $TAP_NAME
    ip link set dev $TAP_NAME up
    ip route del $(ip route | grep default)
    ip route add default via $VPNKIT_GATEWAY_IP dev $TAP_NAME

    if [ "$USE_IPTABLES" ]; then
        iptables -t nat -A OUTPUT -d $WSL2_GATEWAY_IP -j DNAT --to-destination $VPNKIT_GATEWAY_IP
        iptables -t nat -A POSTROUTING -o $TAP_NAME -j MASQUERADE
    fi
}

close () {
    if [ "$USE_IPTABLES" ]; then
        iptables -t nat -S | grep $VPNKIT_GATEWAY_IP | cut -d " " -f 2- | tr '\n' '\0' | xargs -0 -r -n 1 sh -c 'iptables -t nat -D $1' argv0
        iptables -t nat -S | grep $TAP_NAME | cut -d " " -f 2- | tr '\n' '\0' | xargs -0 -r -n 1 sh -c 'iptables -t nat -D $1' argv0
    fi

    ip link set dev $TAP_NAME down
    ip route add default via $WSL2_GATEWAY_IP dev eth0

    echo "stopped wsl-vpnkit"
    kill 0
}

if [ ${EUID:-$(id -u)} -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

#install
relay &
relay_wait
vpnkit &
tap &
tap_wait
ipconfig
trap close exit
trap exit int term
wait