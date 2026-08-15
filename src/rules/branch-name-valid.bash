#!/bin/bash

# ---
# description: >-
#   Checks whether the branch name is well formatted
# ---

# ---

# NOTE: Repository-context adapters supply the branch name as the first argument.

# ---

permanent_branch_pattern="^(infallible|main|master|untouchable)$"

topic_branch_pattern=""
topic_branch_pattern+="^"
topic_branch_pattern+="("
topic_branch_pattern+="bugfix\/|"
topic_branch_pattern+="dev\/|"
topic_branch_pattern+="docs\/|"
topic_branch_pattern+="experimental\/|"
topic_branch_pattern+="feature\/|"
topic_branch_pattern+="hotfix\/|"
topic_branch_pattern+="release\/|"
topic_branch_pattern+="test\/|"
topic_branch_pattern+="\/\/\/"
topic_branch_pattern+=")"
topic_branch_pattern+="[a-z0-9_-]+"
topic_branch_pattern+="$"

branch_name="${1:?usage: branch-name-valid.bash <branch-name>}"

if ! printf "%s\n" "${branch_name}" | grep -E -q \
    -e "${permanent_branch_pattern}" \
    -e "${topic_branch_pattern}"; then
    log-error \
        "Branch name is not well formatted:" \
        "  ${branch_name}" \
        "Branch names should match one of the regexps:" \
        "  ${permanent_branch_pattern}" \
        "  ${topic_branch_pattern}" \
        "Please stick to this convention next time."
    exit 1
fi
