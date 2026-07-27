#!/usr/bin/env bash
# Compact startup banner for a freshly created tmux session on the laptop ---
# a shorter cousin of the full system MOTD the Ansible `motd` role installs
# on servers (homelab-ansible repo, roles/motd/templates/motd.sh.j2).
# That one leans on system stats (load, disk, containers, last login); a
# workstation you're sitting at interactively doesn't need any of that, so
# this one drops straight to the thing actually worth a reminder: tmux
# muscle memory and handy aliases grouped by category. Falls back to plain
# text if figlet isn't installed, same as the server banner does.
#
# Called from .zshrc as: zsh-banner.sh "<prefix key, e.g. C-y>"

set -u

PREFIX="${1:-C-y}"

# --- Catppuccin Mocha palette ------------------------------------------------
MAUVE='\e[38;2;203;166;247m'
LAVENDER='\e[38;2;180;190;254m'
BLUE='\e[38;2;137;180;250m'
GREEN='\e[38;2;166;227;161m'
SUBTEXT='\e[38;2;166;173;200m'
BOLD='\e[1m'
R='\e[0m'

# --- Hostname figlet ----------------------------------------------------------
HOST_SHORT=$(hostname -s)
BANNER=$(figlet -f small "$HOST_SHORT" 2>/dev/null || echo "  $HOST_SHORT")

echo ""
echo -e "${LAVENDER}${BANNER}${R}"

# --- Helpers ------------------------------------------------------------------

# Section header with box-drawing, Nerd Font icon, and optional right-side info.
#   section_header <icon> <label> [right_text]
section_header() {
  local icon="$1" label="$2" right="${3:-}"
  local bar="───────────────────────────────────────"
  if [ -n "$right" ]; then
    echo -e "${MAUVE}─── ${icon} ${label} ${bar}${R} ${SUBTEXT}${right}${R}"
  else
    echo -e "${MAUVE}─── ${icon} ${label} ${bar}─────────${R}"
  fi
}

# Key-description row.  Keys in Green, description in Subtext.
#   kv <keys> <description>
kv() {
  local keys="$1" desc="$2"
  echo -e "  ${GREEN}$(printf '%-17s' "$keys")${R} ${SUBTEXT}${desc}${R}"
}

# Group sub-label (e.g. "navigation", "sync").
#   group_label <text>
group_label() {
  echo -e "  ${BLUE}${1}${R}"
}

# --- tmux section -------------------------------------------------------------
echo ""
section_header "󰓫" "tmux" "prefix: ${PREFIX}"
kv '% · "' 'split vertical · horizontal'
kv '← → ↑ ↓' 'switch pane'
kv 'c' 'new window'
kv 'n · p' 'next · prev window'
kv '[' 'copy mode (vi keys, y yanks via OSC52)'
kv 'd' 'detach'

# --- Aliases section ----------------------------------------------------------
echo ""
section_header "󰘳" "Aliases"
group_label "navigation"
kv 'dots · ha · hc' 'cd dotfiles · ansible · catalog'
kv 'ssh2' 'ssh via kitty kitten'
echo ""
group_label "sync"
kv 'sync-dotfiles' 'chezmoi update --force'
kv 'update-omz' 'refresh oh-my-zsh + plugins'
echo ""
group_label "general"
kv 'banner' 'show this banner again'
kv 'clh' 'clear shell history'
kv 'tidy' 'remove stale home files'
kv 'reload' 'restart gpg-agent'
echo ""
