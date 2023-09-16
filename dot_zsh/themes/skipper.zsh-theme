## skipper theme
# to disable the nvm prompt set
# zstyle ':ohritz:skipper' disable_nvmprompt true

########################################################################

setopt prompt_subst
autoload -U add-zsh-hook

# Must use Powerline font, for \uE0A0 to render.
# ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[magenta]%}\uE0A0 "
ZSH_THEME_GIT_PROMPT_PREFIX="-[\uE0A0%{$fg[white]%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}]"

ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}×"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}✔"

ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[magenta]%}?%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}-%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}»%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}#%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}+%{$fg[white]%}"

# ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED=1
ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE="%{$fg_bold[magenta]%}=%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}↓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}↑%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}↕%{$reset_color%}"

ZSH_THEME_NVM_PROMPT_PREFIX=" [%{$fg[magenta]%}\uE718 "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}]"

ZSH_THEME_KUBECTX_PROMT_PREFIX="-["
ZSH_THEME_KUBECTX_PROMT_SUFFIX="]"

NVM_PROMPT=1
IS_NODE_REPO=0
GIT_CURRENT_BRANCH=""
GIT_DIRTY=""
GIT_REMOTE_STATUS=""

function _conditional_kubectx_prompt_info() {
    if zstyle -t ':ohritz:skipper' disable_nvmprompt; then return; fi
    local current_context=$(kubectx_prompt_info)

    if [ -n "$current_context" ]; then
        echo "${ZSH_THEME_KUBECTX_PROMT_PREFIX}${current_context}${ZSH_THEME_KUBECTX_PROMT_SUFFIX}"
    fi
}

function _is_node_repo() {
    local has_package_json=$(find . -maxdepth 1 -name "package.json" | wc -l)
    echo $has_package_json
}

function _build_git_prompt() {
    local upstream
    GIT_DIRTY=$(parse_git_dirty)
    GIT_REMOTE_STATUS=$(git_remote_status)
    if [ -n "$GIT_CURRENT_BRANCH" ]; then
        # upstream=$(__git_prompt_git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null) && upstream=" -> ${upstream}"
        echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${GIT_CURRENT_BRANCH} ${GIT_DIRTY}${ZSH_THEME_GIT_PROMPT_SUFFIX}${GIT_REMOTE_STATUS}"
    fi
}

function skipper_chpwd() {
    if zstyle -t ':ohritz:skipper' disable_nvmprompt; then
        NVM_PROMPT=0
    else
        NVM_PROMPT=1
    fi
    IS_NODE_REPO=$(_is_node_repo)
}

add-zsh-hook chpwd skipper_chpwd

function skipper_prexec {
}

add-zsh-hook preexec skipper_prexec

function skipper_precmd {
    if [ $NVM_PROMPT -eq 1 ]; then
        if [ ${IS_NODE_REPO} -eq 1 ]; then
            RPROMPT='$(nvm_prompt_info)'
        fi
    fi
    GIT_CURRENT_BRANCH=$(git_current_branch)
}

add-zsh-hook precmd skipper_precmd

PROMPT='┌[$(emoji-clock)%{$fg[green]%}%*%{$reset_color%}]$(_build_git_prompt)
├[%{$fg[green]%}%~%{$reset_color%}]$(_conditional_kubectx_prompt_info)
└➤'
