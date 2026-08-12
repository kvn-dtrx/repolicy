#!/usr/bin/env sh

# ---
# description: >-
#   Example prepare-commit-msg hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git prepare-commit-msg hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example prepare-commit-msg hook"
log-info "commit message file: $1"
log-info "source: $2"
if [ -n "$3" ]; then
    log-info "commit SHA (amend): $3"
fi
exit 0
