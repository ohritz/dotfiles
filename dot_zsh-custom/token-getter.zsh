
TM_CONFIG_FOLDER="$HOME/.tm"

if [ ! -d "$TM_CONFIG_FOLDER" ]; then
  mkdir "$TM_CONFIG_FOLDER"
fi

_debug() {
  if [ "$TM_TOKEN_GETTER_DEBUG" ]; then
    echo "$@" >&2
  fi
}

_write-token() {
  local token="${1:?"Missing token"}"
  local expires_at="${2:?"Missing expires_at"}"
  
  _debug "writing token to $TM_CONFIG_FOLDER/token"
  echo "$token" > "$TM_CONFIG_FOLDER/token"
  _debug "writing expires_at to $TM_CONFIG_FOLDER/expires_at"
  echo "$expires_at" > "$TM_CONFIG_FOLDER/expires_at"
}

_read-token() {
  local token
  local expires_at
  _debug "reading token from $TM_CONFIG_FOLDER/token"
  if [ -f "$TM_CONFIG_FOLDER/token" ]; then
    token=$(cat "$TM_CONFIG_FOLDER/token")
  fi
  echo "$token"
}

_read-expires_at() {
  local expires_at
  if [ -f "$TM_CONFIG_FOLDER/expires_at" ]; then
    expires_at=$(cat "$TM_CONFIG_FOLDER/expires_at")
  fi
  echo "${expires_at:-0}"
}

_get_current_time() {
  date +%s
}

_fetch-new-token() {
  local token
  local tempout=$(mktemp)
  trap "rm -f $tempout" EXIT
  local client_id="${OAUTH_CLIENT_ID}"
  local client_secret="${OAUTH_CLIENT_SECRET}"
  local audience="${OAUTH_AUDIENCE}"
  local grant_type="client_credentials"
  
  curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --progress-bar \
  -d "{\"client_id\":\"$client_id\",\"client_secret\":\"$client_secret\",\"audience\":\"$audience\",\"grant_type\":\"$grant_type\"}" \
  -o $tempout \
  "${OAUTH_ISSUER}"
  local output=$(cat $tempout)
  echo $output
}

fetch-auth0-token() {
  local expires_at=$(_read-expires_at)
  local current_time=$(_get_current_time)
  local result
  local token
  local expires_in
  if [[ "$1" == "--debug" ]]; then
    TM_TOKEN_GETTER_DEBUG=1
  fi
  
  trap "unset TM_TOKEN_GETTER_DEBUG" EXIT
  
  
  if [ "$expires_at" -gt "$current_time" ]; then
    _debug "token is still valid for $(((expires_at - current_time) / 60)) minutes"
    token=$(_read-token)
  else
    _debug "token is expired"
    _debug "fetching new token"
    result=$(_fetch-new-token)
    expires_in=$(echo $result | jq -r '.expires_in')
    let "new_expires_at = $expires_in + $current_time"
    _debug "new token expires in $expires_in seconds"
    token=$(echo $result | jq -r '.access_token')
    _write-token "$token" "$new_expires_at"
  fi
  echo "$token"
}
