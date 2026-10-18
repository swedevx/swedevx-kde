# lib-kde.sh — helpers shared by the KDE topic files. Sourced, not run.

# kde_set FILE GROUP... KEY VALUE
#
# Writes one key to ~/.config/FILE. The last two arguments are the key and
# the value, everything between FILE and those is the group path, so nested
# groups work: kde_set kglobalshortcutsrc services kitty.desktop _launch "Ctrl+Alt+T"
kde_set() {
    local file="$1"; shift
    local value="${!#}"
    local key="${*: -2:1}"
    local args=(--file "${file}")
    local i

    for ((i = 1; i <= $# - 2; i++)); do
        args+=(--group "${!i}")
    done

    kwriteconfig6 "${args[@]}" --key "${key}" "${value}"
}

# kde_applet_groups PLUGIN
#
# Prints the group path of the first Plasma widget with the given plugin id,
# one group per word, e.g. "Containments 2 Applets 5". Returns 1 if the
# widget is not in any panel or desktop.
kde_applet_groups() {
    local rc="${XDG_CONFIG_HOME:-${HOME}/.config}/plasma-org.kde.plasma.desktop-appletsrc"
    local groups

    [[ -f "${rc}" ]] || return 1

    groups=$(awk -v plugin="plugin=$1" '
        /^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/ { section = $0 }
        $0 == plugin && section != "" { print section; exit }
    ' "${rc}" | tr -d '[' | tr ']' ' ')

    [[ -n "${groups}" ]] || return 1
    echo "${groups}"
}
