# Managed by chezmoi — PowerShell 7 profile for Windows workstation.
# Mirrors the zsh setup: Starship prompt, zoxide, fzf, PSReadLine tuning,
# psmux auto-attach.

# ── psmux auto-attach ───────────────────────────────────────────────
# Attach to a persistent psmux session for interactive shells, mirroring
# the tmux auto-attach in .zshrc. Skip if already inside psmux, or if
# this is a non-interactive session (e.g. VS Code task runner).
if (-not $env:TMUX -and -not $env:PSMUX -and $Host.Name -eq 'ConsoleHost' -and (Get-Command psmux -ErrorAction SilentlyContinue)) {
    psmux new-session -A -s main
    return
}

# ── PSReadLine ──────────────────────────────────────────────────────
Set-PSReadLineOption -EditMode Vi
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
