#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="${root}/src/wire/libexec/run-repolicy-catalog"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin"
export PATH="${tmp}/bin:${PATH}"
export TRACE="${tmp}/trace"
export REPOLICY_LIBEXEC="${root}/src/wire/libexec"

make_command() {
    local name="$1"
    local status="$2"
    {
        printf '%s\n' '#!/bin/sh'
        # The emitted code expands these values when the fake command runs.
        # shellcheck disable=SC2016
        printf '%s\n' 'printf "%s\n" "$(basename "$0")" >> "${TRACE}"'
        printf 'exit %s\n' "${status}"
    } > "${tmp}/bin/${name}"
    chmod +x "${tmp}/bin/${name}"
}

run_catalog() {
    local expected="$1"
    local catalog="$2"
    local actual=0
    "${runner}" pre-commit "${catalog}" > "${tmp}/output" 2>&1 || actual=$?
    if [ "${actual}" -ne "${expected}" ]; then
        printf 'expected status %s, got %s\n' "${expected}" "${actual}" >&2
        cat "${tmp}/output" >&2
        exit 1
    fi
}

make_command changed 3
make_command after-change 0
printf 'cli\tchanged\ncli\tafter-change\n' > "${tmp}/changed.tsv"
: > "${TRACE}"
run_catalog 3 "${tmp}/changed.tsv"
[ "$(paste -sd, "${TRACE}")" = 'changed,after-change' ]
grep -q 'commit stopped after all checks' "${tmp}/output"

make_command failed 1
make_command after-failure 0
printf 'cli\tfailed\ncli\tafter-failure\n' > "${tmp}/failed.tsv"
: > "${TRACE}"
run_catalog 1 "${tmp}/failed.tsv"
[ "$(paste -sd, "${TRACE}")" = 'failed' ]
grep -q 'Policy step failed' "${tmp}/output"

make_command clean 0
printf 'cli\tclean\n' > "${tmp}/clean.tsv"
: > "${TRACE}"
run_catalog 0 "${tmp}/clean.tsv"
[ "$(paste -sd, "${TRACE}")" = 'clean' ]

printf 'run-repolicy-catalog: ok\n'
