#!/usr/bin/env sh

# ---
# description: >-
#   Checks whether a commit contains ignored files
# ---

# ---

# NOTE: Intended as a git pre-commit hook

# ---

ignored_files="$(
    git status --ignored --porcelain |
        awk '/^!!/ {print $2}' |
        xargs git diff --cached --name-only
)"

if [ -n "${ignored_files}" ]; then
    log-error "Ignored files found in the commit:" "  ${ignored_files}" "If you really want to commit, run:" "  git commit --no-verify"
    exit 1
fi
