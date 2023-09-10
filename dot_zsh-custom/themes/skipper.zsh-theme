# vim:ft=zsh ts=2 sw=2 sts=2

# Must use Powerline font, for \uE0A0 to render.
# ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[magenta]%}\uE0A0 "
ZSH_THEME_GIT_PROMPT_PREFIX="-[\uE0A0%{$fg[white]%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}]"

ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}×"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔"

ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[magenta]%}?%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}-%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[yellow]%}»%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}#%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}+%{$fg[white]%}"

#ZSH_THEME_GIT_SHOW_UPSTREAM=""
ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$fg_bold[magenta]%}↓%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$fg_bold[magenta]%}↑%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$fg_bold[magenta]%}↕%{$reset_color%}"

ZSH_THEME_NVM_PROMPT_PREFIX=" [%{$fg[magenta]%}\uE718 "
ZSH_THEME_NVM_PROMPT_SUFFIX="%{$reset_color%}]"

PROMPT='┌[$(emoji-clock)%{$fg[green]%}%*%{$reset_color%}]$(git_prompt_info)$(git_remote_status) $(git_prompt_status)
├[%{$fg[green]%}%~%{$reset_color%}]-$(_conditional_kubectx_prompt_info)
└➤'

RPROMPT='$(_conditional_nvm_prompt)'
