
_conditional_kubectx_prompt_info() {
  local current_context=$(kubectx_prompt_info)
  if [ -n "$current_context" ]; then
    echo "[$current_context]"
  fi
}
