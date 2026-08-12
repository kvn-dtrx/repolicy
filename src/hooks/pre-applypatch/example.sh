#!/usr/bin/env sh

# ---
# description: >-
#   Example pre-applypatch hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git pre-applypatch hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example pre-applypatch hook"
log-info "no arguments"
exit 0
