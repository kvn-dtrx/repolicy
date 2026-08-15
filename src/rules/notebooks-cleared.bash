#!/bin/bash

# ---
# description: >-
#   Checks whether output cells of supplied iPy notebooks are cleared
# ---

# ---

# NOTE: Intended as a git pre-commit hook

# ---

failed=0

for notebook in "${@}"; do
    case "${notebook}" in
        *.ipynb) ;;
        *) continue ;;
    esac
    [ -f "${notebook}" ] || continue
    if [ -n "$(jq '.cells[] | select(.outputs | length > 0)' "${notebook}")" ]; then
        if [ "${failed}" -eq 0 ]; then
            log-info "Notebooks with uncleared output cells:"
        fi
        log-info "  ${notebook}"
        failed=1
    fi
done

if [ "${failed}" -gt 0 ]; then
    log-error "Some notebooks have uncleared output cells." "If you really want to commit, run:" "  git commit --no-verify"
    exit 1
else
    log-info "All notebook output cells are cleared."
fi
