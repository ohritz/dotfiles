init_wsl_for_mitmproxy() {
    local host_ip

    host_ip=$(ip route show | grep -i default | awk '{ print $3}')
    export HTTP_PROXY="http://${host_ip}:8080"
    export HTTPS_PROXY="http://${host_ip}:8080"

    export NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/mitmproxy-ca-cert.pem

    echo 'run mitmproxy in a terminal on the windows side'
}

unset_wsl_mitmproxy_settings() {
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset NODE_EXTRA_CA_CERTS
}
