#!/usr/bin/env bash
#
# KDE Plasma Fedora and Arch Installation Script
# Run this from the Terminal on a fresh Fedora or Arch install with KDE Plasma.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/scripts/install"
WALLPAPERS_DIR="${SCRIPT_DIR}/wallpapers"

# shellcheck source=scripts/install/lib.sh
source "${INSTALL_DIR}/lib.sh"
export DISTRO PKG_MANAGER DISTRO_PRETTY_NAME
log_info "Detected distro: ${DISTRO_PRETTY_NAME} (using ${PKG_MANAGER})"

usage() {
    echo "Usage: ./install.sh [--profile personal|work]"
    echo "  Default profile: personal"
}

INSTALL_PROFILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            [[ $# -ge 2 ]] || { log_err "--profile needs a value."; usage >&2; exit 1; }
            INSTALL_PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            INSTALL_PROFILE="${1#--profile=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_err "Unknown argument: $1"
            usage >&2
            exit 1
            ;;
    esac
done

ensure_profile
log_info "Install profile: ${INSTALL_PROFILE}"

main() {
    reset_selected    # start every full run with a clean slate

    bash "${INSTALL_DIR}/prerequisites.sh"
    bash "${INSTALL_DIR}/system-settings.sh"
    bash "${INSTALL_DIR}/system-tools.sh"
    bash "${INSTALL_DIR}/shell.sh"
    bash "${INSTALL_DIR}/dev-tools.sh"
    bash "${INSTALL_DIR}/applications.sh"
    bash "${INSTALL_DIR}/dotfiles.sh"   # last: it needs the selections of the others
    bash "${INSTALL_DIR}/kde/kde-settings.sh"

    log_ok "***** INSTALL DONE! *****"
}

main "$@"
