#!/usr/bin/env bash
# Called by install.ps1 inside MSYS2 — installs the shell toolchain.
# Not meant to be run directly.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

log() { printf '==> %s\n' "$1"; }

# chezmoi
if command -v chezmoi >/dev/null 2>&1; then
    log "chezmoi: already installed"
else
    log "Installing chezmoi..."
    mkdir -p "$HOME/.local/bin"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# starship
if command -v starship >/dev/null 2>&1; then
    log "starship: already installed"
else
    log "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
fi

# fzf
if command -v fzf >/dev/null 2>&1; then
    log "fzf: already installed"
else
    log "Installing fzf..."
    FZF_VERSION=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
        | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-windows_amd64.zip" -o /tmp/fzf.zip
    unzip -o /tmp/fzf.zip -d /usr/local/bin
    rm /tmp/fzf.zip
    log "fzf ${FZF_VERSION} installed"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    log "zoxide: already installed"
else
    log "Installing zoxide..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# MSYS2 by default uses the Windows home (C:\Users\...) as $HOME.
# Override to /home/<user> so dotfiles, starship, and tmux configs
# are found at their expected POSIX paths.
NSSWITCH="/etc/nsswitch.conf"
if ! grep -q "db_home: /home" "$NSSWITCH" 2>/dev/null; then
    log "Setting MSYS2 home to /home/<user>..."
    if grep -q "db_home:" "$NSSWITCH" 2>/dev/null; then
        sed -i 's|^db_home:.*|db_home: /home/%U|' "$NSSWITCH"
    else
        echo "db_home: /home/%U" >> "$NSSWITCH"
    fi
fi

# default shell — MSYS2 uses /etc/passwd only if it exists
if [ -f /etc/passwd ]; then
    CURRENT_SHELL=$(grep "^$(whoami):" /etc/passwd | cut -d: -f7)
    if [ "$CURRENT_SHELL" != "/usr/bin/zsh" ]; then
        log "Setting zsh as default shell..."
        sed -i "s|^$(whoami):\(.*\):[^:]*$|$(whoami):\1:/usr/bin/zsh|" /etc/passwd
    else
        log "zsh: already default shell"
    fi
else
    log "Generating /etc/passwd with zsh as default shell..."
    mkpasswd -c | sed "s|/usr/bin/bash|/usr/bin/zsh|" > /etc/passwd
fi

# chezmoi apply
CHEZMOI_USER="${1:-st0o0}"
log "Applying dotfiles (workstation profile)..."
chezmoi init --apply --no-tty --promptString profile=workstation "$CHEZMOI_USER"

log "Shell toolchain setup complete."
