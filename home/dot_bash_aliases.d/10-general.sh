# General shell comfort — applies on every profile (workstation + server)

alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias grep='grep --color=auto'
if ls --color=auto / >/dev/null 2>&1; then
    alias ls='ls --color=auto'
else
    alias ls='ls -G'
fi

if command -v apt >/dev/null 2>&1; then
    alias update='sudo apt update && sudo apt upgrade -y'
    alias upgradable='apt list --upgradable'
elif command -v brew >/dev/null 2>&1; then
    alias update='brew update && brew upgrade'
    alias upgradable='brew outdated'
fi

# Wipe shell history, in-memory and on disk. bash and zsh clear their
# in-memory list differently (`history -c` vs. reloading a truncated
# HISTFILE via `fc -R`), so branch on which shell sourced this file.
clh() {
    : > "$HISTFILE"
    if [ -n "$ZSH_VERSION" ]; then
        fc -R "$HISTFILE"
    elif [ -n "$BASH_VERSION" ]; then
        history -c
    fi
}

# Remove stale caches and temp files from $HOME
tidy() {
    local -a targets=(
        "$HOME"/.bash_history-*.tmp
        "$HOME"/.lesshst
        "$HOME"/.wget-hsts
        "$HOME"/.sudo_as_admin_successful
        "$HOME"/.zcompdump-*
    )
    local count=0
    for f in "${targets[@]}"; do
        [ -f "$f" ] || continue
        rm -f "$f" && printf 'removed %s\n' "${f##*/}" && ((count++))
    done
    [ "$count" -eq 0 ] && echo "nothing to tidy"
}

# Kill gpg-agent; it auto-respawns on the next gpg/ssh use at the same
# socket path (gpgconf --list-dirs agent-ssh-socket, exported above/in
# .bashrc). Modern equivalent of `gpg-connect-agent killagent /bye`.
alias reload='gpgconf --kill gpg-agent'

