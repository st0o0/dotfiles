#!/usr/bin/env bash
# Bootstrap a fresh Linux or macOS machine for this dotfiles repo.
# Installs the full shell toolchain, applies dotfiles via chezmoi,
# and optionally clones related repos.
#
# Safe to re-run: every step is skipped if already present.
#
# Usage:
#   ./install.sh                          # workstation (default)
#   ./install.sh --profile server         # server (no kitty/fzf/font)
#   curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash
#   curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash -s -- --profile server

set -euo pipefail

GITHUB_USER="st0o0"
CHEZMOI_GITHUB_USER="${GITHUB_USER}"
GITHUB_REPO="dotfiles"
PROFILE="workstation"
NERD_FONT="JetBrainsMono"
VERSION=""
SHOW_STATUS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --status) SHOW_STATUS=true; shift ;;
    *) echo "error: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

case "${PROFILE}" in
  workstation|server) ;;
  *) echo "error: profile must be 'workstation' or 'server', got '${PROFILE}'" >&2; exit 1 ;;
esac

# ── Helpers ─────────────────────────────────────────────────────────

log() { printf '==> %s\n' "$1"; }
warn() { printf '==> WARNING: %s\n' "$1" >&2; }

maybe_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

mkdir -p "${HOME}/.local/bin"
export PATH="${HOME}/.local/bin:${PATH}"

# ── Version resolution ──────────────────────────────────────────────

VERSION_FILE="${HOME}/.dotfiles-version"

get_latest_release() {
  curl -sSL "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest" 2>/dev/null \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'
}

get_installed_version() {
  if [[ -f "${VERSION_FILE}" ]]; then cat "${VERSION_FILE}"; else echo ""; fi
}

save_installed_version() { echo "$1" > "${VERSION_FILE}"; }

if [[ "${SHOW_STATUS}" == true ]]; then
  installed=$(get_installed_version)
  latest=$(get_latest_release)
  log "Installed: ${installed:-not installed}"
  log "Latest:    ${latest}"
  exit 0
fi

installed=$(get_installed_version)
if [[ -z "${VERSION}" ]] || [[ "${VERSION}" == "latest" ]]; then
  TARGET_VERSION=$(get_latest_release)
  if [[ -z "${TARGET_VERSION}" ]]; then
    log "Could not fetch latest release, using 'main'"
    TARGET_VERSION="main"
  fi
else
  TARGET_VERSION="${VERSION}"
fi

if [[ -n "${installed}" ]]; then
  if [[ "${installed}" == "${TARGET_VERSION}" ]]; then
    log "Already at ${TARGET_VERSION}"
  else
    log "Updating: ${installed} → ${TARGET_VERSION}"
  fi
else
  log "Installing version: ${TARGET_VERSION}"
fi

log "profile: ${PROFILE}"

# ── 0. Clean up stale state from previous installs ──────────────────

CHEZMOI_SRC="${HOME}/.local/share/chezmoi"
if [[ -d "${CHEZMOI_SRC}/.git" ]]; then
  CHEZMOI_BRANCH="$(git -C "${CHEZMOI_SRC}" symbolic-ref --short HEAD 2>/dev/null || echo "")"
  if [[ -z "${CHEZMOI_BRANCH}" ]]; then
    log "cleanup: chezmoi source is on detached HEAD, switching to main"
    git -C "${CHEZMOI_SRC}" checkout -B main origin/main 2>/dev/null \
      || git -C "${CHEZMOI_SRC}" checkout -B main 2>/dev/null \
      || warn "could not fix chezmoi branch — chezmoi update may fail"
  fi
fi

for bin in chezmoi starship zoxide; do
  if [[ -f "/usr/local/bin/${bin}" ]] && [[ -f "${HOME}/.local/bin/${bin}" ]]; then
    log "cleanup: removing old ${bin} from /usr/local/bin (now in ~/.local/bin)"
    maybe_sudo rm -f "/usr/local/bin/${bin}"
  fi
done

