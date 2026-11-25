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

# kde_add_panel_widget PLUGIN [KEY=VALUE...]
#
# Adds the widget to the first panel and writes each KEY=VALUE to its
# "General" config group. Skipped if a widget with that plugin id already
# exists, so re-runs change nothing. true/false are written as booleans,
# everything else as strings. Values must not contain single quotes.
# Needs a running Plasma session (it talks to plasmashell over D-Bus).
kde_add_panel_widget() {
    local plugin="$1"
    shift
    local qdbus js pair key value

    if kde_applet_groups "${plugin}" >/dev/null; then
        log_ok "${plugin} already in a panel, skipping."
        return 0
    fi

    if ! qdbus=$(command -v qdbus6 || command -v qdbus-qt6); then
        log_warn "qdbus6 not found, cannot add ${plugin}."
        return 1
    fi

    js="var p = panels()[0]; if (p) { var w = p.addWidget('${plugin}'); w.currentConfigGroup = ['General'];"
    for pair in "$@"; do
        key="${pair%%=*}"
        value="${pair#*=}"
        case "${value}" in
            true|false) js+=" w.writeConfig('${key}', ${value});" ;;
            *)          js+=" w.writeConfig('${key}', '${value}');" ;;
        esac
    done
    js+=" }"

    "${qdbus}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${js}" >/dev/null
}
