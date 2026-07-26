# cd shortcuts — server profile only. All compose stacks live under /docker.

alias docker-root='cd /docker'

cdd() {
    if [ -z "$1" ]; then
        cd /docker || return
    else
        cd "/docker/$1" || echo "No such stack: /docker/$1"
    fi
}

# Tab-completion for `cdd <stack>` — native completer per shell, no
# bashcompinit/compdef-emulation shim needed on either side.
if [ -n "$BASH_VERSION" ]; then
    _cdd_complete() {
        local cur
        cur="${COMP_WORDS[COMP_CWORD]}"
        COMPREPLY=($(compgen -W "$(ls /docker 2>/dev/null)" -- "$cur"))
    }
    complete -F _cdd_complete cdd
elif [ -n "$ZSH_VERSION" ]; then
    _cdd_complete() {
        local -a stacks
        stacks=(/docker/*(N:t))
        _describe 'stack' stacks
    }
    compdef _cdd_complete cdd
fi
