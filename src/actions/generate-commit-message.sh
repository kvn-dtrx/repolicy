#!/bin/sh

# ---
# description: Populates an empty ordinary Git commit message after pre-commit
# ---

set -eu

message_file="${1:?message-file argument required}"
message_source="${2:-}"
generator="${3:-git-synth-message}"

# Preserve explicit, merge, squash, and reused commit messages. A configured
# commit template is still an ordinary commit and may receive a generated line.
case "${message_source}" in
    '' | template) ;;
    *) exit 0 ;;
esac

comment_char="$(git config --get core.commentChar 2> /dev/null || true)"
case "${comment_char}" in
    '' | auto) comment_char='#' ;;
esac

# Never overwrite substantive text already present in the editor buffer.
if awk -v comment="${comment_char}" '
    /^[[:space:]]*$/ { next }
    index($0, comment) == 1 { next }
    { found = 1; exit }
    END { exit found ? 0 : 1 }
' "${message_file}"; then
    exit 0
fi

generated="$(mktemp)"
combined="$(mktemp)"
cleanup() {
    rm -f "${generated}" "${combined}"
}
trap cleanup EXIT HUP INT TERM

"${generator}" > "${generated}"
if ! grep -q '[^[:space:]]' "${generated}"; then
    printf 'Commit-message generator produced no message: %s\n' "${generator}" >&2
    exit 1
fi

{
    cat "${generated}"
    printf '\n\n'
    cat "${message_file}"
} > "${combined}"
mv "${combined}" "${message_file}"
