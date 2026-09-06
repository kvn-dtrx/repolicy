#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin" "${tmp}/repo/.git/info" "${tmp}/runtime/rules"
git -C "${tmp}/repo" init -q
git -C "${tmp}/repo" config user.email test@example.invalid
git -C "${tmp}/repo" config user.name Test
printf 'print("test")\n' > "${tmp}/repo/example.py"
printf '*.py repolicy-sanitise=python\n' > "${tmp}/repo/.git/info/attributes"
git -C "${tmp}/repo" add example.py

cat > "${tmp}/bin/sanitise-python" << 'EOF'
#!/bin/bash
[ "${1}" = "--stdin0" ]
while IFS= read -r -d '' path; do
    printf '%s\n' "${path}" >> "${TRACE}"
done
EOF
chmod +x "${tmp}/bin/sanitise-python"

export PATH="${tmp}/bin:${root}/src/wire/libexec:${PATH}"
export REPOLICY_LIBEXEC="${root}/src/wire/libexec"
export TRACE="${tmp}/trace"
(
    cd "${tmp}/repo"
    "${root}/src/adapters/git-hooks/run-attribute" \
        pre-commit repolicy-sanitise --
)

[ "$(cat "${TRACE}")" = "example.py" ]

printf 'print("untracked")\n' > "${tmp}/repo/untracked.py"
printf 'example.py\0untracked.py\0' > "${tmp}/all-paths"
: > "${TRACE}"
(
    export REPOLICY_PATHS_FILE="${tmp}/all-paths"
    cd "${tmp}/repo"
    "${root}/src/adapters/git-hooks/run-attribute" \
        pre-commit repolicy-sanitise --
)
[ "$(paste -sd, "${TRACE}")" = "example.py,untracked.py" ]

printf '*.rs repolicy-sanitise=rust\n' > "${tmp}/repo/.git/info/attributes"
(
    cd "${tmp}/repo"
    "${root}/src/adapters/git-hooks/run-attribute" \
        pre-commit repolicy-sanitise --
)

printf '*.txt repolicy-check=staged-content\n' > "${tmp}/repo/.git/info/attributes"
printf 'staged\n' > "${tmp}/repo/example.txt"
git -C "${tmp}/repo" add example.txt
printf 'working tree\n' > "${tmp}/repo/example.txt"
cat > "${tmp}/runtime/rules/staged-content.bash" << 'EOF'
#!/bin/sh
[ "$(cat "${1}")" = "staged" ]
EOF
chmod +x "${tmp}/runtime/rules/staged-content.bash"
export REPOLICY_LIBEXEC="${tmp}/runtime"
(
    cd "${tmp}/repo"
    "${root}/src/adapters/git-hooks/run-attribute" \
        pre-commit repolicy-check --
)

printf 'attribute dispatch: ok\n'
