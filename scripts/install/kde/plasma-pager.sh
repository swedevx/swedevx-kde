# plasma-pager.sh — settings of the Plasma Pager widget (virtual desktop
# switcher). Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time.

# set_plasma_pager
#
# Configures the pager widget if it is in a panel. The widget config lives in
# plasma-org.kde.plasma.desktop-appletsrc, in a group whose numbers vary per
# machine, so the group path is looked up first.
set_plasma_pager() {
    local groups
    if ! groups=$(kde_applet_groups org.kde.plasma.pager); then
        log_warn "Plasma Pager widget not found in any panel, skipping its settings."
        return 0
    fi

    log_info "Applying Plasma Pager settings..."

    # shellcheck disable=SC2086  # groups is a list of words, split on purpose
    set -- ${groups}
    local rc=plasma-org.kde.plasma.desktop-appletsrc

    # Show window outlines: unchecked.
    kde_set "${rc}" "$@" Configuration General showWindowOutlines false

    # Text display: Desktop name.
    kde_set "${rc}" "$@" Configuration General displayedText Name

    # Selecting current virtual desktop: Shows the desktop.
    kde_set "${rc}" "$@" Configuration General currentDesktopSelected ShowDesktop
}
