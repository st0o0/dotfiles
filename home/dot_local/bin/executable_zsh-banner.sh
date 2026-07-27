#!/usr/bin/env bash
# Compact startup banner for a freshly created tmux session on the laptop ---
# a shorter cousin of the full system MOTD the Ansible `motd` role installs
# on servers (homelab-ansible repo, roles/motd/templates/motd.sh.j2).
#
# Called from .zshrc as: zsh-banner.sh "<prefix key, e.g. C-y>"

set -u

PREFIX="${1:-C-y}"

# --- Catppuccin Mocha palette ------------------------------------------------
MAUVE='\e[38;2;203;166;247m'
LAVENDER='\e[38;2;180;190;254m'
GREEN='\e[38;2;166;227;161m'
SUBTEXT='\e[38;2;166;173;200m'
OVERLAY='\e[38;2;108;112;134m'
R='\e[0m'
BOLD='\e[1m'

HOST_SHORT=$(hostname -s)
BANNER=$(figlet -f small "$HOST_SHORT" 2>/dev/null || echo "  $HOST_SHORT")

hdr() {
  local label="$1" right="${2:-}"
  local w=55 pre="─── " dashes=""
  if [ -n "$right" ]; then
    local suf=" ${right} ───"
    local n=$(( w - ${#pre} - ${#label} - 1 - ${#suf} ))
    [ "$n" -lt 3 ] && n=3
    printf -v dashes '%*s' "$n" ''; dashes="${dashes// /─}"
    echo -e "${MAUVE}${pre}${label} ${dashes}${OVERLAY}${suf}${R}"
  else
    local n=$(( w - ${#pre} - ${#label} - 1 ))
    [ "$n" -lt 3 ] && n=3
    printf -v dashes '%*s' "$n" ''; dashes="${dashes// /─}"
    echo -e "${MAUVE}${pre}${label} ${dashes}${R}"
  fi
}

echo ""
echo -e "${LAVENDER}${BOLD}${BANNER}${R}"

# tmux
echo ""
hdr "󰓫 tmux" "prefix: ${PREFIX}"
echo -e "  ${GREEN}% · \"${R}  ${SUBTEXT}split${R}   ${GREEN}← → ↑ ↓${R}  ${SUBTEXT}pane${R}   ${GREEN}c${R}  ${SUBTEXT}window${R}   ${GREEN}n · p${R}  ${SUBTEXT}next/prev${R}"
echo -e "  ${GREEN}[${R}  ${SUBTEXT}copy mode (vi, y yanks)${R}   ${GREEN}d${R}  ${SUBTEXT}detach${R}"

# Aliases
echo ""
hdr "󰘳 Aliases"
echo -e "  ${GREEN}dots${R}${OVERLAY}·${R}${GREEN}ha${R}${OVERLAY}·${R}${GREEN}hc${R}  ${OVERLAY}cd repos${R}   ${GREEN}ssh2${R}  ${OVERLAY}kitty ssh${R}   ${GREEN}sync-dotfiles${R}${OVERLAY}·${R}${GREEN}update-omz${R}  ${OVERLAY}sync${R}"
echo -e "  ${GREEN}banner${R}${OVERLAY}·${R}${GREEN}clh${R}${OVERLAY}·${R}${GREEN}tidy${R}${OVERLAY}·${R}${GREEN}reload${R}  ${OVERLAY}system maintenance${R}"
echo ""
