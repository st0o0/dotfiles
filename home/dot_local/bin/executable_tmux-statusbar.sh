#!/usr/bin/env bash
# Renders the right side of the tmux status bar (Catppuccin Mocha colors,
# Powerline capsule style). Called from tmux.conf as:
#   status-right "#(tmux-statusbar.sh '#{pane_current_path}' '#{client_width}' \
#     '#{session_name}' '#{W:#I:#{window_name} }' 'workstation|server' 'PREFIXCOLOR')"
#
# Interlocking chain of Powerline capsules. Every segment has a fixed static
# fill colour and dark (BASE) text (git = green, dir = peach,
# load = mauve, uptime = yellow, net = red/yellow, battery = pink,
# date = blue, time = lavender) — the fill names *what* the segment is.
# Network segments only appear when degraded. Git's working-tree status is folded into the
# green git capsule as compact symbols (+ staged, ! modified, ? untracked,
# ⇡/⇣ ahead/behind) in the same dark text colour as the branch. No segment
# breaks the chain, so every capsule seams cleanly into its neighbour; adjacent
# fills are all distinct, so every seam stays visible.
#
# Segments that don't apply on the current host are skipped automatically
# (no battery on a headless server, no git branch outside a repo). A few are
# gated on $PROFILE (baked in statically by tmux.conf.tmpl at chezmoi-render
# time): uptime is server-only, date is workstation-only.
#
# Optional segments (everything except dir/time) are dropped lowest-priority
# first when the terminal is too narrow — see the budget logic below.

set -u

PANE_PATH="${1:-$HOME}"
CLIENT_WIDTH="${2:-200}"
SESSION_NAME="${3:-}"
WINDOW_LIST="${4:-}"
PROFILE="${5:-workstation}"
# Colour of the prefix-indicator pill immediately to this chain's left (drawn
# live in status-right). When set, the chain's first segment seams into it
# instead of getting a rounded opening cap. Empty → standalone rounded cap.
PREFIX_COLOR="${6:-}"

# Palette. BASE is the default dark text colour used by every segment.
BASE="#1e1e2e"
RED="#f38ba8"
PEACH="#fab387"
YELLOW="#f9e2af"
GREEN="#a6e3a1"
TEAL="#94e2d5"
LAVENDER="#b4befe"
BLUE="#89b4fa"
MAUVE="#cba6f7"
PINK="#f5c2e7"

# Powerline caps. CAP_JOIN is the leftward-pointing dual-colour seam between
# two adjacent capsules (this is a right-anchored chain flowing leftward);
# CAP_OPEN/CAP_CLOSE are the rounded outer caps at the chain's two ends.
CAP_JOIN=$(printf '')
CAP_OPEN=$(printf '')
CAP_CLOSE=$(printf '')

ICON_GIT=$(printf '')      # pl-branch
ICON_DIR=$(printf '')      # nf-fa-folder
ICON_LOAD=$(printf '')     # nf-fa-tachometer
ICON_UPTIME=$(printf '')   # nf-fa-history
ICON_CAL=$(printf '')      # nf-fa-calendar
ICON_CLOCK=$(printf '')    # nf-fa-clock
ICON_BAT=$(printf '')      # nf-fa-battery_full

# Each entry is "seq:priority:fill:textcolor:text":
#   priority 999 = never drop (dir, time); lower = droppable, lowest first.
#   fill      = the capsule's static background colour.
#   textcolor = glyph/label colour override (empty → BASE dark). Currently
#               unused by any segment; kept for future per-segment overrides.
# $seq preserves push order so a dropped segment doesn't shift the rest.
all_segments=()
seq=0
push() {
    all_segments+=("${seq}:${1}:${2}:${3}:${4}")
    seq=$(( seq + 1 ))
}

# Git branch (inside a repo). The capsule stays green; working-tree status is
# folded in as compact symbols in the same dark text colour as the branch
# (+ staged, ! modified, ? untracked), matching starship.
branch=$(cd "$PANE_PATH" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ]; then
    porc=$(cd "$PANE_PATH" && git status --porcelain 2>/dev/null)
    sym=""
    printf '%s\n' "$porc" | grep -q '^[MADRC]' && sym="${sym}+"
    printf '%s\n' "$porc" | grep -q '^.[MD]'   && sym="${sym}!"
    printf '%s\n' "$porc" | grep -q '^??'      && sym="${sym}?"
    git_text="${ICON_GIT} ${branch}"
    [ -n "$sym" ] && git_text="${git_text} ${sym}"
    push 90 "$GREEN" "" "$git_text"
fi

# Current directory (basename only). Mandatory.
dir=$(basename "$PANE_PATH")
push 999 "$PEACH" "" "${ICON_DIR} ${dir}"

# Load average (1-minute). Mauve capsule, dark text.
if [ -r /proc/loadavg ]; then
    load1=$(cut -d' ' -f1 /proc/loadavg)
    push 50 "$MAUVE" "" "${ICON_LOAD} ${load1}"
fi

