#!/usr/bin/env sh

# ---
# description: >-
#   Example sendemail-validate hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git sendemail-validate hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example sendemail-validate hook"
log-info "args: $*"
exit 0
