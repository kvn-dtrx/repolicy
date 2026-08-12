#!/bin/bash

# ---
# description: >-
#   Checks whether names of committed files fulfill the following
#   formatting rules: - No whitespace. - No uppercase characters. Intended
#   as a git pre-commit hook
# ---

# ---

failed=0

while IFS="" read -r -d "" file; do
    # Check for whitespace in the filename
    printf "%s\n" "${file}" | grep -E -q "[[:space:]]|[A-Z]" && {
        log-error "File name with white spaces or uppercase characters found:" "  ${file}"
        failed=1
    }
    # It must be ensured that the while loop runs in the main shell,
    # otherwise changes to the failed variable would be restricted to subshells!.
    # done < <(git diff --cached --name-only -z)
done < <(git diff --name-only origin/main HEAD)

if [ "${failed}" -gt 0 ]; then
    log-error "Commit aborted."
    exit 1
fi
