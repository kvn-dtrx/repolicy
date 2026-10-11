#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin" "${tmp}/runtime"
ln -s "${root}/src/actions" "${tmp}/runtime/actions"
ln -s "${root}/src/wire/libexec/log-error" "${tmp}/runtime/log-error"
cat > "${tmp}/bin/infer-fixture" << 'EOF'
#!/bin/sh
printf 'called\n' >> "${TRACE}"
printf 'feat: infer final staged change\n'
EOF
chmod +x "${tmp}/bin/infer-fixture"
export PATH="${tmp}/bin:${PATH}"
export TRACE="${tmp}/trace"

message="${tmp}/message"
printf '# Conventional Commit Format\n' > "${message}"
: > "${TRACE}"
REPOLICY_LIBEXEC="${tmp}/runtime" \
    "${root}/src/adapters/git-hooks/run-action" \
    prepare-commit-msg generate-commit-message.sh infer-fixture \
    -- "${message}" template
grep -Fqx 'feat: infer final staged change' "${message}"
grep -Fqx '# Conventional Commit Format' "${message}"
[ "$(wc -l < "${TRACE}" | tr -d ' ')" -eq 1 ]

printf 'fix: supplied message\n' > "${message}"
: > "${TRACE}"
REPOLICY_LIBEXEC="${tmp}/runtime" \
    "${root}/src/adapters/git-hooks/run-action" \
    prepare-commit-msg generate-commit-message.sh infer-fixture \
    -- "${message}" message
grep -Fqx 'fix: supplied message' "${message}"
[ ! -s "${TRACE}" ]

mkdir -p "${tmp}/hooks" "${tmp}/policy" "${tmp}/repo"
ln -s "${root}/src/adapters/git-hooks/entry/pre-commit" \
    "${tmp}/hooks/pre-commit"
ln -s "${root}/src/adapters/git-hooks/entry/prepare-commit-msg" \
    "${tmp}/hooks/prepare-commit-msg"
ln -s "${root}/src/wire/libexec/run-repolicy-catalog" \
    "${tmp}/run-repolicy-catalog"
ln -s "${root}/src/adapters" "${tmp}/adapters"
ln -s "${root}/src/actions" "${tmp}/actions"
for logger in log-debug log-error log-info log-star log-warn; do
    ln -s "${root}/src/wire/libexec/${logger}" "${tmp}/${logger}"
done

cat > "${tmp}/bin/sanitise-fixture" << 'EOF'
#!/bin/sh
grep -Fqx 'sanitised' item.txt && exit 0
printf 'sanitised\n' >> item.txt
exit 3
EOF
chmod +x "${tmp}/bin/sanitise-fixture"
printf 'sanitiser\tsanitise-fixture\n' > "${tmp}/policy/pre-commit.tsv"
printf 'action\tgenerate-commit-message.sh\tinfer-fixture\n' \
    > "${tmp}/policy/prepare-commit-msg.tsv"

git -C "${tmp}/repo" init -q
git -C "${tmp}/repo" config user.name 'Repolicy Test'
git -C "${tmp}/repo" config user.email 'repolicy@example.invalid'
git -C "${tmp}/repo" config commit.gpgsign false
git -C "${tmp}/repo" config core.hooksPath "${tmp}/hooks"
git -C "${tmp}/repo" config repolicy.policyPath "${tmp}/policy"
printf 'original\n' > "${tmp}/repo/item.txt"
git -C "${tmp}/repo" add item.txt
: > "${TRACE}"

status=0
GIT_EDITOR=true git -C "${tmp}/repo" commit > "${tmp}/first-output" 2>&1 ||
    status=$?
[ "${status}" -ne 0 ]
grep -q 'Policy steps modified files' "${tmp}/first-output" || {
    cat "${tmp}/first-output" >&2
    exit 1
}
[ ! -s "${TRACE}" ]

git -C "${tmp}/repo" add item.txt
status=0
GIT_EDITOR=true git -C "${tmp}/repo" commit > "${tmp}/second-output" 2>&1 ||
    status=$?
if [ "${status}" -ne 0 ]; then
    cat "${tmp}/second-output" >&2
    exit "${status}"
fi
[ "$(wc -l < "${TRACE}" | tr -d ' ')" -eq 1 ]
[ "$(git -C "${tmp}/repo" log -1 --format=%s)" = \
    'feat: infer final staged change' ]

printf 'prepare-commit-msg: ok\n'
