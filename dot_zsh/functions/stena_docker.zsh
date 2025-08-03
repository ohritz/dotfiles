PROJECTS_ROOT="${HOME}/dev/stena"
export DOCKER_REGISTRY="quay.io"
TAG_REPO="${DOCKER_REGISTRY}/stena"

reload_local_dev() {
    source "${TM_LOCAL_DEV_PATH}/aliases"
}

build:docker() {
    docker build $1 -t $2
}

build:freight-build-tools() {
    local WORKING_DIR="${PROJECTS_ROOT}/freight-build-tools"
    local TAG="${TAG_REPO}/freight-build-tools"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:freight-flip() {
    local WORKING_DIR="${PROJECTS_ROOT}/freight-flip"
    local TAG="${TAG_REPO}/freight-flip"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:freight-ca-sync-mongodb() {
    local WORKING_DIR="${PROJECTS_ROOT}/freight-ca-sync-mongodb"
    local TAG="${TAG_REPO}/freight-ca-sync-mongodb"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:freight-ca-web() {
    local WORKING_DIR="${PROJECTS_ROOT}/freight-ca-web"
    local TAG="${TAG_REPO}/freight-ca-web"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-client() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-client"
    local TAG="${TAG_REPO}/tm-client"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-forecast-api-beta() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-forecast-api-beta"
    local TAG="${TAG_REPO}/tm-forecast-api-beta"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-internal-api() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-internal-api"
    local TAG="${TAG_REPO}/tm-internal-api"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-price-api() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-price-api"
    local TAG="${TAG_REPO}/tm-price-api"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-build-tools() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-build-tools"
    local TAG="${TAG_REPO}/tm-build-tools"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-departure-db() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-departure-db"
    local TAG="${TAG_REPO}/tm-departure-db"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-freight-api() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-freight-api"
    local TAG="${TAG_REPO}/tm-freight-api"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-local-dev() {
    local TAG="${TAG_REPO}/ "

    build:docker $WORKING_DIR "${TAG}:latest"
    local WORK
    ING_DIR="${PROJECTS_ROOT}/tm-local-dev"
    local TAG="${TAG_REPO}/OJECTS_ROOT}/tm-local-dev"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-task-api() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-task-api"
    local TAG="${TAG_REPO}/tm-task-api"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-capacity-api-v2() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-capacity-api-v2"
    local TAG="${TAG_REPO}/tm-capacity-api-v2"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-docs() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-docs"
    local TAG="${TAG_REPO}/tm-docs"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-freight-mis-api() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-freight-mis-api"
    local TAG="${TAG_REPO}/tm-freight-mis-api"

    build:docker $WORKING_DIR "${TAG}:latest"
}

build:tm-poc() {
    local WORKING_DIR="${PROJECTS_ROOT}/tm-poc"

    source "${WORKING_DIR}/dev.sh"
    cd $WORKING_DIR
    docker:build all
}

prune-quay-images() {
    docker images --filter 'reference=quay.io/*/*' --format "{{.ID}}" | xargs docker rmi $1
}
