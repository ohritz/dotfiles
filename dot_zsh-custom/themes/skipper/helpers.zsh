
_conditional_kubectx_prompt_info() {
  local current_context=$(kubectx_prompt_info)

  if [ -n "$current_context" ]; then
    echo "${ZSH_THEME_KUBECTX_PROMT_PREFIX}${current_context}${ZSH_THEME_KUBECTX_PROMT_SUFFIX}"
  fi
}

_is_node_repo() {
  local has_package_json=$(find . -maxdepth 1 -name "package.json" | wc -l)
  echo $has_package_json
}

_conditional_nvm_prompt() {
  if [ $(_is_node_repo) -eq 1 ]; then
    nvm_prompt_info
  fi
}
