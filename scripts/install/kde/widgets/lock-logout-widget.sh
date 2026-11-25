# lock-logout-widget.sh — the "Leave" widget (lock/logout/reboot/shutdown
# buttons). Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time.

# set_lock_logout_widget
#
# Adds the widget to the panel with only Log Out, Restart and Shut Down
# visible (Lock and Log Out Screen are hidden).
set_lock_logout_widget() {
    log_info "Adding the Lock/Logout widget..."

    kde_add_panel_widget org.kde.plasma.lock_logout \
        actionsOrder=lockScreen,switchUser,requestLogout,requestReboot,requestShutDown,requestLogoutScreen,suspendToRam,suspendToDisk \
        show_lockScreen=false \
        show_requestLogout=true \
        show_requestLogoutScreen=false \
        show_requestReboot=true \
        show_requestShutDown=true
}
