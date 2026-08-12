#!/usr/bin/env sh

# ---
# description: >-
#   Example post-applypatch hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git post-applypatch hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example post-applypatch hook"
log-info "no arguments"
exit 0
