# window-management-shortcuts.sh — KDE window management shortcuts.
# Sourced by kde-settings.sh.
#
# Functions only: nothing runs at source time.

# set_window_management_shortcuts
#
# Close window and move-window-to-desktop shortcuts. KWin keeps these in
# kglobalshortcutsrc, group "kwin". The value format is
# "current shortcut,default shortcut,display name".
# The shortcuts are in single quotes so bash leaves !, " and # alone.
set_window_management_shortcuts() {
    log_info "Applying window management shortcuts..."

    kde_set kglobalshortcutsrc kwin "Window Close" 'Meta+C,Alt+F4,Close Window'

    kde_set kglobalshortcutsrc kwin "Window to Desktop 1" 'Meta+Ctrl+!,none,Window to Desktop 1'
    kde_set kglobalshortcutsrc kwin "Window to Desktop 2" 'Meta+Ctrl+",none,Window to Desktop 2'
    kde_set kglobalshortcutsrc kwin "Window to Desktop 3" 'Meta+Ctrl+#,none,Window to Desktop 3'
    kde_set kglobalshortcutsrc kwin "Window to Desktop 4" 'Meta+Ctrl+¤,none,Window to Desktop 4'
    kde_set kglobalshortcutsrc kwin "Window to Desktop 5" 'Meta+Ctrl+%,none,Window to Desktop 5'
}
