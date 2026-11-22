#!/usr/bin/env bash
#
# dev-tools.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# Fedora names the package after the major version. Arch's dotnet-sdk needs
# no hook, since the logical name already matches.
pkg_name_dotnet-sdk_dnf() {
    echo "dotnet-sdk-10.0"
}

# install_dotnet_sdk
#
# Asks whether to install the dotnet SDK (default yes) and installs it.
install_dotnet_sdk() {
    if confirm "Do you want to install the latest dotnet SDK?" Y; then
        pkg_install_if_missing dotnet-sdk
    fi
}

# --- Visual Studio Code (Microsoft's build) ---

# Arch: the AUR package visual-studio-code-bin is Microsoft's build.
# (`code` in the official repos is the open-source Code - OSS build.)
pkg_install_visual-studio-code_pacman() {
    aur_install visual-studio-code-bin
}
pkg_is_installed_visual-studio-code_pacman() {
    pacman -Qq visual-studio-code-bin &>/dev/null
}

# Fedora: Microsoft's own repo, then the normal dnf install of `code`.
pkg_name_visual-studio-code_dnf() {
    echo "code"
}
pkg_setup_visual-studio-code_dnf() {
    local repo_file="/etc/yum.repos.d/vscode.repo"

    if [[ -f "${repo_file}" ]]; then
        log_info "VS Code repo already configured."
        return 0
    fi

    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee "${repo_file}" >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
}

# --- Passenger IDE (Fedora only) ---
# Not in any repo: a tarball from GitHub with its own install.sh, which
# installs for the current user only (~/.local/opt/passenger).

# Runtime libraries the page lists for Fedora. Runs before the install hook.
pkg_setup_passenger-ide_dnf() {
    local pkg
    for pkg in git libX11 libICE libSM fontconfig dejavu-sans-fonts; do
        pkg_install_if_missing "${pkg}"
    done
}

# Not in the rpm database, so the check looks for the link install.sh creates.
pkg_is_installed_passenger-ide_dnf() {
    [[ -e "${HOME}/.local/bin/passenger-ide" ]]
}

pkg_install_passenger-ide_dnf() {
    local arch tmp status=0
    arch=$(uname -m | sed 's/x86_64/x64/; s/aarch64/arm64/')
    tmp=$(mktemp -d)

    curl -fsSL -o "${tmp}/passenger.tar.gz" \
        "https://github.com/Zaneris/passenger/releases/latest/download/Passenger-linux-${arch}.tar.gz" \
        && tar -xzf "${tmp}/passenger.tar.gz" -C "${tmp}" \
        && "${tmp}/passenger/install.sh" \
        || status=$?

    rm -rf "${tmp}"   # always clean up, even if the install failed
    return "${status}"
}

# install_ide
#
# Asks which IDE to install (Visual Studio Code is the default for both
# profiles) and installs it. Passenger is only offered on Fedora.
#
# To use a different default per profile, replace the "[Visual Studio Code]"
# bracket with a computed default, like this:
#
#   local ide default
#   default=$(by_profile "Zed" "Visual Studio Code")   # personal, work
#   ...
#   ide=$(choose_option "Choose your development IDE" --default "${default}" \
#       "${options[@]}") || return 1
#
# and list the options without brackets: ("Visual Studio Code" "Zed" ...).
# The label passed to by_profile must match an option label exactly.
install_ide() {
    local ide
    # local ide default
    # default=$(by_profile "Zed" "Visual Studio Code")   # personal, work

    local options=("[Visual Studio Code]" "Zed")
    if [[ "${PKG_MANAGER}" == "dnf" ]]; then
        options+=("Passenger")
    fi
    options+=("None")

    ide=$(choose_option "Choose your development IDE" "${options[@]}") || return 1
    # ide=$(choose_option "Choose your development IDE" --default "${default}" \
    #     "${options[@]}") || return 1

    case "$ide" in
        "Visual Studio Code")
            pkg_install_if_missing visual-studio-code
            ;;
        Zed)
            pkg_install_if_missing zed
            ;;
        Passenger)
            pkg_install_if_missing passenger-ide
            ;;
        None)
            log_info "No development IDE chosen!"
            ;;
        *)
            log_err "Unexpected choice: '$ide'"
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
    install_dotnet_sdk
    install_ide

    case "${INSTALL_PROFILE}" in
        work)     install_work_apps ;;
        personal) install_personal_apps ;;
    esac
}

main "$@"
