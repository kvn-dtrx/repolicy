#!/usr/bin/env sh

# ---
# description: >-
#   Checks whether a supplied branch is protected
# ---

# ---

# NOTE: Repository-context adapters supply the branch as the first argument.

# ---

pb="${pb} main"
pb="${pb} master"
pb="${pb} untouchable"
pb="${pb} infallible"

protected_branches="${pb}"
current_branch="${1:?usage: pushes-to-protected-branch.sh <branch-name>}"

for protected_branch in ${protected_branches}; do
    if [ "${current_branch}" = "${protected_branch}" ]; then
        log-error "Push to ${current_branch} is very like not what you want!"
        exit 1
    fi
done
