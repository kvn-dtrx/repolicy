#!/usr/bin/env sh

# ---
# description: >-
#   Example post-checkout hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git post-checkout hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example post-checkout hook"
log-info "previous HEAD: $1"
log-info "new HEAD: $2"
log-info "flag (1=branch checkout, 0=file checkout): $3"
exit 0
