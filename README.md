# dotfiles

Personal machine setup, managed with [chezmoi](https://www.chezmoi.io).
One command per OS — same shell experience everywhere.

## Getting Started

### Linux / macOS

```bash
curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash
```

### Windows

```powershell
irm https://raw.githubusercontent.com/st0o0/dotfiles/main/install.ps1 | iex
```

Installs [MSYS2](https://www.msys2.org) with the full shell toolchain,
adds a "MSYS2 (zsh)" profile to Windows Terminal, and installs
JetBrainsMono Nerd Font. No VM, no reboot.

### Server (called by Ansible, not by hand)

```bash
curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash -s -- --profile server
```

Both scripts are idempotent — safe to re-run at any time.

## What gets installed

| Tool | Linux | macOS | Windows (MSYS2) | server | Source |
|---|---|---|---|---|---|
| git | yes | yes | yes | yes | apt / brew / pacman |
| zsh | yes | yes | yes | yes | apt / brew / pacman |
| tmux | yes | yes | yes | yes | apt / brew / pacman |
| chezmoi | yes | yes | yes | yes | get.chezmoi.io / brew |
| starship | yes | yes | yes | yes | starship.rs installer |
| zoxide | yes | yes | yes | yes | official installer / pacman |
| fzf | yes | yes | yes | yes | apt / brew / pacman |
| kitty | yes | yes | — | — | official installer / brew |
| Nerd Font | yes | yes | yes | — | GitHub release / brew cask / winget |
| Login shell → zsh | yes | yes | yes | yes | usermod / chsh / /etc/passwd |
| oh-my-zsh + plugins | yes | yes | yes | yes | chezmoi externals |

## Installation hierarchy

`install.sh` is the **single source of truth** for the shell toolchain.
Everything else calls it instead of reimplementing:

| Target | How it gets the shell toolchain |
|---|---|
| Bare workstation | `install.sh` or `install.ps1` |
| DevContainer | [homelab-ansible](https://github.com/st0o0/homelab-ansible)'s `install-dependencies.sh` calls `install.sh --profile workstation` |
| Ansible server | [homelab-ansible](https://github.com/st0o0/homelab-ansible)'s `dotfiles` role calls `install.sh --profile server` |

Tool versions and install logic are maintained in one place.
`.zshrc` falls back gracefully if a tool isn't on `PATH` yet (e.g.
`starship`, `gpgconf`, `zoxide`).

## Profiles

This repo serves two kinds of machines, controlled by a `profile` data
value (`workstation` or `server`) in `~/.config/chezmoi/chezmoi.toml`:

- **workstation**: Kitty config, `ssh2` alias, repo shortcuts, startup banner
- **server**: docker/compose aliases, `/docker` stack shortcuts, Ansible-managed MOTD

Both profiles get oh-my-zsh with plugins (fzf-tab, autosuggestions,
syntax-highlighting), starship prompt, and tmux auto-attach.

Shared across both: `.tmux.conf`, `.zshrc`, `starship.toml`, `.gitconfig`,
`.nanorc`, `.inputrc`, general aliases (`ll`, `..`, `update`).

`.tmux.conf` uses a different prefix per profile — `C-b` on workstation,
`C-n` on server — so nested tmux sessions over SSH don't collide.

## Making changes

```bash
chezmoi edit ~/.bash_aliases.d/10-general.sh   # edit through chezmoi
chezmoi diff                                   # see what would change
chezmoi apply                                  # apply changes to $HOME
chezmoi add ~/.some_config                     # add a new file
```

## Rule: nothing sensitive goes in here

No private keys, no `.netrc`, no tokens — this repo is **public**. See
`.chezmoiignore` for the guardrail patterns. Actual secrets belong in
Bitwarden.
