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
