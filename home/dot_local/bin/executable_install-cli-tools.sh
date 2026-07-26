#!/usr/bin/env bash
# Installs a handful of small Go/Rust terminal tools as prebuilt release
# binaries into ~/.local/bin (already on PATH via .zshrc) — no go/cargo
# toolchain needed. Always fetches whatever the GitHub API currently
# reports as "latest", so re-running this script is the upgrade path too.
#
# Usage: install-cli-tools.sh [tool ...]   (default: all tools below)

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"

OS=$(uname -s)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_GNU=x86_64; ARCH_RUST=x86_64; ARCH_GO=amd64 ;;
    aarch64|arm64) ARCH_GNU=arm64; ARCH_RUST=aarch64; ARCH_GO=arm64 ;;
    *) echo "install-cli-tools: unsupported arch: $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
    Linux)  OS_LOWER=linux;  OS_TITLE=Linux ;;
    Darwin) OS_LOWER=darwin; OS_TITLE=Darwin ;;
    *) echo "install-cli-tools: unsupported OS: $OS" >&2; exit 1 ;;
esac

latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'
}

fetch_extract() {
    # fetch_extract <url> <binary-name-inside-archive>
    local url="$1" bin_in_archive="$2" tmp
    tmp=$(mktemp -d)
    curl -fsSL "$url" -o "$tmp/archive.tar.gz"
    tar xzf "$tmp/archive.tar.gz" -C "$tmp" "$bin_in_archive"
    install -m 755 "$tmp/$bin_in_archive" "$INSTALL_DIR/$(basename "$bin_in_archive")"
    rm -rf "$tmp"
}

install_lazygit() {
    local v; v=$(latest_tag jesseduffield/lazygit | sed 's/^v//')
    fetch_extract "https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_${OS_TITLE}_${ARCH_GNU}.tar.gz" lazygit
    echo "lazygit ${v} -> $INSTALL_DIR/lazygit"
}

install_lazydocker() {
    local v; v=$(latest_tag jesseduffield/lazydocker | sed 's/^v//')
    fetch_extract "https://github.com/jesseduffield/lazydocker/releases/download/v${v}/lazydocker_${v}_${OS_TITLE}_${ARCH_GNU}.tar.gz" lazydocker
    echo "lazydocker ${v} -> $INSTALL_DIR/lazydocker"
}

install_lazyssh() {
    local v; v=$(latest_tag adembc/lazyssh)
    fetch_extract "https://github.com/adembc/lazyssh/releases/download/${v}/lazyssh_${OS_TITLE}_${ARCH_GNU}.tar.gz" lazyssh
    echo "lazyssh ${v} -> $INSTALL_DIR/lazyssh"
}

install_zeit() {
    local v; v=$(latest_tag mrusme/zeit | sed 's/^v//')
    fetch_extract "https://github.com/mrusme/zeit/releases/download/v${v}/zeit_${v}_${OS_LOWER}_${ARCH_GO}.tar.gz" zeit
    echo "zeit ${v} -> $INSTALL_DIR/zeit"
}

install_serie() {
    local v; v=$(latest_tag lusingander/serie | sed 's/^v//')
    local target="${ARCH_RUST}-unknown-${OS_LOWER}-musl"
    if [[ "$OS" == "Darwin" ]]; then
        target="${ARCH_RUST}-apple-darwin"
    fi
    fetch_extract "https://github.com/lusingander/serie/releases/download/v${v}/serie-${v}-${target}.tar.gz" serie
    echo "serie ${v} -> $INSTALL_DIR/serie"
}

install_zoxide() {
    local v; v=$(latest_tag ajeetdsouza/zoxide | sed 's/^v//')
    local target="${ARCH_RUST}-unknown-${OS_LOWER}-musl"
    if [[ "$OS" == "Darwin" ]]; then
        target="${ARCH_RUST}-apple-darwin"
    fi
    fetch_extract "https://github.com/ajeetdsouza/zoxide/releases/download/v${v}/zoxide-${v}-${target}.tar.gz" zoxide
    echo "zoxide ${v} -> $INSTALL_DIR/zoxide"
}

install_fzf() {
    local v; v=$(latest_tag junegunn/fzf | sed 's/^v//')
    fetch_extract "https://github.com/junegunn/fzf/releases/download/v${v}/fzf-${v}-${OS_LOWER}_${ARCH_GO}.tar.gz" fzf
    echo "fzf ${v} -> $INSTALL_DIR/fzf"
}

install_vortix() {
    # Upstream ships its own installer that already resolves the right
    # asset per OS/arch and drops the binary on PATH (~/.cargo/bin or
    # ~/.local/bin depending on environment) — no reason to reimplement it.
    curl --proto '=https' --tlsv1.2 -fsSL \
        https://github.com/Harry-kp/vortix/releases/latest/download/vortix-installer.sh | sh
}

all_tools="lazygit lazydocker lazyssh zeit serie zoxide fzf vortix"
tools="${*:-$all_tools}"

for tool in $tools; do
    "install_${tool}"
done
