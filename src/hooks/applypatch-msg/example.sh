#!/usr/bin/env sh

# ---
# description: >-
#   Example applypatch-msg hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git applypatch-msg hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example applypatch-msg hook"
log-info "commit message file: $1"
exit 0
