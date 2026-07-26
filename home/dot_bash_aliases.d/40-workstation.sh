# Workstation profile only — laptop-side conveniences

# SSH via Kitty's ssh kitten — auto-installs xterm-kitty terminfo on the
# remote host, avoids terminfo mismatches without hardcoding TERM locally
alias ssh2='kitty +kitten ssh'

# Repo shortcuts
alias ha='cd ~/GIT/homelab-ansible'
alias hc='cd ~/GIT/homelab-catalog'
alias dots='cd ~/GIT/dotfiles'

# Pull latest dotfiles repo state and re-apply via chezmoi
alias sync-dotfiles='chezmoi update --force'

# oh-my-zsh + its plugins are cloned as chezmoi externals with
# DISABLE_AUTO_UPDATE set (see dot_zshrc.tmpl) — this forces a git pull on
# them past the usual refreshPeriod cache, without touching the rest of
# the dotfiles.
alias update-omz='chezmoi apply --refresh-externals=always'
