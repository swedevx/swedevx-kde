#!/usr/bin/env bash
#
# system-tools.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# install_terminal
#
# Asks which terminal emulator to install (Kitty is the default) and
# installs it with pkg_install_if_missing. Choosing "None" skips the
# installation.
#
# Returns:
#   0 on success or when skipped, 1 on an unexpected choice.
install_terminal() {
    terminal=$(choose_option "Choose your terminal" "[Kitty]" "Ghostty" "None")

    case "$terminal" in
        Kitty)
            pkg_install_if_missing kitty
            ;;
        Ghostty)
            pkg_install_if_missing ghostty
            ;;
        None)
            log_info "No terminal chosen!"
            ;;
        *)
            log_err "Unexpected choice: '$terminal'"
            return 1
            ;;
    esac
}

# Starship comes from a COPR on Fedora.
pkg_setup_starship_dnf() {
    sudo dnf copr enable -y atim/starship
}

install_starship() {
    if confirm "Do you want to install Starship?" Y; then
        pkg_install_if_missing starship
    fi
}

install_fastfetch() {
    if confirm "Do you want to install Fastfetch?" Y; then
        pkg_install_if_missing fastfetch
    fi
}

install_work_apps() {
    log_info "No work-specific apps defined yet, skipping."
}

install_personal_apps() {
    log_info "No personal-specific apps defined yet, skipping."
}


main() {
    ensure_profile

    # Install on both profiles
    install_terminal
    install_starship
    install_fastfetch

    case "${INSTALL_PROFILE}" in
        work)     install_work_apps ;;
        personal) install_personal_apps ;;
    esac
}

main "$@"
