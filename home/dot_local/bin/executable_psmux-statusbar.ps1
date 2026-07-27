# Renders the right side of the psmux status bar (Catppuccin Mocha colors,
# Powerline capsule style). Called from psmux.conf as:
#   status-right "#(pwsh -NoProfile -File ~/.local/bin/psmux-statusbar.ps1 '#{pane_current_path}' '#{client_width}' '#{session_name}' '#{W:#I:#{window_name} }' '#{?client_prefix,#f38ba8,#b4befe}')"
#
# Interlocking chain of Powerline capsules. Every segment has a fixed static
# fill colour and dark (BASE) text (git = green, dir = peach, date = blue,
# time = lavender). Git's working-tree status is folded into the green git
# capsule as compact symbols (+ staged, ! modified, ? untracked).
#
# Optional segments (everything except dir/time) are dropped lowest-priority
# first when the terminal is too narrow.

$PANE_PATH    = if ($args[0]) { $args[0] } else { $HOME }
$CLIENT_WIDTH = if ($args[1]) { [int]$args[1] } else { 200 }
$SESSION_NAME = if ($args[2]) { $args[2] } else { '' }
$WINDOW_LIST  = if ($args[3]) { $args[3] } else { '' }
$PREFIX_COLOR = if ($args[4]) { $args[4] } else { '' }

# ── Palette (Catppuccin Mocha) ──
$BASE     = '#1e1e2e'
$GREEN    = '#a6e3a1'
$PEACH    = '#fab387'
$BLUE     = '#89b4fa'
$LAVENDER = '#b4befe'

# ── Powerline caps ──
$CAP_JOIN  = [char]0xe0b2   #
$CAP_OPEN  = [char]0xe0b6   #
$CAP_CLOSE = [char]0xe0b4   #

# ── Nerd Font icons ──
$ICON_GIT   = [char]0xe0a0  #
$ICON_DIR   = [char]0xf07b  #
$ICON_CAL   = [char]0xf073  #
$ICON_CLOCK = [char]0xf017  #

# ── Segment collection ──
# Each entry: [seq, priority, fill, textcolor, text]
$all_segments = [System.Collections.Generic.List[object[]]]::new()
$seq = 0

# ── Git branch ──
try {
    $branch = & git -C $PANE_PATH rev-parse --abbrev-ref HEAD --no-optional-locks 2>$null
    if ($branch) {
        $porc = & git -C $PANE_PATH --no-optional-locks status --porcelain 2>$null
        $sym = ''
        if ($porc) {
            $lines = if ($porc -is [string]) { @($porc) } else { $porc }
            foreach ($l in $lines) {
                if ($l -match '^[MADRC]') { if ($sym -notmatch '\+') { $sym += '+' } }
                if ($l -match '^.[MD]')   { if ($sym -notmatch '!')  { $sym += '!' } }
                if ($l -match '^\?\?')    { if ($sym -notmatch '\?') { $sym += '?' } }
            }
        }
        $git_text = "$ICON_GIT $branch"
        if ($sym) { $git_text += " $sym" }
        $all_segments.Add(@($seq, 90, $GREEN, '', $git_text))
        $seq++
    }
} catch {}

# ── Current directory (mandatory) ──
$dir = Split-Path $PANE_PATH -Leaf
$all_segments.Add(@($seq, 999, $PEACH, '', "$ICON_DIR $dir"))
$seq++

# ── Date ──
$dateStr = (Get-Date).ToString('dd.MM.')
$all_segments.Add(@($seq, 30, $BLUE, '', "$ICON_CAL $dateStr"))
$seq++

# ── Time (mandatory, always last) ──
$timeStr = (Get-Date).ToString('HH:mm')
$all_segments.Add(@($seq, 999, $LAVENDER, '', "$ICON_CLOCK $timeStr"))
$seq++

# ── Width budget — drop optional segments lowest priority first ──
$reserved = 2 + $SESSION_NAME.Length
$tokens = $WINDOW_LIST -split '\s+'
foreach ($t in $tokens) {
    if ($t) { $reserved += $t.Length + 2 }
}
$budget = $CLIENT_WIDTH - $reserved - 2

function Get-SegWidth([string]$text) {
    return $text.Length + 4
}

$total = 0
foreach ($e in $all_segments) {
    $total += Get-SegWidth $e[4]
}

# Sort droppable segments by priority ascending
$droppable = $all_segments | Where-Object { $_[1] -lt 999 } | Sort-Object { $_[1] }

$dropped = [System.Collections.Generic.HashSet[int]]::new()
foreach ($e in $droppable) {
    if ($total -le $budget) { break }
    $total -= Get-SegWidth $e[4]
    [void]$dropped.Add($e[0])
}

$final = $all_segments | Where-Object { -not $dropped.Contains($_[0]) }

# ── Render right-anchored leftward interlocking chain ──
$finalArr = @($final)
$out = [System.Text.StringBuilder]::new(256)
$prev_color = ''
$last_index = $finalArr.Count - 1

for ($i = 0; $i -lt $finalArr.Count; $i++) {
    $e = $finalArr[$i]
    $fill = $e[2]
    $textcolor = $e[3]
    $text = $e[4]
    $tc = if ($textcolor) { $textcolor } else { $BASE }

    if ($i -eq 0) {
        if ($PREFIX_COLOR) {
            [void]$out.Append("#[fg=${fill},bg=${PREFIX_COLOR}]${CAP_JOIN}")
        } else {
            [void]$out.Append("#[fg=${fill},bg=default]${CAP_OPEN}")
        }
    } else {
        [void]$out.Append("#[fg=${fill},bg=${prev_color}]${CAP_JOIN}")
    }

    [void]$out.Append("#[fg=${tc},bg=${fill},bold] ${text} #[nobold]")

    if ($i -eq $last_index) {
        [void]$out.Append("#[fg=${fill},bg=default]${CAP_CLOSE}#[default]")
    }
    $prev_color = $fill
}

Write-Host -NoNewline $out.ToString()
