#!/usr/bin/env sh

# ---
# description: >-
#   Fails when supplied paths name ignored files selected by an adapter
# ---

# ---

# NOTE: Repository-context adapters perform Git index inspection.

# ---

if [ "${#}" -gt 0 ]; then
    log-error "Ignored files found in the commit:" "$(printf '  %s\n' "${@}")" "If you really want to commit, run:" "  git commit --no-verify"
    exit 1
fi
