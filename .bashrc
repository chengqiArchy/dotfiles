case $- in
    *i*) ;;
    *) return;;
esac

# Better history management
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTIGNORE='ls:ll:la:cd:pwd:exit:bg:fg:history:clear'
shopt -s histappend cmdhist

# Helpful shell options
shopt -s autocd checkwinsize extglob globstar
bind 'set completion-ignore-case on'
bind 'set bell-style none'
set -o notify

# Prompt with exit status and git info
__prompt_command() {
    local exit_code=$?
    local reset='\[\e[0m\]'
    local bold='\[\e[1m\]'
    local dim='\[\e[2m\]'
    local red='\[\e[31m\]'
    local green='\[\e[32m\]'
    local blue='\[\e[34m\]'
    local status_color=$green
    local git_segment=

    if [[ $exit_code -ne 0 ]]; then
        status_color=$red
    fi

    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        git_segment=" ${dim}(${branch})${reset}"
    fi

    PS1="${status_color}➜ ${bold}\u@\h${reset}:${blue}\w${reset}${git_segment}\n${status_color}\$ ${reset}"
    builtin history -a
    builtin history -n
}
PROMPT_COMMAND=__prompt_command

# Color support for common commands
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
fi
alias ls='ls --color=auto -F'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Handy helpers
alias ..='cd ..'
alias ...='cd ../..'
alias please='sudo $(fc -ln -1)'
alias c='clear'

mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}

# Editor and pager defaults
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS='-R'

# Load bash completion if available
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
    . /etc/bash_completion
fi
