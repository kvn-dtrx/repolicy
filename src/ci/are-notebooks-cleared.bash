#!/usr/bin/env bash

# ---
# description: >-
#   Checks whether output cells of all iPy notebooks are cleared
# ---

# ---

# NOTE: Script is intended to be run as GitHub workflow on pull requests

# ---

failed=0

if [ -z "${BASE_SHA:-}" ] || [ -z "${HEAD_SHA:-}" ]; then
    log-error "BASE_SHA and HEAD_SHA must be set." "Perhaps the script is not run in the context of a pull request?"
    exit 1
fi

log-info "Notebook with uncleared output cells:"

while IFS="" read -r notebook; do
    if [ -n "$(jq '.cells[] | select(.outputs | length > 0)' "${notebook}")" ]; then
        log-info "  ${notebook}"
        failed=1
    fi
    # It must be ensured that the while loop runs in the main shell,
    # otherwise changes to the failed variable would be restricted to subshells!.
done < <(
    git diff --name-only --diff-filter=AM -z "${BASE_SHA}" "${HEAD_SHA}" |
        grep -z '\.ipynb$' || :
)

if [ "${failed}" -gt 0 ]; then
    log-warn "Some notebooks have uncleared output cells." "Please check if this is intended."
    exit 1
else
    log-info "None! No notebook with uncleared output cells found."
fi
