# Devcontainer profile only — SSH-config-based host completion for ssh and just

if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.ssh/config" ]; then
    eval '
    _ssh_config_hosts() {
        local -a hosts
        hosts=(${(f)"$(command grep -i "^Host " "$HOME/.ssh/config" 2>/dev/null \
            | awk "{for(i=2;i<=NF;i++) if(\$i !~ /[*?]/) print \$i}")"})
        echo "${hosts[@]}"
    }

    zstyle ":completion:*:(ssh|scp|sftp|rsync):*" hosts ${(f)"$(
        command grep -i "^Host " "$HOME/.ssh/config" 2>/dev/null \
            | awk "{for(i=2;i<=NF;i++) if(\$i !~ /[*?]/) print \$i}"
    )"}

    _just_with_hosts() {
        if (( CURRENT >= 3 )); then
            local -a hosts
            hosts=(${(f)"$(_ssh_config_hosts)"})
            if (( ${#hosts} )); then
                _describe "host" hosts
            fi
        fi
        _just "$@"
    }
    compdef _just_with_hosts just
    '
fi
