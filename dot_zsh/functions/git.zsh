
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

git-co-task() {
    local taskId="${1:?'Usage: call with task no as first arg.'}"
    local branch="$(git branch -r | grep $taskId | sed -e 's/origin\///' | awk '{$1=$1};1')"
    git co $branch
}
