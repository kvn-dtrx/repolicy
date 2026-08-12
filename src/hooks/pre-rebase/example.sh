#!/usr/bin/env sh

# ---
# description: >-
#   Example pre-rebase hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git pre-rebase hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example pre-rebase hook"
log-info "upstream: $1"
if [ -n "$2" ]; then
    log-info "branch being rebased: $2"
fi
exit 0
