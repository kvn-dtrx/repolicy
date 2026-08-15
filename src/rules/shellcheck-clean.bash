#!/bin/bash

# ---
# description: >-
#   Runs ShellCheck on supplied *.sh / *.bash / *.zsh files (paradigmata flags)
# ---

# ---

# NOTE: Repository-context adapters supply paths as arguments.
# NOTE: Flags match paradigmata share/conventions/shell.md

# ---

if ! command -v shellcheck > /dev/null 2>&1; then
    log-warn "shellcheck not found; skipping"
    exit 0
fi

files=()
for file in "${@}"; do
    case "${file}" in
        *.sh | *.bash | *.zsh) ;;
        *) continue ;;
    esac
    [ -f "${file}" ] || continue
    files+=("${file}")
done

if [ "${#files[@]}" -eq 0 ]; then
    exit 0
fi

log-info "ShellCheck:" "${files[@]}"

if ! shellcheck --exclude=SC1103 --shell=bash -- "${files[@]}"; then
    log-error "ShellCheck failed." \
        "Fix findings, or silence intentionally with:" \
        "  # shellcheck disable=SCxxxx  # reason" \
        "See paradigmata share/conventions/shell.md"
    exit 1
fi
