# dotfiles

Cross-platform dotfiles managed by [chezmoi](https://chezmoi.io/).
Catppuccin Mocha theme, Powerline-style status bar and prompt.

| | Linux/macOS | Windows |
|---|---|---|
| Shell | zsh + oh-my-zsh | PowerShell 7 + PSReadLine |
| Multiplexer | tmux | psmux |
| Prompt | Starship | Starship |
| Fuzzy finder | fzf + fzf-tab | fzf + PSFzf |
| Fuzzy cd | zoxide | zoxide |

## Install

**Linux/macOS:**

```bash
curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/st0o0/dotfiles/main/install.ps1 | iex
```

### Version selection

```bash
# Install specific version
./install.sh --version v1.2.0

# Check installed vs latest
./install.sh --status

# Upgrade to latest
./install.sh --version latest
```

```powershell
# Windows equivalents
.\install.ps1 -Version v1.2.0
.\install.ps1 -Status
.\install.ps1 -Version latest
```

## Structure

```
.chezmoiroot → home/
home/           chezmoi source (cross-platform dotfiles)
install.sh      Linux/macOS bootstrap
install.ps1     Windows bootstrap
```

Platform-specific files are filtered via `.chezmoiignore` using
`{{ .chezmoi.os }}`. Linux configs (zsh, tmux, kitty) are ignored on
Windows; Windows configs (PowerShell profile, psmux) are ignored on Linux.

## Profiles

Linux/macOS supports two profiles:

- **workstation** (default): Full setup with kitty, fzf, Nerd Font
- **server**: Minimal setup, different tmux prefix (C-n)

```bash
./install.sh --profile server
```