# ── OS detection ────────────────────────────────────────────────────

OS="$(uname -s)"
case "${OS}" in
  Linux)
    if ! command -v apt-get >/dev/null 2>&1; then
      echo "error: only apt-based Linux (Debian/Ubuntu) is supported" >&2
      exit 1
    fi
    PKG_MANAGER="apt"
    ;;
  Darwin)
    PKG_MANAGER="brew"
    ;;
  *)
    echo "error: unsupported OS '${OS}'" >&2
    exit 1
    ;;
esac

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then return; fi
  log "installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
}

# ── 1. System packages ──────────────────────────────────────────────

if [[ "${PKG_MANAGER}" == "apt" ]]; then
  APT_PKGS=()
  command -v git  >/dev/null 2>&1 || APT_PKGS+=(git)
  command -v curl >/dev/null 2>&1 || APT_PKGS+=(curl)
  command -v zsh  >/dev/null 2>&1 || APT_PKGS+=(zsh)
  command -v tmux >/dev/null 2>&1 || APT_PKGS+=(tmux)
  command -v fzf  >/dev/null 2>&1 || APT_PKGS+=(fzf)

  if [[ "${PROFILE}" == "workstation" ]]; then
    if ! command -v kitty >/dev/null 2>&1 && ! command -v xz >/dev/null 2>&1; then
      APT_PKGS+=(xz-utils)
    fi
  fi

  if [[ ${#APT_PKGS[@]} -gt 0 ]]; then
    log "installing apt packages: ${APT_PKGS[*]}"
    # Wait for dpkg lock (another apt process may be running)
    maybe_sudo apt-get update -qq
    maybe_sudo apt-get install -y "${APT_PKGS[@]}"
  fi
else
  ensure_brew
  for pkg in git curl zsh tmux fzf; do
    command -v "${pkg}" >/dev/null 2>&1 || brew install "${pkg}"
  done
fi

# ── 2. chezmoi ───────────────────────────────────────────────────────

if command -v chezmoi >/dev/null 2>&1; then
  log "chezmoi already installed, skipping"
else
  log "installing chezmoi"
  if [[ "${PKG_MANAGER}" == "brew" ]]; then
    brew install chezmoi
  else
    CHEZMOI_SCRIPT="$(curl -fsLS get.chezmoi.io)" || { echo "error: failed to download chezmoi installer" >&2; exit 1; }
    sh -c "${CHEZMOI_SCRIPT}" -- -b "${HOME}/.local/bin"
  fi
fi

# ── 3. starship ──────────────────────────────────────────────────────

if command -v starship >/dev/null 2>&1; then
  log "starship already installed, skipping"
else
  log "installing starship"
  STARSHIP_SCRIPT="$(curl -sS https://starship.rs/install.sh)" || { echo "error: failed to download starship installer" >&2; exit 1; }
  sh -c "${STARSHIP_SCRIPT}" -- -y -b "${HOME}/.local/bin"
fi

# ── 4. zoxide ────────────────────────────────────────────────────────

if command -v zoxide >/dev/null 2>&1; then
  log "zoxide already installed, skipping"
else
  log "installing zoxide"
  ZOXIDE_SCRIPT="$(curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)" || { echo "error: failed to download zoxide installer" >&2; exit 1; }
  sh -c "${ZOXIDE_SCRIPT}"
fi

# ── 5. Workstation-only: kitty ───────────────────────────────────────

if [[ "${PROFILE}" == "workstation" ]]; then
  if command -v kitty >/dev/null 2>&1; then
    log "kitty already installed, skipping"
  else
    log "installing kitty"
    if [[ "${PKG_MANAGER}" == "brew" ]]; then
      brew install --cask kitty
    else
      curl -sL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
      maybe_sudo ln -sf "${HOME}/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
    fi
  fi
fi

# ── 6. Nerd Font (workstation only) ──────────────────────────────────

if [[ "${PROFILE}" == "workstation" ]]; then
  if [[ "${PKG_MANAGER}" == "brew" ]]; then
    if brew list --cask "font-${NERD_FONT,,}-nerd-font" &>/dev/null 2>&1; then
      log "Nerd Font already installed, skipping"
    else
      log "installing ${NERD_FONT} Nerd Font"
      brew install --cask "font-jetbrains-mono-nerd-font"
    fi
  else
    FONT_DIR="${HOME}/.local/share/fonts/${NERD_FONT}NerdFont"
    if [[ -d "${FONT_DIR}" ]] && [[ "$(ls -A "${FONT_DIR}" 2>/dev/null)" ]]; then
      log "Nerd Font already installed, skipping"
    else
      log "installing ${NERD_FONT} Nerd Font"
      FONT_VERSION="$(curl -sSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest 2>/dev/null \
                      | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
      if [[ -n "${FONT_VERSION}" ]]; then
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${NERD_FONT}.tar.xz"
        mkdir -p "${FONT_DIR}"
        curl -fsSL "${FONT_URL}" | tar xJf - -C "${FONT_DIR}"
        if command -v fc-cache >/dev/null 2>&1; then
          fc-cache -f "${FONT_DIR}"
        fi
      else
        warn "could not determine Nerd Font version, skipping font install"
      fi
    fi
  fi
fi

# ── 7. Login shell → zsh ────────────────────────────────────────────

ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-}")"
if [[ "${CURRENT_SHELL}" != "${ZSH_PATH}" ]]; then
  log "setting zsh as login shell"
  if ! grep -qx "${ZSH_PATH}" /etc/shells 2>/dev/null; then
    echo "${ZSH_PATH}" | maybe_sudo tee -a /etc/shells >/dev/null
  fi
  if [[ "${OS}" == "Darwin" ]]; then
    chsh -s "${ZSH_PATH}"
  else
    maybe_sudo usermod -s "${ZSH_PATH}" "$(id -un)"
  fi
fi

# ── 8. chezmoi init + apply ─────────────────────────────────────────

log "running chezmoi init --apply (${PROFILE} profile)"
chezmoi init --apply --no-tty --promptString "profile=${PROFILE}" --branch main "${CHEZMOI_GITHUB_USER}"

save_installed_version "${TARGET_VERSION}"

# ── 9. Clone repos (interactive, workstation only) ───────────────────

if [[ "${PROFILE}" == "workstation" ]] && [[ -t 0 ]]; then
  REPOS=(
    "dotfiles"
    "homelab-ansible"
    "homelab-catalog"
  )
  GIT_DIR="${HOME}/GIT"

  echo ""
  log "clone repos into ${GIT_DIR}? (select with numbers, empty to skip)"
  for i in "${!REPOS[@]}"; do
    printf "  [%d] %s\n" "$((i + 1))" "${REPOS[$i]}"
  done
  printf "  [a] all\n"
  read -rp "Choice (e.g. 1 3, a, or Enter to skip): " CHOICE

  if [[ -n "${CHOICE}" ]]; then
    mkdir -p "${GIT_DIR}"
    SELECTED=()
    if [[ "${CHOICE}" == "a" ]]; then
      SELECTED=("${REPOS[@]}")
    else
      for n in ${CHOICE}; do
        if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#REPOS[@]} )); then
          SELECTED+=("${REPOS[$((n - 1))]}")
        fi
      done
    fi

    for REPO in "${SELECTED[@]}"; do
      DEST="${GIT_DIR}/${REPO}"
      if [[ -d "${DEST}" ]]; then
        log "${REPO}: already cloned at ${DEST}"
      else
        log "cloning ${REPO} via HTTPS..."
        git clone "https://github.com/${CHEZMOI_GITHUB_USER}/${REPO}.git" "${DEST}"
        log "switching ${REPO} remote to SSH..."
        git -C "${DEST}" remote set-url origin "git@github.com:${CHEZMOI_GITHUB_USER}/${REPO}.git"
      fi
    done
  fi
fi

log "done. Start a new shell (or 'exec zsh') to pick everything up."
