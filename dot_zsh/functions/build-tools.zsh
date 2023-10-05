Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Color_End='\033[0m'

source "${TM_LOCAL_DEV_PATH}/common.sh"

set_buildtools_ca() {
  export BUILD_TOOLS_PATH="${STENA_PROJECTS_ROOT}/freight-build-tools"
  PATH="$PATH:$BUILD_TOOLS_PATH"
}
set_buildtools_nemo() {
  export BUILD_TOOLS_PATH="${STENA_PROJECTS_ROOT}/tm-build-tools"
  PATH="$PATH:$BUILD_TOOLS_PATH"
}

fetch-tm-secret() {
  aws-tm
  aws s3 cp s3://$AWS_SECRET_PATH secrets.json
}
upload-tm-secret() {
  local secretfile=${1:-secrets.json}
  aws-tm
  echo "Writeing new secrets."
  aws s3 cp $secretfile s3://$AWS_SECRET_PATH
  rm $secretfile
}
