#!/usr/bin/env bash
# Bootstrap a fresh Linux or macOS machine for this dotfiles repo.
# Installs system dependencies and chezmoi, then hands off to chezmoi
# which manages dotfiles and user-level tools via run_once scripts.
#
# Safe to re-run: every step is skipped if already present.
#
# Usage:
#   ./install.sh                          # workstation (default)
#   ./install.sh --profile server         # server (no kitty/fzf/font)
#   ./install.sh --profile devcontainer   # devcontainer (prefix C-y)
#   curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash
#   curl -fsLS https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh | bash -s -- --profile server

set -euo pipefail

GITHUB_USER="st0o0"
PROFILE="workstation"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    *) echo "error: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

case "${PROFILE}" in
  workstation|server|devcontainer) ;;
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

# ── 1. OS detection ────────────────────────────────────────────────

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

# ── 2. System packages ─────────────────────────────────────────────

if [[ "${PKG_MANAGER}" == "apt" ]]; then
  APT_PKGS=()
  command -v git  >/dev/null 2>&1 || APT_PKGS+=(git)
  command -v curl >/dev/null 2>&1 || APT_PKGS+=(curl)
  command -v zsh  >/dev/null 2>&1 || APT_PKGS+=(zsh)
  command -v tmux >/dev/null 2>&1 || APT_PKGS+=(tmux)

  if [[ ${#APT_PKGS[@]} -gt 0 ]]; then
    log "installing apt packages: ${APT_PKGS[*]}"
    maybe_sudo apt-get update -qq
    maybe_sudo apt-get install -y "${APT_PKGS[@]}"
  fi
else
  ensure_brew
  for pkg in git curl zsh tmux; do
    command -v "${pkg}" >/dev/null 2>&1 || brew install "${pkg}"
  done
fi

# ── 3. chezmoi ──────────────────────────────────────────────────────

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

# ── 4. Login shell → zsh ───────────────────────────────────────────

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

# ── 5. chezmoi init + apply ────────────────────────────────────────
# chezmoi run_once_before scripts handle starship, zoxide, fzf etc.

log "running chezmoi init --apply (${PROFILE} profile)"
if [[ -d "${CHEZMOI_SRC}/.git" ]]; then
  chezmoi update --force
else
  chezmoi init --apply --force --promptChoice "Machine profile=${PROFILE}" "${GITHUB_USER}"
fi

# ── 6. Clone repos (interactive, workstation only) ──────────────────

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
        git clone "https://github.com/${GITHUB_USER}/${REPO}.git" "${DEST}"
        log "switching ${REPO} remote to SSH..."
        git -C "${DEST}" remote set-url origin "git@github.com:${GITHUB_USER}/${REPO}.git"
      fi
    done
  fi
fi

log "done. Start a new shell (or 'exec zsh') to pick everything up."
