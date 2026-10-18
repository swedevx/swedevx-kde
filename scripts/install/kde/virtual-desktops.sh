# virtual-desktops.sh — KDE virtual desktops. Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time.

# set_virtual_desktops
#
# Three desktops in one row (Main, Terminal, Browser), plus the
# desktop-switching options. KWin keeps these in kwinrc.
set_virtual_desktops() {
    log_info "Applying virtual desktops..."

    kde_set kwinrc Desktops Number 3
    kde_set kwinrc Desktops Rows 1

    kde_set kwinrc Desktops Name_1 "Main"
    kde_set kwinrc Desktops Name_2 "Terminal"
    kde_set kwinrc Desktops Name_3 "Browser"

    # Show animation when switching: checked, effect "Slide".
    kde_set kwinrc Plugins slideEnabled true

    # Switch desktops independently for each screen: checked.
    kde_set kwinrc Windows PerOutputVirtualDesktops true
}
