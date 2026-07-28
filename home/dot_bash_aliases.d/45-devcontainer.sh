# Devcontainer profile only — show only SSH config host aliases, not known_hosts IPs

if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.ssh/config" ]; then
    eval '
    zstyle ":completion:*:(ssh|scp|sftp|rsync):*" known-hosts-files ""
    zstyle ":completion:*:(ssh|scp|sftp|rsync):*" hosts ${(f)"$(
        command grep -i "^Host " "$HOME/.ssh/config" 2>/dev/null \
            | awk "{for(i=2;i<=NF;i++) if(\$i !~ /[*?]/) print \$i}"
    )"}
    '
fi
