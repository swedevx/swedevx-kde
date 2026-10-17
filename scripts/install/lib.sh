#!/usr/bin/env bash
#
# lib.sh — shared helpers sourced by every scripts/install/*.sh phase script
# and by the repo-root install.sh orchestrator.
#
# Not meant to be run directly.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC}  $*" >&2; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Sets DISTRO (fedora|arch) and PKG_MANAGER (dnf|pacman) by reading
# /etc/os-release's ID (falling back to ID_LIKE for derivatives — e.g. a
# future EndeavourOS/CachyOS install would match via ID_LIKE=arch without
# needing a new case arm). Refuses to guess: an unrecognized distro exits
# with the detected ID/ID_LIKE rather than silently defaulting to one
# package manager. Adding a third distro means adding one case arm here,
# not touching every phase script.
detect_distro() {
    # Already detected (e.g. exported by the orchestrator), nothing to do.
    if [[ -n "${DISTRO:-}" && -n "${PKG_MANAGER:-}" && -n "${DISTRO_PRETTY_NAME:-}" ]]; then
        return 0
    fi

    local os_release="/etc/os-release"
    [[ -f "${os_release}" ]] || os_release="/usr/lib/os-release"

    if [[ ! -f "${os_release}" ]]; then
        log_err "Could not find /etc/os-release or /usr/lib/os-release — cannot detect the Linux distribution."
        exit 1
    fi

    # shellcheck source=/dev/null
    source "${os_release}"

    case "${ID:-}" in
        fedora) DISTRO="fedora"; PKG_MANAGER="dnf" ;;
        arch)   DISTRO="arch";   PKG_MANAGER="pacman" ;;
        *)
            case " ${ID_LIKE:-} " in
                *" fedora "*) DISTRO="fedora"; PKG_MANAGER="dnf" ;;
                *" arch "*)   DISTRO="arch";   PKG_MANAGER="pacman" ;;
                *)
                    log_err "Unrecognized distro (ID='${ID:-unknown}', ID_LIKE='${ID_LIKE:-}')." \
                         "This repo only supports Fedora and Arch Linux right now."
                    exit 1
                    ;;
            esac
            ;;
    esac

    DISTRO_PRETTY_NAME="${PRETTY_NAME:-$DISTRO}"
}

# _selected_file
#
# Path of the file listing the components the user chose this run. It is a
# file rather than a variable because phase scripts are separate processes.
_selected_file() {
    echo "${XDG_STATE_HOME:-${HOME}/.local/state}/system-setup/selected"
}

# reset_selected
#
# Forgets all selections. Called once by install.sh at the start of a run.
reset_selected() {
    local file
    file=$(_selected_file)
    mkdir -p "$(dirname "${file}")"
    : > "${file}"
}

# mark_selected NAME
#
# Records that NAME was chosen (and is now installed).
mark_selected() {
    local file
    file=$(_selected_file)
    mkdir -p "$(dirname "${file}")"
    is_selected "$1" || echo "$1" >> "${file}"
}

# is_selected NAME
#
# True if NAME was recorded by mark_selected.
is_selected() {
    grep -qxF -- "$1" "$(_selected_file)" 2>/dev/null
}

# ensure_profile
#
# Makes sure INSTALL_PROFILE is set to a valid profile (personal|work).
# Defaults to "personal" when unset or empty. Exports the result so child
# processes (the phase scripts) inherit it.
#
# Returns:
#   0 on success, 1 on an invalid value.
ensure_profile() {
    INSTALL_PROFILE="${INSTALL_PROFILE:-personal}"

    case "${INSTALL_PROFILE}" in
        personal|work) ;;
        *)
            log_err "Unknown profile '${INSTALL_PROFILE}' (expected: personal or work)."
            return 1
            ;;
    esac
    export INSTALL_PROFILE
}

# by_profile PERSONAL_VALUE WORK_VALUE
#
# Prints the value for the current INSTALL_PROFILE.
by_profile() {
    case "${INSTALL_PROFILE:-personal}" in
        personal) echo "$1" ;;
        work)     echo "$2" ;;
        *)        log_err "by_profile: unknown profile '${INSTALL_PROFILE}'"; return 1 ;;
    esac
}

