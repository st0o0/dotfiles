<#
.SYNOPSIS
  Bootstrap a Windows machine with this dotfiles repo.
.DESCRIPTION
  Installs chezmoi, psmux, Starship, zoxide, fzf, Nerd Font, and applies dotfiles.
  Supports versioned installation for up/downgrade.
.EXAMPLE
  .\install.ps1
  .\install.ps1 -Version v1.2.0
  .\install.ps1 -Status
  irm https://raw.githubusercontent.com/st0o0/dotfiles/main/install.ps1 | iex
#>
#Requires -Version 7
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$Status
)

$ErrorActionPreference = "Stop"
$GITHUB_USER = "st0o0"
$GITHUB_REPO = "dotfiles"
$VERSION_FILE = Join-Path $env:USERPROFILE ".dotfiles-version"

function Log { param([string]$Message) Write-Host "==> $Message" }

function Get-LatestRelease {
    $uri = "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri $uri -Headers @{ Accept = "application/vnd.github.v3+json" }
        return $release.tag_name
    } catch {
        Write-Warning "Could not fetch latest release, using 'main'"
        return "main"
    }
}

function Get-InstalledVersion {
    if (Test-Path $VERSION_FILE) { return (Get-Content $VERSION_FILE -Raw).Trim() }
    return $null
}

function Save-InstalledVersion { param([string]$Ver) Set-Content -Path $VERSION_FILE -Value $Ver }

# ── Status ──────────────────────────────────────────────────────────
if ($Status) {
    $installed = Get-InstalledVersion
    $latest = Get-LatestRelease
    Log "Installed: $($installed ?? 'not installed')"
    Log "Latest:    $latest"
    exit 0
}

# ── Resolve version ────────────────────────────────────────────────
$installed = Get-InstalledVersion
if (-not $Version -or $Version -eq "latest") {
    $targetVersion = Get-LatestRelease
} else {
    $targetVersion = $Version
}

if ($installed) {
    if ($installed -eq $targetVersion) {
        Log "Already at $targetVersion"
    } else {
        Log "Updating: $installed -> $targetVersion"
    }
} else {
    Log "Installing version: $targetVersion"
}

# ── Install tools via winget ────────────────────────────────────────
$tools = @(
    @{ Name = "chezmoi";  Id = "twpayne.chezmoi" },
    @{ Name = "psmux";    Id = "marlocarlo.psmux" },
    @{ Name = "Starship"; Id = "Starship.Starship" },
    @{ Name = "zoxide";   Id = "ajeetdsouza.zoxide" },
    @{ Name = "fzf";      Id = "junegunn.fzf" }
)

foreach ($tool in $tools) {
    $existing = winget list --id $tool.Id --accept-source-agreements 2>&1
    if ($existing -match $tool.Id) {
        Log "$($tool.Name): already installed"
    } else {
        Log "Installing $($tool.Name)..."
        winget install -e --id $tool.Id --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { Write-Error "Failed to install $($tool.Name) (winget exit code $LASTEXITCODE)" }
    }
}

# Refresh PATH after installs
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ── Nerd Font ───────────────────────────────────────────────────────
Log "Checking Nerd Font..."
$fontFound = $false
foreach ($h in @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts")) {
    try {
        if ((Get-ItemProperty $h -ErrorAction Stop | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match "JetBrainsMono.*Nerd" })) { $fontFound = $true; break }
    } catch {}
}
if ($fontFound) {
    Log "Nerd Font: already installed"
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Log "Installing JetBrainsMono Nerd Font..."
    winget install -e --id DEVCOM.JetBrainsMonoNerdFont --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to install JetBrainsMono Nerd Font (winget exit code $LASTEXITCODE)" }
} else {
    Log "Install manually: winget install -e --id DEVCOM.JetBrainsMonoNerdFont"
}

# ── PSFzf module ───────────────────────────────────────────────────
if (-not (Get-Module -ListAvailable -Name PSFzf)) {
    Log "Installing PSFzf module..."
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module -Name PSFzf -Scope CurrentUser -Force
} else {
    Log "PSFzf: already installed"
}

# ── chezmoi init + apply ───────────────────────────────────────────
$branch = $targetVersion
Log "Applying dotfiles ($branch)..."
chezmoi init --apply --no-tty --promptString "profile=workstation" --branch $branch $GITHUB_USER
if ($LASTEXITCODE -ne 0) { Write-Error "chezmoi init --apply failed (exit code $LASTEXITCODE)" }

Save-InstalledVersion $targetVersion

# ── Windows Terminal profile ────────────────────────────────────────
$wtFile = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtFile) {
    Log "Configuring Windows Terminal..."
    Copy-Item $wtFile "$wtFile.bak" -Force
    $wt = Get-Content $wtFile -Raw | ConvertFrom-Json
    $pName = "Dotfiles (pwsh)"
    if (-not ($wt.profiles.list | Where-Object { $_.name -eq $pName })) {
        $shellScript = Join-Path $env:USERPROFILE ".local\bin\dotfiles-shell.ps1"
        $wt.profiles.list += [PSCustomObject]@{
            name              = $pName
            commandline       = "pwsh -NoProfile -NoExit -Command `"`$env:DOTFILES_SHELL='1'; . '$shellScript'; psmux new-session -A -s main`""
            startingDirectory = "%USERPROFILE%"
            font              = [PSCustomObject]@{ face = "JetBrainsMono NFM" }
            environment       = [PSCustomObject]@{ DOTFILES_SHELL = "1" }
        }
        $wt | ConvertTo-Json -Depth 10 | Set-Content $wtFile -Encoding UTF8
        Log "Added '$pName' profile to Windows Terminal"
    } else {
        Log "Windows Terminal profile already exists"
    }
}

# ── $PROFILE hook ──────────────────────────────────────────────────
$profilePath = $PROFILE.CurrentUserCurrentHost
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    if ($content -notmatch 'DOTFILES_SHELL') {
        Log "Adding dotfiles hook to `$PROFILE..."
        Add-Content -Path $profilePath -Value @'

# Dotfiles shell — only loads when DOTFILES_SHELL env var is set (via WT profile)
if ($env:DOTFILES_SHELL -and (Test-Path "$HOME\.local\bin\dotfiles-shell.ps1")) {
    . "$HOME\.local\bin\dotfiles-shell.ps1"
}
'@
    } else {
        Log "Dotfiles hook already in `$PROFILE"
    }
} else {
    Log "Creating `$PROFILE with dotfiles hook..."
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Set-Content -Path $profilePath -Value @'
# Dotfiles shell — only loads when DOTFILES_SHELL env var is set (via WT profile)
if ($env:DOTFILES_SHELL -and (Test-Path "$HOME\.local\bin\dotfiles-shell.ps1")) {
    . "$HOME\.local\bin\dotfiles-shell.ps1"
}
'@
}

# ── Summary ─────────────────────────────────────────────────────────
Log "Done! Version $targetVersion installed."
Log "Open 'Dotfiles (pwsh)' in Windows Terminal."
