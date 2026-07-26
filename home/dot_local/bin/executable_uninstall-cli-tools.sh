#!/usr/bin/env bash
# Removes what install-cli-tools.sh installs. lazygit/lazydocker/lazyssh/
# zeit/serie are plain binaries in ~/.local/bin; vortix is special-cased
# because its upstream installer drops the binary in ~/.cargo/bin (cargo-dist
# convention) and, per its own README, may need a /usr/local/bin symlink for
# `sudo vortix` to work — see install-cli-tools.sh's install_vortix comment.
#
# Usage: uninstall-cli-tools.sh [tool ...]   (default: all tools below)

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

remove() {
    # remove <path>
    if [ -e "$1" ] || [ -L "$1" ]; then
        rm -f "$1"
        echo "removed $1"
    fi
}

uninstall_lazygit()    { remove "$INSTALL_DIR/lazygit"; }
uninstall_lazydocker() { remove "$INSTALL_DIR/lazydocker"; }
uninstall_lazyssh()    { remove "$INSTALL_DIR/lazyssh"; }
uninstall_zeit()       { remove "$INSTALL_DIR/zeit"; }
uninstall_serie()      { remove "$INSTALL_DIR/serie"; }

uninstall_zoxide()     { remove "$INSTALL_DIR/zoxide"; }
uninstall_fzf()        { remove "$INSTALL_DIR/fzf"; }

uninstall_vortix() {
    remove "$HOME/.cargo/bin/vortix"
    remove "$HOME/.cargo/bin/vortix-receipt.json"
    remove "/usr/local/bin/vortix"
}

all_tools="lazygit lazydocker lazyssh zeit serie zoxide fzf vortix"
tools="${*:-$all_tools}"

for tool in $tools; do
    "uninstall_${tool}"
done
