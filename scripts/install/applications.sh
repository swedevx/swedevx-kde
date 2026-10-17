#!/usr/bin/env bash
#
# applications.sh — installs end-user applications (browsers, editors, ...).
# Run by install.sh after prerequisites.sh and system-tools.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# --- Brave Origin -----------------------------------------------------------

# Arch: AUR package brave-origin-bin.
pkg_install_brave-origin_pacman() {
    aur_install brave-origin-bin
}
pkg_is_installed_brave-origin_pacman() {
    pacman -Qq brave-origin-bin &>/dev/null
}

# Fedora: Brave's own repo, then the normal dnf install of brave-origin.
pkg_setup_brave-origin_dnf() {
    local repo_file="/etc/yum.repos.d/brave-browser.repo"

    if [[ -f "${repo_file}" ]]; then
        log_info "Brave repo already configured."
        return 0
    fi

    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
}

# install_browser
#
# Asks which web browser to install (Brave Origin is the default) and
# installs it. Brave Origin uses the per-distro hooks above; Firefox comes
# straight from the distro repos. Choosing "None" skips the installation.
#
# Returns:
#   0 on success or when skipped, 1 on an unexpected choice or if input ends.
install_browser() {
    local browser default
    default=$(by_profile "Brave Origin" "Firefox")   # personal, work

    browser=$(choose_option "Choose your browser" --default "${default}" \
        "Brave Origin" "Firefox" "None") || return 1

    case "$browser" in
        "Brave Origin")
            pkg_install_if_missing brave-origin
            ;;
        Firefox)
            pkg_install_if_missing firefox
            ;;
        None)
            log_info "No browser chosen!"
            ;;
        *)
            log_err "Unexpected choice: '$browser'"
            return 1
            ;;
    esac
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
    install_browser

    case "${INSTALL_PROFILE}" in
        work)     install_work_apps ;;
        personal) install_personal_apps ;;
    esac
}

main "$@"
