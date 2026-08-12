#!/usr/bin/env bash

# ---
# description: >-
#   Derives a single-commit version of a repository with GitHub origin
#   path and pushes it to GitHub
# ---

# ---

set -o errexit
set -o nounset

SRC_REPO="${1}"
PUB_SUFFIX="_pub"

# tmp_dir="$(mktemp -d)"
tmp_dir="${HOME}/Downloads/foo"
rm -rf "${tmp_dir}"

[ -n "${SRC_REPO}" ] || {
    log-error "First argument not provided"
    exit 1
}

git clone "${SRC_REPO}" "${tmp_dir}"

cd "${tmp_dir}"

src_origin_url="$(
    git -C "${SRC_REPO}" remote get-url origin
)"
src_repo_name="$(basename -s .git "${src_origin_url}")"
default_branch="main"
username="$(
    printf "%s" "${src_origin_url}" |
        sed -E -e "s#.*github\.com[:/](.+?)/.*#\1#"
)"
dst_repo_name="${src_repo_name}${PUB_SUFFIX}"
dst_url="git@github.com:${username}/${dst_repo_name}.git"

# Extracts the tree SHA of the commit.
tree_sha="$(
    git rev-parse "origin/${default_branch}^{tree}"
)"

# Creates a new commit with that tree and no parent.
commit_msg="init: Create Clean Snapshot @ $(gdate "+%Y-%m-%dT%H:%M:%S")"
new_commit_sha="$(
    echo "${commit_msg}" |
        git commit-tree "${tree_sha}"
)"

# Lets main branch point to this new commit.
# Since we are on ${default_branch}, git demands detaching first.
git checkout --detach
git branch -f "${default_branch}" "${new_commit_sha}"
git switch "${default_branch}"

git remote set-url origin "${dst_url}"

# Checks if origin really was changed as we will force push!
current_origin_url="$(git remote get-url origin)"
[ "${current_origin_url}" = "${dst_url}" ] || {
    log-error \
        "Remote origin URL mismatch." \
        "Expected:" \
        "  ${dst_url}" \
        "Actual:" \
        "  ${current_origin_url}" \
        "Aborting to avoid accidental force-push to wrong remote."
    exit 1
}

if ! gh repo view "${username}/${dst_repo_name}" > /dev/null 2>&1; then
    gh repo create "${username}/${dst_repo_name}" --public
fi

git push --force origin "${default_branch}"
