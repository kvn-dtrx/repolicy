#!/bin/bash

# ---
# description: >-
#   Checks supplied paths for portable file-name characters. Each segment may
#   use ASCII letters in any casing, digits, #, +, _, and -; dots separate
#   non-empty name parts or introduce a dotfile. A segment must not start '-'.
# ---

# ---

# NOTE: Repository-context adapters supply paths as arguments.
# NOTE: C locale keeps A-Z and a-z strictly ASCII on macOS Bash.

# ---

export LC_ALL=C

failed=0

# One path segment (directory or basename).
segment_ok() {
    local seg="$1"

    case "${seg}" in
        -*) return 1 ;;
    esac

    # One leading dot denotes a hidden name and is not part of the character
    # check. A second leading dot or an otherwise empty part remains invalid.
    case "${seg}" in
        .*) seg="${seg#.}" ;;
    esac
    [ -n "${seg}" ] || return 1

    [[ ${seg} =~ ^[A-Za-z0-9#+_][A-Za-z0-9#+_-]*(\.[A-Za-z0-9#+_][A-Za-z0-9#+_-]*)*$ ]]
}

path_ok() {
    local file="$1"
    local seg
    local rest

    rest="${file}"

    while [ -n "${rest}" ]; do
        case "${rest}" in
            */*)
                seg="${rest%%/*}"
                rest="${rest#*/}"
                ;;
            *)
                seg="${rest}"
                rest=""
                ;;
        esac
        [ -z "${seg}" ] && continue
        segment_ok "${seg}" || return 1
    done
    return 0
}

for file in "${@}"; do
    if ! path_ok "${file}"; then
        log-error "File name contains unsupported characters or begins with '-':" "  ${file}"
        failed=1
    fi
done

if [ "${failed}" -gt 0 ]; then
    log-error "Commit aborted."
    log-error "Allowed per path segment: ASCII letters in any casing, digits, #, +, _, -, and separating dots."
    log-error "Rejected: a leading '-', whitespace, other special characters, or empty dotted parts such as foo..md."
    exit 1
fi
