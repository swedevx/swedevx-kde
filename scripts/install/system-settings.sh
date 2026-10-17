#!/usr/bin/env bash
#
# system-settings.sh — machine-wide settings that are not packages
# (locale, ...).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# ensure_locale_available LOCALE
#
# Makes sure LOCALE (e.g. en_DK.UTF-8) exists on the system, so setting it
# in /etc/locale.conf actually has an effect.
ensure_locale_available() {
    local locale="$1"
    local pattern="${locale%.UTF-8}"

    if locale -a | grep -qiE "^${pattern}\.utf-?8$"; then
        return 0
    fi

    case "${PKG_MANAGER}" in
        dnf)
            # Fedora ships the English locales in this package.
            pkg_install_if_missing glibc-langpack-en
            ;;
        pacman)
            sudo sed -i "s/^#\(${locale} UTF-8\)/\1/" /etc/locale.gen
            sudo locale-gen
            ;;
    esac
}

# set_time_format_24h
#
# Sets LC_TIME to en_DK.UTF-8 in /etc/locale.conf, which gives a 24-hour
# clock on the login screen. Uses localectl, which edits the file safely
# and keeps any other entries.
set_time_format_24h() {
    local locale="en_DK.UTF-8"

    if localectl status | grep -q "LC_TIME=${locale}"; then
        log_ok "LC_TIME is already ${locale}, skipping."
        return 0
    fi

    ensure_locale_available "${locale}"

    log_info "Setting LC_TIME=${locale} (24-hour clock)..."
    sudo localectl set-locale "LC_TIME=${locale}"
    log_ok "LC_TIME set. The login screen picks it up after a reboot."
}

# install_system_settings
#
# Asks whether to use a 24-hour clock (default yes) and applies it.
install_system_settings() {
    if confirm "Do you want a 24-hour clock on the login screen?" Y; then
        set_time_format_24h
    fi
}

main() {
    install_system_settings
}

main "$@"
