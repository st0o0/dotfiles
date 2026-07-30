# General shell comfort — applies on every profile (workstation + server)

alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias x='exit'

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

# Migrate legacy apt keys from trusted.gpg to individual files in trusted.gpg.d
apt-fix-keys() {
    if [ ! -f /etc/apt/trusted.gpg ]; then
        echo "no legacy keyring found"
        return
    fi
    local count=0
    while IFS= read -r keyid; do
        [ -z "$keyid" ] && continue
        local name
        name=$(sudo apt-key export "$keyid" 2>/dev/null \
            | gpg --no-default-keyring --import-options show-only --import 2>/dev/null \
            | sed -n 's/.*uid.*<\(.*\)>.*/\1/p' | head -1 \
            | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g;s/^-//;s/-$//')
        [ -z "$name" ] && name="key-${keyid}"
        sudo apt-key export "$keyid" 2>/dev/null \
            | sudo gpg --dearmor -o "/etc/apt/trusted.gpg.d/${name}.gpg" 2>/dev/null \
            && printf 'migrated %s → %s.gpg\n' "$keyid" "$name" && ((count++))
    done < <(apt-key list 2>/dev/null | grep -oP '^\s+\K[A-F0-9]{40}' || \
             apt-key list 2>/dev/null | grep -oE '[A-F0-9]{8,}' | tail -n+1)
    echo "${count} key(s) migrated. Run 'sudo rm /etc/apt/trusted.gpg' to remove the legacy keyring."
}

# Fix dpkg interrupted state
alias apt-fix-dpkg='sudo dpkg --configure -a'

# Force-fix broken dependencies
alias apt-fix-deps='sudo apt install --fix-broken -y'

# Full repair sequence: fix dpkg, fix deps, clean, update
apt-repair() {
    echo "==> fixing dpkg..."
    sudo dpkg --configure -a
    echo "==> fixing broken deps..."
    sudo apt install --fix-broken -y
    echo "==> cleaning cache..."
    sudo apt autoclean
    sudo apt autoremove -y
    echo "==> updating..."
    sudo apt update
    echo "done."
}

# Kill gpg-agent; it auto-respawns on the next gpg/ssh use at the same
# socket path (gpgconf --list-dirs agent-ssh-socket, exported above/in
# .bashrc). Modern equivalent of `gpg-connect-agent killagent /bye`.
alias reload='gpgconf --kill gpg-agent'

banner() {
    if [ -x /usr/local/sbin/homelab-motd ]; then
        /usr/local/sbin/homelab-motd
    elif command -v zsh-banner.sh >/dev/null 2>&1; then
        zsh-banner.sh "${TMUX_PREFIX:-C-Space}"
    else
        echo "no banner script found"
    fi
}

