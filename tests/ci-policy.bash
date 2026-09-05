#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

root="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="${root}/src/adapters/ci/run-policy"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

git -C "${tmp}" init -q
git -C "${tmp}" config user.email test@example.invalid
git -C "${tmp}" config user.name Test
git -C "${tmp}" config core.hooksPath /dev/null
git -C "${tmp}" config commit.gpgsign false
printf 'clean\n' > "${tmp}/README.md"
git -C "${tmp}" add README.md
git -C "${tmp}" commit -qm 'init: start test repository'
base_sha="$(git -C "${tmp}" rev-parse HEAD)"
printf 'cleaner\n' > "${tmp}/README.md"
git -C "${tmp}" commit -qam 'test: exercise CI policy'
head_sha="$(git -C "${tmp}" rev-parse HEAD)"

export REPOLICY_CI_PROVIDER=github
export REPOLICY_EVENT=pull_request
export REPOLICY_BRANCH=dev/ci-policy
export REPOLICY_BASE_SHA="${base_sha}"
export REPOLICY_HEAD_SHA="${head_sha}"

(
    cd "${tmp}"
    "${runner}"
)

export REPOLICY_BRANCH='bad branch'
status=0
(
    cd "${tmp}"
    "${runner}"
) > /dev/null 2>&1 || status=$?
[ "${status}" -ne 0 ]

printf 'ci-policy: ok\n'
