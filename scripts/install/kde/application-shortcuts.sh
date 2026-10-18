# application-shortcuts.sh — KDE keyboard shortcuts. Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time. INSTALL_PROFILE is only
# guaranteed to be valid after ensure_profile has run in kde-settings.sh.

# set_keyboard_shortcuts
#
# Applies the shortcuts both profiles get, then the profile-specific ones.
set_application_shortcuts() {
    log_info "Applying keyboard shortcuts (${INSTALL_PROFILE})..."

    set_terminal_shortcut
    set_browser_shortcut
}

# set_terminal_shortcut
#
# Binds Meta+Return to the terminal the user selected.
# To find the group and key for a new shortcut, copy ~/.config/kglobalshortcutsrc,
# change the shortcut in System Settings, and diff the two files.
set_terminal_shortcut() {
    if is_selected kitty; then
        kde_set kglobalshortcutsrc services kitty.desktop _launch "Meta+Return"
    fi

    if is_selected ghostty; then
        kde_set kglobalshortcutsrc services com.mitchellh.ghostty.desktop _launch "Meta+ReturnT"
    fi

    # This is KDE's default terminal
    if is_selected konsole; then
        kde_set kglobalshortcutsrc services org.kde.konsole.desktop _launch "Meta+Return"
    fi
}

# set_browser_shortcut
#
# Binds Meta+B to the browser the user selected.
set_browser_shortcut() {
    if is_selected brave-origin; then
        kde_set kglobalshortcutsrc services brave-browser.desktop _launch "Meta+B"
    fi

    if is_selected firefox; then
        kde_set kglobalshortcutsrc services firefox.desktop _launch "Meta+B"
    fi
}
