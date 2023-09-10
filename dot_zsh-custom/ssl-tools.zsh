check-for-sql-server-cert() {
    local tempout=$(mktemp)
    trap "rm -f $tempout" EXIT
    local address=${1:?"Missing address mate"}
    local port=${2:-1433}
    echo "running nmap for address: $address and port: $port"
    (nmap -sV -p $port -vv -Pn --script ssl-cert $address) >$tempout 2>&1 &
    spinner $!
    local output=$(cat $tempout)
    echo $output | grep -oPz '.*(\| ssl-cert:(?:.|\r|\n)*\|_-----END CERTIFICATE-----(?:\r|\n))' | sed 's/[|  | _]//g'
}

check-for-server-cert() {
    local tempout=$(mktemp)
    trap "rm -f $tempout" EXIT
    local address=${1:?"Missing address mate"}
    local port=${2:-443}
    echo "running openssl s_client for address: $address and port: $port"
    (openssl s_client -showcerts -servername $address -connect $address:$port </dev/null) >$tempout 2>&1 &
    spinner $!
    local output=$(cat $tempout)
    echo $output
}
