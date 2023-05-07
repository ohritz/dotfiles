export Red='\033[0;31m'
export Green='\033[0;32m'
export Yellow='\033[0;33m'
export Color_End='\033[0m'

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"

greeting() {
    if [[ is_interactive ]]; then
        local myname=$(whoami)
        local f_msg=$(fortune -as)
        local msg="Hello ${myname}! \n\n ${f_msg}"

        printf ${Green}
        echo "${msg}" | cowsay -f tux -pn
        printf ${Color_End}
    fi
}

is_interactive() {
    if [[ -o login ]]; then
       return 0
    fi
    return 1
}

get-nemo-jwt() {
    local PROJECTS_ROOT="${HOME}/dev/lab/tm-token-getter"
    node "${PROJECTS_ROOT}/index.js"
}
