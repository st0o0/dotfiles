<#
.SYNOPSIS
  Bootstrap a Windows machine for this dotfiles repo via MSYS2.
.DESCRIPTION
  One-liner: irm https://raw.githubusercontent.com/st0o0/dotfiles/main/install.ps1 | iex
.EXAMPLE
  .\install.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$CHEZMOI_GITHUB_USER = "st0o0"
$msys2Root = "C:\msys64"
$msys2Bash = "$msys2Root\usr\bin\bash.exe"
$toolsScriptUrl = "https://raw.githubusercontent.com/$CHEZMOI_GITHUB_USER/dotfiles/main/install-msys2-tools.sh"

function Invoke-MSYS2 {
    param([string]$Command)
    & $msys2Bash --login -c $Command
    if ($LASTEXITCODE -ne 0) { Write-Error "MSYS2 command failed: $Command" }
}

# ── 1. Install MSYS2 ────────────────────────────────────────────────

if (Test-Path $msys2Bash) {
    Write-Host "==> MSYS2 already installed"
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "==> Installing MSYS2 via winget..."
    winget install -e --id MSYS2.MSYS2 --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "==> Installing MSYS2 via direct download..."
    $url = "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe"
    $tmp = Join-Path $env:TEMP "msys2-installer.exe"
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    & $tmp -y -oC:\
    Remove-Item $tmp -Force
}

if (-not (Test-Path $msys2Bash)) { Write-Error "MSYS2 not found at $msys2Bash"; exit 1 }

& $msys2Bash --login -c "exit" 2>$null

# ── 2. Update and install base packages ──────────────────────────────

Write-Host "==> Updating MSYS2..."
& $msys2Bash --login -c "pacman -Syu --noconfirm" 2>$null
& $msys2Bash --login -c "pacman -Syu --noconfirm" 2>$null

Write-Host "==> Installing base packages..."
Invoke-MSYS2 "pacman -S --noconfirm --needed curl git zsh tmux unzip"

# ── 3. Run tool installer (chezmoi, starship, fzf, zoxide, dotfiles)─

Write-Host "==> Installing shell toolchain..."
Invoke-MSYS2 "curl -fsSL $toolsScriptUrl | bash -s -- $CHEZMOI_GITHUB_USER"

# ── 4. Nerd Font ─────────────────────────────────────────────────────

Write-Host "==> Checking Nerd Font..."
$fontFound = $false
foreach ($h in @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts")) {
    try {
        if ((Get-ItemProperty $h -ErrorAction Stop | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match "JetBrainsMono.*Nerd" })) { $fontFound = $true; break }
    } catch {}
}
if ($fontFound) {
    Write-Host "    already installed"
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install -e --id DEVCOM.JetBrainsMonoNerdFont --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "    Install manually: winget install -e --id DEVCOM.JetBrainsMonoNerdFont"
}

# ── 5. Windows Terminal profile ──────────────────────────────────────

$iconPath = "$msys2Root\dotfiles-terminal.svg"
if (-not (Test-Path $iconPath)) {
    Write-Host "==> Downloading terminal icon..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$CHEZMOI_GITHUB_USER/dotfiles/main/terminal-icon.svg" -OutFile $iconPath -UseBasicParsing
}

$wtFile = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtFile) {
    Write-Host "==> Configuring Windows Terminal..."
    Copy-Item $wtFile "$wtFile.bak" -Force
    $wt = Get-Content $wtFile -Raw | ConvertFrom-Json
    $pName = "MSYS2 (zsh)"
    if (-not ($wt.profiles.list | Where-Object { $_.name -eq $pName })) {
        $wt.profiles.list += [PSCustomObject]@{
            name              = $pName
            commandline       = "C:/msys64/msys2_shell.cmd -defterm -here -no-start -msys -shell zsh"
            icon              = $iconPath
            startingDirectory = "%USERPROFILE%"
            font              = [PSCustomObject]@{ face = "JetBrainsMono Nerd Font Mono" }
        }
        $wt | ConvertTo-Json -Depth 10 | Set-Content $wtFile -Encoding UTF8
        Write-Host "    Added profile"
    } else {
        Write-Host "    Profile already exists"
    }
} else {
    Write-Host "==> Windows Terminal not found"
    Write-Host "    Run: $msys2Root\msys2_shell.cmd -defterm -here -no-start -msys -shell zsh"
}

# ── 6. Clone repos ──────────────────────────────────────────────────

$repos = @("dotfiles", "homelab-ansible", "homelab-catalog")
$gitDir = Join-Path $env:USERPROFILE "GIT"
Write-Host "`n==> Clone repos into ${gitDir}?"
for ($i = 0; $i -lt $repos.Count; $i++) { Write-Host "    [$($i+1)] $($repos[$i])" }
Write-Host "    [a] all"
$pick = Read-Host "Choice (e.g. 1 3, a, or Enter to skip)"

if ($pick) {
    if (-not (Test-Path $gitDir)) { New-Item -ItemType Directory $gitDir -Force | Out-Null }
    $sel = if ($pick -eq "a") { $repos } else { $pick -split '\s+' | ForEach-Object { $repos[[int]$_ - 1] } }
    foreach ($r in $sel) {
        $d = Join-Path $gitDir $r
        $m = ($d -replace '\\','/') -replace '^(\w):','/$1'
        if (Test-Path $d) { Write-Host "==> ${r}: already exists" } else {
            Write-Host "==> Cloning $r..."
            Invoke-MSYS2 "git clone https://github.com/$CHEZMOI_GITHUB_USER/$r.git $m"
            Invoke-MSYS2 "git -C $m remote set-url origin git@github.com:$CHEZMOI_GITHUB_USER/$r.git"
        }
    }
}

Write-Host "`n==> Done! Open 'MSYS2 (zsh)' in Windows Terminal."
