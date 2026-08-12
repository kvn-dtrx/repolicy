#!/usr/bin/env sh

# ---
# description: >-
#   Formats the commit message by removing leading and trailing
#   whitespaces
# ---

# ---

# NOTE: Script is intended to be run as git commit-msg hook

# ---

# File containing the commit message.
commit_msg_file="${1}"

# Detect the sed version or operating system
if sed --version > /dev/null 2>&1; then
    # GNU sed (Linux)
    sedi() {
        sed -i "${@}"
    }
else
    # BSD sed (macOS)
    sedi() {
        sed -i "" "${@}"
    }
fi

# Remove leading whitespaces in the first line if necessary.
if head -n 1 "${commit_msg_file}" | grep -q "^[[:space:]]"; then
    sedi '1s/^[[:space:]]*//' "${commit_msg_file}"
    log-info "Leading whitespace removed from the first message line."
fi

# Remove trailing whitespaces if necessary.
if grep -q "[[:space:]]$" "${commit_msg_file}"; then
    sedi 's/[[:space:]]*$//' "${commit_msg_file}"
    log-info "Trailing whitespace removed."
fi
