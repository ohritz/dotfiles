
_conditional_kubectx_prompt_info() {
  local current_context=$(kubectx_prompt_info)

  if [ -n "$current_context" ]; then
    echo "${ZSH_THEME_KUBECTX_PROMT_PREFIX}${current_context}${ZSH_THEME_KUBECTX_PROMT_SUFFIX}"
  fi
}
