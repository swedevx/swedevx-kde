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

# --- Proton Mail (Fedora only) ---
# Not in any repo: Proton publishes a signed RPM. Steps follow Proton's
# "Verifying the Proton Mail desktop app package on Fedora" page.

# _install_proton_mail_rpm DIR
#
# Downloads the key and RPM into DIR, verifies them, and installs the RPM.
# Explicit "|| return 1" on every step: set -e does not apply here, because
# the caller uses this function in an || list.
_install_proton_mail_rpm() {
    local dir="$1"
    local base="https://proton.me/download/mail/linux"
    local fingerprint="1C27DF7A717BCBCAC760A84C0DB4B0701E5FB04A"
    local actual

    curl -fsSL -o "${dir}/RPM-GPG-KEY-proton-mail" "${base}/RPM-GPG-KEY-proton-mail" || return 1
    curl -fsSL -o "${dir}/ProtonMail-desktop-beta.rpm" "${base}/ProtonMail-desktop-beta.rpm" || return 1

    actual=$(gpg --show-keys --with-colons "${dir}/RPM-GPG-KEY-proton-mail" \
        | awk -F: '/^fpr:/ {print $10; exit}') || return 1
    if [[ "${actual}" != "${fingerprint}" ]]; then
        log_err "Proton key fingerprint mismatch (got '${actual}'), not installing."
        return 1
    fi

    sudo rpm --import "${dir}/RPM-GPG-KEY-proton-mail" || return 1

    if ! rpm --checksig "${dir}/ProtonMail-desktop-beta.rpm" | grep -q "signatures OK"; then
        log_err "Proton Mail RPM signature check failed, not installing."
        return 1
    fi

    sudo dnf install -y "${dir}/ProtonMail-desktop-beta.rpm"
}

pkg_install_proton-mail_dnf() {
    local tmp status=0
    tmp=$(mktemp -d)
    _install_proton_mail_rpm "${tmp}" || status=$?
    rm -rf "${tmp}"   # always clean up, even if the install failed
    return "${status}"
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

# install_email
#
# Asks which email client to install and installs it. Fedora only: other
# distros skip it. Thunderbird is the default on work, Proton Mail on
# personal (Proton Mail is not offered on work).
install_email() {
    if [[ "${PKG_MANAGER}" != "dnf" ]]; then
        return 0
    fi

    local mail default
    default=$(by_profile "Proton Mail" "Thunderbird")   # personal, work

    local options=("Thunderbird" "KMail")
    if [[ "${INSTALL_PROFILE}" == "personal" ]]; then
        options+=("Proton Mail")
    fi
    options+=("None")

    mail=$(choose_option "Choose your email client" --default "${default}" \
        "${options[@]}") || return 1

    case "$mail" in
        Thunderbird)
            pkg_install_if_missing thunderbird
            ;;
        KMail)
            pkg_install_if_missing kmail
            ;;
        "Proton Mail")
            pkg_install_if_missing proton-mail
            ;;
        None)
            log_info "No email client chosen!"
            ;;
        *)
            log_err "Unexpected choice: '$mail'"
            return 1
            ;;
    esac
}

# install_libreoffice
#
# Asks which LibreOffice parts to install (type "a" for the full suite) and
# installs each as libreoffice-<part>. Fedora only: other distros skip it.
install_libreoffice() {
    if [[ "${PKG_MANAGER}" != "dnf" ]]; then
        return 0
    fi

    local selected part
    selected=$(choose_multiple "Choose the LibreOffice parts to install" \
        "[Writer]" "[Calc]" "[Impress]" "Draw" "Math" "Base") || return 1

    if [[ -z "${selected}" ]]; then
        log_info "No LibreOffice parts chosen!"
        return 0
    fi

    while IFS= read -r part; do
        pkg_install_if_missing "libreoffice-${part,,}"
    done <<< "${selected}"
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
    install_email
    install_libreoffice

    case "${INSTALL_PROFILE}" in
        work)     install_work_apps ;;
        personal) install_personal_apps ;;
    esac
}

main "$@"
