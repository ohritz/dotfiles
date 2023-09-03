
set-aws-region() {
  local region=${1:?'Missing region'}
  case $region in
    "ireland")
      export AWS_REGION=eu-west-1
    ;;
    "sweden")
      export AWS_REGION=eu-north-1
    ;;
    *)
      echo "Unknown region: $region"
      return 1
    ;;
  esac
}
