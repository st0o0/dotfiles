#!/usr/bin/env bash
# Compact startup banner for a freshly created tmux session on the laptop —
# a shorter cousin of the full system MOTD the Ansible `motd` role installs
# on servers (homelab-ansible repo, roles/motd/templates/motd.sh.j2).
# That one leans on system stats (load, disk, containers, last login); a
# workstation you're sitting at interactively doesn't need any of that, so
# this one drops straight to the thing actually worth a reminder: tmux
# muscle memory. Falls back to plain text if figlet isn't installed, same
# as the server banner does.
#
# Called from .zshrc as: zsh-banner.sh "<prefix key, e.g. C-b>"

set -u

PREFIX="${1:-C-b}"

MAUVE='\e[38;2;203;166;247m'
BLUE='\e[38;2;137;180;250m'
GREEN='\e[38;2;166;227;161m'
SUBTEXT='\e[38;2;166;173;200m'
BOLD='\e[1m'
R='\e[0m'

HOST_SHORT=$(hostname -s)
BANNER=$(figlet -f small "$HOST_SHORT" 2>/dev/null || echo " $HOST_SHORT")

echo ""
echo -e "${MAUVE}${BANNER}${R}"
echo ""
echo -e " ${BLUE}${BOLD}tmux${R} ${SUBTEXT}(prefix: ${PREFIX})${R}"
echo -e "   ${GREEN}%${R} / ${GREEN}\"${R}     split pane vertical / horizontal"
echo -e "   ${GREEN}arrows${R}      switch pane"
echo -e "   ${GREEN}c${R}           new window     ${GREEN}n${R}/${GREEN}p${R}  next / prev window"
echo -e "   ${GREEN}[${R}           copy mode ${SUBTEXT}(vi keys, y/Enter yanks via OSC52)${R}"
echo -e "   ${GREEN}d${R}           detach"
echo ""
echo -e " ${BLUE}${BOLD}aliases${R}"
echo -e "   ${GREEN}clh${R}           clear shell history"
echo -e "   ${GREEN}update-omz${R}    refresh oh-my-zsh + plugins"
echo -e "   ${GREEN}sync-dotfiles${R} chezmoi update --force"
echo -e "   ${GREEN}dots${R} / ${GREEN}ha${R}     cd to dotfiles / homelab-ansible"
echo -e "   ${GREEN}ssh2${R}          ssh via kitty kitten"
echo ""
