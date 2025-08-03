

function set_prompt_message() {
  local message="$1"
  local level="${2:-warn}"  # default to 'warn' if not provided

  declare -g -a OHR_PROMPT_MESSAGE

  if [[ -z "$message" ]]; then
    echo "Error: No message provided." >&2
    return 1
  fi

  case "$level" in
    info|warn|error)
      ;;
    *)
      echo "Error: Invalid level '$level'. Use 'info', 'warn', or 'error'." >&2
      return 1
      ;;
  esac

  OHR_PROMPT_MESSAGE+=("${level}:${message}")
}

function prompt_my_message() {
  declare -g -a OHR_PROMPT_MESSAGE

  local _fg _level _message

  for entry in "${OHR_PROMPT_MESSAGE[@]}"; do
    _level="${entry%%:*}"
    _message="${entry#*:}"

    case "$_level" in
      info)  _fg=blue ;;
      warn)  _fg=yellow ;;
      error) _fg=red ;;
      *)     _fg=magenta ;;
    esac

    p10k segment -c 0 -e -t "$_message" -f "$_fg"
  done

  OHR_PROMPT_MESSAGE=()
}


