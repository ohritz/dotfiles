set -euo pipefail

git-remote:gone:ls() {
    git fetch --all -p; git branch -vv | grep ": gone]" | awk '{ print $1 }'
}

git-remote:gone:rm() {
    local isForce=$([[ "${1:-''}" == "-f" ]] && echo 'forced')
    local branches=$(git fetch --all -p -q; git branch -vv | grep ": gone]" | awk '{ print $1 }')
    echo "${branches[*]}"
    echo "${Green}Cleaning branches.${Color_End} use -f if there are unmerged to remove."
    if [[ -z "$isForce" ]]; then
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

git-worktree:add() {
    local branch="${1:?'Usage: call with branch name as first arg.'}"
    [ ! git_is_git_repo ] && return 0
    local repo_dir=$(git rev-parse --show-toplevel)
    local parent_dir=$(dirname $repo_dir)
    local dir_name=$(basename $repo_dir)
    local worktree_dir="$parent_dir/$dir_name-$branch"
    git worktree add $worktree_dir $branch
}

git-worktree:rm() {
    [ ! git_is_git_repo ] && return 0
    local -a worktree_array
    worktree_array=(${(f)"$(git worktree list)"})

    ## if there is only one in the list there are no worktree copies so exit
    if [[ ${#worktree_array[@]} -eq 1 ]]; then
        echo "No worktree copies found"
        return 0
    fi

    ## remove the first line from the worktrees as it is the original repo
    local worktrees=$(printf '%s\n' "${worktree_array[@]:1}")
    local worktree_dir=$(_select_worktree "$worktrees" | awk '{print $1}')

    # if the selections is empty exit
    if [[ -z "$worktree_dir" ]]; then
        echo "No worktree selected"
        return 0
    fi

    echo "Removing $worktree_dir"
    echo "Are you sure? (y/n)"
    read -q
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git worktree remove $worktree_dir
        rm -rf $worktree_dir
    fi
}

git-worktree:cd() {
    [ ! git_is_git_repo ] && return 0
    local current_dir=$(pwd)
    local -a worktree_array
    worktree_array=(${(f)"$(git worktree list)"})

    ## if there is only one in the list there are no worktree copies so exit
    if [[ ${#worktree_array[@]} -eq 1 ]]; then
        echo "No worktree copies found"
        return 0
    fi

    ## if there are only two in the list and we are on the first one we go to the second if we are on the second we go to the first
    if [[ ${#worktree_array[@]} -eq 2 ]]; then
        local first_dir=$(echo "${worktree_array[0]}" | awk '{print $1}')
        local second_dir=$(echo "${worktree_array[1]}" | awk '{print $1}')

        if [[ "$current_dir" == "$first_dir" ]]; then
            cd "$second_dir"
            return 0
        elif [[ "$current_dir" == "$second_dir" ]]; then
            cd "$first_dir"
            return 0
        fi
    fi

    ## remove the entry that matches the current directory from the worktree list, but do not always remove the first item
    local worktrees=$(printf '%s\n' "${worktree_array[@]}" | awk -v cur="$current_dir" '$1 != cur')

    local worktree_dir=$(_select_worktree "$worktrees" | awk '{print $1}')

    # if the selections is empty exit
    if [[ -z "$worktree_dir" ]]; then
        echo "No worktree selected"
        return 0
    fi

    cd $worktree_dir
}

_select_worktree() {
    local worktrees=${1}

        {
        echo "$worktrees" | awk '{
            path=$1;
            commit=$2;
            branch="";
            for (i=3; i<=NF; ++i) branch=branch $i " ";
            gsub(/^\[|\]$/, "", branch);  # Remove [ and ] from branch name
            print path "\t" commit "\t" branch
        }'
    } | column -t | fzf --ansi
}
