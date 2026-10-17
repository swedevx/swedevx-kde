#!/usr/bin/env bash
#
# prerequisites.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

update_system() {
    log_info "Updating system packages"
    case "${DISTRO}" in
        fedora) sudo dnf upgrade -y ;;
        arch)   sudo pacman -Syu --noconfirm ;;
    esac
}

add_third_part_repositories() {
    log_info "Adding third-party repositories..."

    case "${PKG_MANAGER}" in
        dnf)    add_fedora_repos ;;
        pacman) log_warn "PACMAN IS THE PACKAGE_MANAGER, AUR WILL BE ADDED WHEN NEEDED!" ;;
    esac
}

add_fedora_repos() {
    log_info "Installing RPM Fusion (free and non-free)..."
    if rpm -q rpmfusion-free-release &>/dev/null && rpm -q rpmfusion-nonfree-release &>/dev/null; then
        log_ok "RPM Fusion already installed. Skipping."
    else
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi

    log_info "Installing Terra repository..."
    if rpm -q terra-release &>/dev/null; then
        log_ok "Terra repository already installed. Skipping."
    else
        sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release -y
    fi

    log_info "Refreshing package cache..."
    sudo dnf check-update || true

    log_ok "Fedora repositories added."
}

install_core_tools() {
    log_info "Installing core CLI tools"

    local packages=(git curl tar unzip)
    local pkg
    for pkg in "${packages[@]}"; do
        pkg_install_if_missing "${pkg}"
    done
}

install_work_apps() {
    log_info "No work-specific apps defined yet, skipping."
}

install_personal_apps() {
    add_third_part_repositories
}

main() {
    ensure_profile

    # Install on both profiles
    update_system
    install_core_tools

    case "${INSTALL_PROFILE}" in
            work)     install_work_apps ;;
            personal) install_personal_apps ;;
        esac
}

main "$@"
