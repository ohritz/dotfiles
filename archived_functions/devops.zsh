login_az_devops() {
  if [[ -z $AZURE_DEVOPS_EXT_PAT ]]; then
    echo $TM_NUGET_FEED_TOKEN | az devops login --only-show-errors
    export AZURE_DEVOPS_EXT_PAT=$TM_NUGET_FEED_TOKEN
  fi
}

get_board_item() {
  local taskId="${1:?Must supply a PBI Id}"
  local boardDetails="$(az boards work-item show --id ${taskId})"
  echo "${boardDetails}"
}

get_board_item_title() {
  local taskId="${1:?Must supply a PBI Id}"
  local title=$(az boards work-item show --id ${taskId} | jq -r '.fields ."System.Title"')
  echo $title
}

ready-to-pull() {
  local taskId="${1:?Must supply a PBI Id}"
  local state=$(az boards work-item update --id ${taskId} --state 'Ready to pull' | jq -r '.fields ."System.State"')
  echo $state
}
