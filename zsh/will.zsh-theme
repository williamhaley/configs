# clone of muse.zsh-theme with my customizations

setopt prompt_subst

# function env_pyenv_load() {
#     eval "$(pyenv init -)"
# }

# function env_nodenv_load() {
#     eval "$(nodenv init -)"
# }

# function check_envs() {
#     if command -v pyenv > /dev/null
#     then
#         printf 🐍
#     fi
#     if command -v nodenv > /dev/null
#     then
#         printf 🚀
#     fi
# }

# add-zsh-hook precmd check_envs
# Put this in the PROMPT somewhere '$(check_envs)'

PROMPT="%m ${FG[117]}%~%{$reset_color%}\$(git_prompt_info)\$(virtualenv_prompt_info)${FG[133]}\$(git_prompt_status) ${FG[077]}ᐅ%{$reset_color%} "

ZSH_THEME_GIT_PROMPT_PREFIX=" ${FG[012]}("
ZSH_THEME_GIT_PROMPT_SUFFIX="${FG[012]})%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" ${FG[133]}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" ${FG[118]}✔"

ZSH_THEME_GIT_PROMPT_ADDED="${FG[082]}✚%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="${FG[166]}✹%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="${FG[160]}✖%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="${FG[220]}➜%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="${FG[082]}═%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="${FG[190]}✭%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_AHEAD="${FG[190]}(↑)%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="${FG[190]}(↓)%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIVERGED="${FG[190]}(↯)%{$reset_color%}"

ZSH_THEME_VIRTUALENV_PREFIX=" ["
ZSH_THEME_VIRTUALENV_SUFFIX="]"
