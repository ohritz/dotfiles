check-for-server-cert() {
    local tempout=$(mktemp)
    trap "rm -f $tempout" EXIT
    local address=${1:?"Missing address mate"}
    local port=${2:-443}
    echo "running nmap for address: $address and port: $port"
    (nmap -sV -p $port -vv --script ssl-cert $address) >$tempout 2>&1 &
    spinner $!
    local output=$(cat $tempout)
    echo $output | grep -oPz '.*(\| ssl-cert:(?:.|\r|\n)*\|_-----END CERTIFICATE-----(?:\r|\n))' | sed 's/[|  | _]//g'
}
