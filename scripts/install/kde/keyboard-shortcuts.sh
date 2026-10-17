# keyboard-shortcuts.sh — KDE keyboard shortcuts. Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time. INSTALL_PROFILE is only
# guaranteed to be valid after ensure_profile has run in kde-settings.sh.

# set_keyboard_shortcuts
#
# Applies the shortcuts both profiles get, then the profile-specific ones.
set_keyboard_shortcuts() {
    log_info "Applying keyboard shortcuts (${INSTALL_PROFILE})..."

    set_shortcuts_common

    case "${INSTALL_PROFILE}" in
        work)     set_shortcuts_work ;;
        personal) set_shortcuts_personal ;;
    esac
}

# set_shortcuts_common
#
# Shortcuts for both profiles. Shortcuts that launch an app are only set
# when that app was selected. Find the group and key for each one with the
# diff method (copy ~/.config/kglobalshortcutsrc, change the shortcut in
# System Settings, diff).
set_shortcuts_common() {
    if is_selected kitty; then
        kde_set kglobalshortcutsrc services kitty.desktop _launch "Meta+Return"
    fi
}

# set_shortcuts_work
#
# Work-profile shortcuts. Nothing here yet.
set_shortcuts_work() {
    :
}

# set_shortcuts_personal
#
# Personal-profile shortcuts. Nothing here yet.
set_shortcuts_personal() {
    :
}