# is_installed PKG
#
# True if PKG is installed. If a hook named pkg_is_installed_<PKG>_<PKG_MANAGER>
# exists it decides (for installs that don't show up in the package database,
# or whose package name differs); otherwise the package manager is asked.
is_installed() {
    local pkg="$1"
    local check="pkg_is_installed_${pkg}_${PKG_MANAGER}"

    if declare -F "${check}" &>/dev/null; then
        "${check}"
        return
    fi

    local real
    real=$(_pkg_real_name "${pkg}")

    case "${PKG_MANAGER}" in
        dnf)    rpm -q "${real}" &>/dev/null ;;
        pacman) pacman -Qq "${real}" &>/dev/null ;;
        *)      return 1 ;;
    esac
}

# _pkg_real_name PKG
#
# Prints the package name to hand to the package manager. If a function
# named pkg_name_<PKG>_<PKG_MANAGER> exists it supplies the name (for
# packages named differently per distro); otherwise PKG is used as is.
_pkg_real_name() {
    local hook="pkg_name_${1}_${PKG_MANAGER}"
    if declare -F "${hook}" &>/dev/null; then
        "${hook}"
    else
        echo "$1"
    fi
}

# _aur_helper
#
# Prints the installed AUR helper (yay or paru). Returns 1 if there is none.
_aur_helper() {
    local helper
    for helper in yay paru; do
        if command -v "${helper}" &>/dev/null; then
            echo "${helper}"
            return 0
        fi
    done
    return 1
}

# _ensure_aur_helper
#
# Makes sure an AUR helper exists, bootstrapping yay or paru (user's choice)
# via git + makepkg if not. Arch only.
_ensure_aur_helper() {
    if [[ "${PKG_MANAGER}" != "pacman" ]]; then
        log_err "AUR helper requested on a system that isn't using pacman."
        return 1
    fi

    if _aur_helper >/dev/null; then
        return 0
    fi

    log_warn "About to bootstrap an AUR helper and build AUR packages with makepkg." \
             "The AUR has had supply-chain-attack activity and registration freezes" \
             "in the past. Check https://aur.archlinux.org and the package pages" \
             "before trusting this if you haven't recently."

    local helper
    helper=$(choose_option "Choose an AUR helper to install" "[yay]" "paru") || return 1

    log_info "Bootstrapping ${helper}..."
    sudo pacman -S --needed --noconfirm git base-devel

    local tmp status=0
    tmp="$(mktemp -d)"
    git clone "https://aur.archlinux.org/${helper}.git" "${tmp}" \
        && (cd "${tmp}" && makepkg -si --noconfirm) \
        || status=$?
    rm -rf "${tmp}"   # always clean up, even if the build failed

    return "${status}"
}

# aur_install AUR_PKG
#
# Installs AUR_PKG with the AUR helper, bootstrapping the helper first if
# needed. Arch only. Call it from a pkg_install_* hook, which has already
# been skipped if the package is installed.
aur_install() {
    local pkg="$1" helper
    _ensure_aur_helper || return 1
    helper=$(_aur_helper)
    "${helper}" -S --needed --noconfirm "${pkg}"
}

# _pkg_manager_install PKG...
#
# Installs the given packages in one call with the current package manager.
# Internal helper, no hook or already-installed checks.
_pkg_manager_install() {
    case "${PKG_MANAGER}" in
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --needed --noconfirm "$@" ;;
        *)      log_err "No install command for package manager '${PKG_MANAGER}'"; return 1 ;;
    esac
}

