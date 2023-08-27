
link_nvm_to_global() {
  sudo ln -s "$NVM_DIR/versions/node/$(nvm version)/bin/node" "/usr/local/bin/node"
  sudo ln -s "$NVM_DIR/versions/node/$(nvm version)/bin/npm" "/usr/local/bin/npm"
  sudo ln -s "$NVM_DIR/versions/node/$(nvm version)/bin/npx" "/usr/local/bin/npx"
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
