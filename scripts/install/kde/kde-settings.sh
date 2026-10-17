#!/usr/bin/env bash
#
# kde-settings.sh — applies KDE Plasma settings with kwriteconfig6.
# Each topic lives in its own file in this folder and is sourced below.
# Skipped when Plasma 6 is not installed.

set -euo pipefail

KDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "${KDE_DIR}/../lib.sh"
# shellcheck source=lib-kde.sh
source "${KDE_DIR}/lib-kde.sh"
# shellcheck source=keyboard-shortcuts.sh
source "${KDE_DIR}/keyboard-shortcuts.sh"

# install_kde_settings
#
# Asks whether to apply the KDE settings (default yes), then runs each topic.
install_kde_settings() {
    if ! command -v kwriteconfig6 &>/dev/null; then
        log_info "kwriteconfig6 not found (no KDE Plasma 6), skipping KDE settings."
        return 0
    fi

    confirm "Do you want to apply the KDE settings?" Y || return 0

    set_keyboard_shortcuts

    log_ok "KDE settings written. Log out and in again to apply them."
}

main() {
    ensure_profile
    install_kde_settings
}

main "$@"
