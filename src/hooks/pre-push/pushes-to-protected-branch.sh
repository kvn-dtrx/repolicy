#!/usr/bin/env sh

# ---
# description: >-
#   Checks whether the push operation targets a protected branch
# ---

# ---

# NOTE: Script is intended to be run as git pre-push hook

# ---

pb="${pb} main"
pb="${pb} master"
pb="${pb} untouchable"
pb="${pb} infallible"

protected_branches="${pb}"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

for protected_branch in ${protected_branches}; do
    if [ "${current_branch}" = "${protected_branch}" ]; then
        log-error "Push to ${current_branch} is very like not what you want!"
        exit 1
    fi
done
