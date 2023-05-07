
gitcm () {
    git commit -m "$*"
}

git-remote:gone:ls() {
    git fetch --all -p; git branch -vv | grep ": gone]" | awk '{ print $1 }'
}

git-remote:gone:rm() {
    local isForce=$([[ "${1:-''}" == "-f" ]] && echo 'forced')
    local branches=$(git fetch --all -p -q; git branch -vv | grep ": gone]" | awk '{ print $1 }')
    echo "${branches[*]}"
    echo "${Green}Cleaning branches.${Color_End} use -f if there are unmerged to remove."
    if [[ -z "$isForce" ]] then;
        echo $branches[@] | xargs -r -n 1 git branch -d
    else
        echo "${Red}forced, unmerged branches will be removed${Color_End}"
        echo $branches[@] | xargs -r -n 1 git branch -D
    fi
}

git-new-feature() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    local desc="${2:?'Usage: call with description as second arg.'}"
    # desc is cleaned ([/] and [space] are replaced with -) ([.], ["] and ['] are replace with nothing) and all to lower.
    desc="$(echo $desc | sed 's/[\/| ]/-/g' | sed 's/[\.|\"|\x27]//g' | tr '[:upper:]' '[:lower:]')"
    local branchname="feature/${taskId}-${desc}"
    echo "creating new branch $branchname from master"
    git fetch -a
    git co -b $branchname origin/master
    # git push --set-upstream origin $branchname
}

git-task-feature() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    echo "logging in to az devops"
    login_az_devops

    local pbiTitle="$(get_board_item_title $taskId)"
    echo "Title of task $taskId is $pbiTitle"
    git-new-feature $taskId $pbiTitle
}

git-co-task() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    local branch="$(git branch -r | grep $taskId | sed -e 's/origin\///' | awk '{$1=$1};1')"
    git co $branch
}

git-create-pr() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    local body="${2:-""}"
    echo "logging in to az devops"
    login_az_devops
    local pbiTitle=$(get_board_item_title $taskId)
    echo "Title of task $taskId is $pbiTitle"

    local prTitle="Task $taskId: $pbiTitle (AB#$taskId)"
    gh pr create --title $prTitle --fill
}

git-create-pr-draft() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    local body="${2:-""}"
    echo "logging in to az devops"
    login_az_devops
    local pbiTitle="$(get_board_item_title $taskId)"
    echo "Title of task $taskId is $pbiTitle"

    local prTitle="Task $taskId: $pbiTitle (AB#$taskId)"
    gh pr create -d --title $prTitle --fill
}

g_tst() {
    local body="${2:-''}"
    echo "${body}"
}