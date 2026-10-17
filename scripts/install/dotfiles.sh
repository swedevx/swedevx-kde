#!/usr/bin/env bash
#
# dotfiles.sh — copies the config files of every component the user chose.
# Must run after the other phases, which record the selections.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DOTFILES_DIR="${REPO_ROOT}/dotfiles"

# copy_component NAME
#
# Copies every file under dotfiles/NAME/ to the same relative path in $HOME.
# Identical files are skipped. A differing file is backed up first
# (name.~1~, name.~2~, ...), so a re-run never destroys local edits.
copy_component() {
    local src="${DOTFILES_DIR}/$1"
    local file rel dest

    while IFS= read -r -d '' file; do
        rel="${file#"${src}/"}"
        dest="${HOME}/${rel}"

        if [[ -f "${dest}" ]] && cmp -s "${file}" "${dest}"; then
            continue
        fi

        mkdir -p "$(dirname "${dest}")"
        cp --backup=numbered "${file}" "${dest}"
        log_ok "Copied ${rel}"
    done < <(find "${src}" -type f -print0)
}

# install_dotfiles
#
# Walks dotfiles/ and copies each component that is selected.
install_dotfiles() {
    local dir component

    for dir in "${DOTFILES_DIR}"/*/; do
        [[ -d "${dir}" ]] || continue
        component="$(basename "${dir}")"

        if is_selected "${component}"; then
            log_info "Copying dotfiles for ${component}..."
            copy_component "${component}"
        else
            log_info "Skipping dotfiles for ${component} (not selected)."
        fi
    done
}

main() {
    install_dotfiles
}

main "$@"
