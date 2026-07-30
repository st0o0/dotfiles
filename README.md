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

### Profiles

Linux/macOS supports three profiles:

- **workstation** (default): Full setup with kitty, Nerd Font, extra aliases, tmux prefix `C-Space`
- **server**: Minimal setup, default tmux prefix `C-b`
- **devcontainer**: tmux prefix `C-y`, status bar, mouse/clipboard support

```bash
./install.sh --profile server
./install.sh --profile devcontainer
```

### What happens

`install.sh` bootstraps system packages (git, curl, zsh, tmux) and
chezmoi, then runs `chezmoi init --apply` which handles everything else:

- **Dotfiles** applied via chezmoi templates (profile-aware)
- **CLI tools** (starship, zoxide, fzf) installed via `run_once_before` scripts to `~/.local/bin`
- **oh-my-zsh + plugins** cloned via `.chezmoiexternal`

Re-running is safe — every step is idempotent.

## Structure

```
.chezmoiroot → home/
home/                   chezmoi source (cross-platform dotfiles)
home/.chezmoiscripts/   run_once scripts for tool installation
install.sh              Linux/macOS bootstrap
install.ps1             Windows bootstrap
```

Platform-specific files are filtered via `.chezmoiignore` using
`{{ .chezmoi.os }}`. Linux configs (zsh, tmux, kitty) are ignored on
Windows; Windows configs (PowerShell profile, psmux) are ignored on Linux.
