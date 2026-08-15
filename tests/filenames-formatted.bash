#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rule="${root}/src/rules/filenames-formatted.bash"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin"
{
    printf '%s\n' '#!/bin/sh'
    # The emitted command expands these values when the fake logger runs.
    # shellcheck disable=SC2016
    printf '%s\n' 'printf "%s\n" "$*" >> "${ERROR_LOG}"'
} > "${tmp}/bin/log-error"
chmod +x "${tmp}/bin/log-error"
export PATH="${tmp}/bin:${PATH}"
export ERROR_LOG="${tmp}/errors"

valid=(
    'src/youtube/yEk5GTbqKXk/concept.tex'
    'README.md'
    '.github/workflows/CI-Test.YAML'
    '.mtdt.yaml'
    'src/C++/C#_Parser-2/file_NAME.TEX'
    'a/b-/c+d#e_f'
)
"${rule}" "${valid[@]}"

invalid=(
    'white space.txt'
    '-leading.txt'
    'path/-leading'
    'semi;colon.txt'
    'umlaut-ä.txt'
    'foo..bar'
    'trailing.'
    '.-hidden'
    '.'
)

for candidate in "${invalid[@]}"; do
    exit_code=0
    "${rule}" "${candidate}" || exit_code=$?
    if [ "${exit_code}" -ne 1 ]; then
        printf 'expected rejection for %s, got status %s\n' \
            "${candidate}" "${exit_code}" >&2
        exit 1
    fi
done

printf 'filenames-formatted: ok\n'
