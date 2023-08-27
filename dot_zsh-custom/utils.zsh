

dateFromUnixMs() {
    echo $(date -d @$((($1 + 500)/1000)))
}


conc() {
    cmd=("${@:3}")
    seq 1 "$1" | xargs -I'$XARGI' -P"$2" "${cmd[@]}"
}