# pkg_install_if_missing PKG
#
# Installs PKG unless already present. Optional per-distro hooks, looked up
# by name as <prefix>_<PKG>_<PKG_MANAGER>:
#   pkg_name_*     supplies the distro's real package name
#   pkg_setup_*    runs first (e.g. enable a repo), then the normal install
#   pkg_install_*  replaces the normal install entirely
pkg_install_if_missing() {
    local pkg="$1"
    local setup="pkg_setup_${pkg}_${PKG_MANAGER}"
    local custom="pkg_install_${pkg}_${PKG_MANAGER}"

    if is_installed "${pkg}"; then
        log_ok "${pkg} already installed, skipping."
        mark_selected "${pkg}"
        return 0
    fi

    if declare -F "${setup}" &>/dev/null; then
        log_info "Preparing ${pkg} (${setup})..."
        "${setup}" || return
    fi

    if declare -F "${custom}" &>/dev/null; then
        log_info "Installing ${pkg} with custom installer (${custom})..."
        "${custom}" || return
    else
        _pkg_manager_install "$(_pkg_real_name "${pkg}")" || return
    fi

    mark_selected "${pkg}"
}

# confirm PROMPT [DEFAULT]
#
# Asks a yes/no question and returns the answer as an exit status.
# Use it in a condition: if confirm "Install Kitty?" Y; then ...
#
# Arguments:
#   PROMPT   The question to ask.
#   DEFAULT  Y or N (case-insensitive), used when the user just presses
#            Enter. Defaults to Y. The hint shows it as [Y/n] or [y/N].
#
# Accepts y, yes, n, no in any case.
#
# Returns:
#   0 for yes, 1 for no, 2 if input ends (Ctrl-D) or DEFAULT is invalid.
confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    local hint reply

    case "${default^^}" in
        Y) hint="Y/n"; default="y" ;;
        N) hint="y/N"; default="n" ;;
        *) log_err "confirm: default must be Y or N, got '$2'"; return 2 ;;
    esac

    while true; do
        read -r -p "$prompt [$hint]: " reply </dev/tty || return 2
        reply="${reply:-$default}"

        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
        esac
        log_err "Please answer y or n."
    done
}

# choose_option PROMPT [--default NAME] OPTION...
#
# Shows a numbered menu and returns the selected option on stdout.
# Capture it with: choice=$(choose_option "Prompt" "[Default]" "Other" ...)
#
# Arguments:
#   PROMPT          Heading shown above the menu.
#   --default NAME  Optional, directly after PROMPT. Marks the option labelled
#                   NAME as the default. Use it when the default is computed
#                   (e.g. per profile). For a fixed default, [brackets] are
#                   shorter.
#   OPTION          One or more choices. Wrap one in [brackets] to make it the
#                   default (pressed with Enter). Without brackets or
#                   --default, the first option is the default.
#
# Output:
#   stdout  The selected option, without brackets. Nothing else.
#   stderr  The menu and any error messages.
#
# Returns:
#   0 on a valid selection, 1 if input ends (Ctrl-D).
choose_option() {
    local prompt="$1"
    shift

    # Optional: --default NAME marks the option with that exact label
    local default_name=""
    if [[ "${1:-}" == "--default" ]]; then
        default_name="$2"
        shift 2
    fi

    local options=()
    local default_idx=0
    local re='^\[(.*)\]$'
    local opt i=0

    for opt in "$@"; do
        if [[ "$opt" =~ $re ]]; then
            opt="${BASH_REMATCH[1]}"
            default_idx=$i
        elif [[ -n "$default_name" && "$opt" == "$default_name" ]]; then
            default_idx=$i
        fi
        options+=("$opt")
        i=$((i + 1))
    done

    local reply mark
    while true; do
        # Menu goes to stderr so $(...) only captures the final choice
        echo "$prompt" >&2
        for i in "${!options[@]}"; do
            mark=""
            (( i == default_idx )) && mark=" (default)"
            printf '  %d) %s%s\n' "$((i + 1))" "${options[i]}" "$mark" >&2
        done

        read -r -p "Choice [$((default_idx + 1))]: " reply </dev/tty || return 1
        reply="${reply:-$((default_idx + 1))}"

        if [[ "$reply" =~ ^[0-9]+$ ]] && (( 10#$reply >= 1 && 10#$reply <= ${#options[@]} )); then
            echo "${options[10#$reply - 1]}"
            return 0
        fi
        log_err "Invalid selection."
    done
}


# REPO_ROOT: resolved relative to this file (scripts/install/lib.sh -> repo root
# is two directories up). Phase scripts source this file first, so they can
# rely on REPO_ROOT being set without recomputing it themselves.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

detect_distro