# Uptime, compact (server-only, lowest priority). Yellow capsule, dark text.
if [ "$PROFILE" = "server" ] && [ -r /proc/uptime ]; then
    up_secs=$(cut -d' ' -f1 /proc/uptime)
    uptime_str=$(awk -v s="$up_secs" 'BEGIN {
        s = int(s);
        d = int(s / 86400);
        h = int((s % 86400) / 3600);
        m = int((s % 3600) / 60);
        if (d > 0) printf "%dd %dh", d, h;
        else if (h > 0) printf "%dh %dm", h, m;
        else printf "%dm", m;
    }')
    push 20 "$YELLOW" "" "${ICON_UPTIME} ${uptime_str}"
fi

# Network: offline warning (instant route-table check) or packet loss
# (async: reads previous ping result, kicks off a new one in background).
# Invisible when connectivity is fine.
PING_CACHE="/tmp/.tmux-ping"
if command -v ip >/dev/null 2>&1 && ! ip route show default 2>/dev/null | grep -q .; then
    push 80 "$RED" "" "⚠ offline"
else
    if [ -f "$PING_CACHE" ] && [ "$(cat "$PING_CACHE" 2>/dev/null)" = "loss" ]; then
        push 75 "$YELLOW" "" "⚠ loss"
    fi
    if command -v ping >/dev/null 2>&1; then
        (ping -c1 -W2 1.1.1.1 >/dev/null 2>&1 && printf ok || printf loss) > "$PING_CACHE" 2>/dev/null &
    fi
fi

# Battery, if present. Pink capsule, dark text, fixed icon.
bat_path=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1 || true)
if [ -n "$bat_path" ] && [ -f "$bat_path/capacity" ]; then
    bat_pct=$(cat "$bat_path/capacity" 2>/dev/null)
    if [ -n "$bat_pct" ]; then
        push 70 "$PINK" "" "${ICON_BAT} ${bat_pct}%"
    fi
fi

# Date — workstation-only. Blue capsule, dark text.
if [ "$PROFILE" != "server" ]; then
    push 30 "$BLUE" "" "${ICON_CAL} $(date '+%d.%m.')"
fi

# Time (always last — the anchor, mandatory). Lavender capsule, dark text.
push 999 "$LAVENDER" "" "${ICON_CLOCK} $(date '+%H:%M')"

# ── Width budget — drop optional segments, lowest priority first, until ──
# everything fits next to the session pill + window list on the left.
reserved=$(( 2 + ${#SESSION_NAME} ))
for token in $WINDOW_LIST; do
    reserved=$(( reserved + ${#token} + 2 ))
done
budget=$(( CLIENT_WIDTH - reserved - 2 ))

seg_width() {
    # Approx capsule width: label + icon + padding + caps. Fields are
    # textcolor:text; only the visible text counts.
    local text="${1#*:}"
    echo $(( ${#text} + 4 ))
}

total=0
for e in "${all_segments[@]}"; do
    total=$(( total + $(seg_width "${e#*:*:*:}") ))
done

droppable=()
for e in "${all_segments[@]}"; do
    prio="${e#*:}"; prio="${prio%%:*}"
    [ "$prio" -lt 999 ] && droppable+=("$e")
done
IFS=$'\n' sorted=($(printf '%s\n' "${droppable[@]}" | sort -t: -k2,2n))
unset IFS

dropped=" "
for e in "${sorted[@]}"; do
    [ "$total" -le "$budget" ] && break
    total=$(( total - $(seg_width "${e#*:*:*:}") ))
    seq_id="${e%%:*}"
    dropped="${dropped}${seq_id} "
done

final=()
for e in "${all_segments[@]}"; do
    seq_id="${e%%:*}"
    case "$dropped" in
        *" ${seq_id} "*) continue ;;
    esac
    final+=("$e")
done

# Render as a right-anchored leftward interlocking chain: only the first
# capsule gets an opening cap (a seam into the live prefix pill when
# PREFIX_COLOR is set, else a rounded cap) and only the last gets a rounded
# closing cap; every internal boundary is a single shared CAP_JOIN seam. The
# body uses each segment's own text colour (default dark BASE).
out=""
prev_color=""
last_index=$(( ${#final[@]} - 1 ))
for i in "${!final[@]}"; do
    rest="${final[$i]#*:*:}"     # fill:textcolor:text
    fill="${rest%%:*}"
    rest2="${rest#*:}"           # textcolor:text
    textcolor="${rest2%%:*}"
    text="${rest2#*:}"           # keeps internal colons (e.g. "14:03")
    tc="${textcolor:-$BASE}"

    if [ "$i" -eq 0 ]; then
        if [ -n "$PREFIX_COLOR" ]; then
            out+="#[fg=${fill},bg=${PREFIX_COLOR}]${CAP_JOIN}"
        else
            out+="#[fg=${fill},bg=default]${CAP_OPEN}"
        fi
    else
        out+="#[fg=${fill},bg=${prev_color}]${CAP_JOIN}"
    fi

    out+="#[fg=${tc},bg=${fill},bold] ${text} #[nobold]"

    if [ "$i" -eq "$last_index" ]; then
        out+="#[fg=${fill},bg=default]${CAP_CLOSE}#[default]"
    fi
    prev_color="$fill"
done

printf '%s' "$out"
