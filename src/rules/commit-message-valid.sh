#!/bin/bash

# ---
# description: >-
#   Checks whether the commit message is well formatted
# ---

# ---

# NOTE: Repository-context adapters supply one or more first-line messages.

# ---

TYPES=(
    "feat"
    "fix"
    "chore"
    "docs"
    "refactor"
    "style"
    "test"
    "wip"
    # "perf"
    # "ci"
    # "build"
    # "revert"
    # "security"
    # "ux"
    # "localization"
    # "meta"
)

TYPE_PATTERN="($(
    IFS="|"
    echo "${TYPES[*]}"
))"

# Full Conventional Commit regex
REGEX="^${TYPE_PATTERN}(\([a-zA-Z0-9_-]+\))?(!)?: .+"

for commit_msg in "${@}"; do
    if ! echo "${commit_msg}" | grep -Eq "${REGEX}"; then
        log-error "Invalid commit message format:" "  ${commit_msg}" "Commit message must follow Conventional Commits format:" "  <type>(optional-scope)!: description" "Allowed types are: ${TYPES[*]}"
        exit 1
    fi
done
