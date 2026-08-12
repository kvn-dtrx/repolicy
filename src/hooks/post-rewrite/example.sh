#!/usr/bin/env sh

# ---
# description: >-
#   Example post-rewrite hook: logs invocation and arguments, then exits successfully
# ---

# ---

# NOTE: Script is an example stub for a git post-rewrite hook
# NOTE: Replace or extend before enabling in a dispatcher

# ---

log-info "example post-rewrite hook"
log-info "command: $1"
log-info "stdin may contain rewrite pairs (old SHA new SHA per line):"
while IFS= read -r line || [ -n "$line" ]; do
    log-info "  $line"
done
exit 0
