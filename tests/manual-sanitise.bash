#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin" "${tmp}/policy" "${tmp}/projects/one" "${tmp}/projects/two"
printf 'sanitiser\tsanitise-fixture\t--staged\n' > "${tmp}/policy/pre-commit.tsv"

for repository in one two; do
    git -C "${tmp}/projects/${repository}" init -q
    git -C "${tmp}/projects/${repository}" config repolicy.policyPath "${tmp}/policy"
    printf 'tracked\n' > "${tmp}/projects/${repository}/tracked file.txt"
    printf 'untracked\n' > "${tmp}/projects/${repository}/untracked.txt"
    printf 'ignored.txt\n' > "${tmp}/projects/${repository}/.gitignore"
    printf 'ignored\n' > "${tmp}/projects/${repository}/ignored.txt"
    git -C "${tmp}/projects/${repository}" add '.gitignore' 'tracked file.txt'
done

cat > "${tmp}/bin/sanitise-fixture" << 'EOF'
#!/bin/bash
[ "${1}" = --stdin0 ]
while IFS= read -r -d '' path; do
    printf '%s\t%s\n' "$(basename "${PWD}")" "${path}" >> "${TRACE}"
done
case "${FAIL_REPOSITORY:-}" in
    "$(basename "${PWD}")") exit 7 ;;
esac
exit 3
EOF
chmod +x "${tmp}/bin/sanitise-fixture"

export PATH="${tmp}/bin:${PATH}"
export TRACE="${tmp}/trace"
: > "${TRACE}"
if ! (
    cd "${tmp}/projects"
    "${root}/src/wire/bin/repolicy" sanitise
) > "${tmp}/output" 2>&1; then
    cat "${tmp}/output" >&2
    exit 1
fi

for repository in one two; do
    grep -Fqx "${repository}"$'\t''.gitignore' "${TRACE}"
    grep -Fqx "${repository}"$'\t''tracked file.txt' "${TRACE}"
    grep -Fqx "${repository}"$'\t''untracked.txt' "${TRACE}"
    if grep -Fqx "${repository}"$'\t''ignored.txt' "${TRACE}"; then
        exit 1
    fi
done
grep -q 'Processed repositories: 2' "${tmp}/output"

: > "${TRACE}"
status=0
FAIL_REPOSITORY=one \
    "${root}/src/wire/bin/repolicy" sanitise "${tmp}/projects" \
    > "${tmp}/output" 2>&1 || status=$?
[ "${status}" -eq 1 ]
grep -Fq $'two\ttracked file.txt' "${TRACE}"
grep -q 'failures: 1' "${tmp}/output"

printf 'manual sanitation: ok\n'
