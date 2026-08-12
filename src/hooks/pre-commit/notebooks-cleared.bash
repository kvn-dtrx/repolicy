#!/bin/bash

# ---
# description: >-
#   Checks whether output cells of all iPy notebooks are cleared
# ---

# ---

# NOTE: Intended as a git pre-commit hook

# ---

failed=0

log-info "Notebook with uncleared output cells:"

while IFS="" read -r -d "" notebook; do
    if [ -n "$(jq '.cells[] | select(.outputs | length > 0)' "$notebook")" ]; then
        log-info "  ${notebook}"
        failed=1
    fi
done < <(
    git diff --name-only --cached |
        grep -z '\.ipynb$' ||
        true
)

if [ "${failed}" -gt 0 ]; then
    log-error "Some notebooks have uncleared output cells." "If you really want to commit, run:" "  git commit --no-verify"
    exit 1
else
    log-info "None! No notebook with uncleared output cells found."
fi
