#!/usr/bin/env sh

# ---
# description: >-
#   Example post-merge hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git post-merge hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example post-merge hook"
log-info "squash merge flag (1=squash, 0=otherwise): $1"
exit 0
