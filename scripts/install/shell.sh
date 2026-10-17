#!/usr/bin/env bash
#
# shell.sh — optionally installs zsh with plugins and makes it the login shell.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# set_default_shell SHELL_PATH
#
# Makes SHELL_PATH the login shell of the current user. Skips if it already is.
# Takes effect on the next login.
set_default_shell() {
    local shell_path="$1" current

    # $SHELL is the shell of the current session, so ask the user database.
    current=$(getent passwd "$(id -un)" | cut -d: -f7)

    if [[ "${current}" == "${shell_path}" ]]; then
        log_ok "zsh is already the login shell, skipping."
        return 0
    fi

    if ! grep -qxF "${shell_path}" /etc/shells; then
        log_err "${shell_path} is not listed in /etc/shells, not switching."
        return 1
    fi

    log_info "Setting zsh as the login shell..."
    sudo usermod --shell "${shell_path}" "$(id -un)"
    log_ok "Login shell changed. It takes effect on your next login."
}

# install_shell
#
# Asks whether to switch to zsh (default yes). If yes, installs zsh and its
# plugins and makes zsh the login shell.
install_shell() {
    confirm "Do you want to switch to zsh?" Y || { log_info "Keeping the current shell."; return 0; }

    local packages=(zsh zsh-autosuggestions zsh-syntax-highlighting)
    local pkg
    for pkg in "${packages[@]}"; do
        pkg_install_if_missing "${pkg}"
    done

    set_default_shell "$(command -v zsh)"
}

main() {
    install_shell
}

main "$@"
