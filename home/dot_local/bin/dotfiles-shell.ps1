# Dotfiles shell — launched by the "Dotfiles (pwsh)" Windows Terminal profile.
# Does NOT touch $PROFILE. Loads Starship, zoxide, fzf, PSReadLine tuning,
# then attaches to psmux.

# ── PSReadLine ──────────────────────────────────────────────────────
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord

# ── PSFzf (fzf integration) ────────────────────────────────────────
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ── Starship prompt ────────────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ── zoxide (fuzzy cd) ──────────────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell)
}

# ── psmux auto-attach ───────────────────────────────────────────────
if (-not $env:TMUX -and -not $env:PSMUX -and (Get-Command psmux -ErrorAction SilentlyContinue)) {
    psmux new-session -A -s main
}
