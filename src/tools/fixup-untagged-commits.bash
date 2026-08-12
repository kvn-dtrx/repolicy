#!/usr/bin/env bash

# ---
# description: >-
#   Fixups all commits between annotated tags into a single commit
# ---

# ---

set -o errexit
set -o nounset

BOT_NAME="Bot"
BOT_EMAIL="bot@invalid"
BRANCH_DST="main"
REPO_TMP_SUFFIX="_tmp"
REPO_DST_SUFFIX="_xxx"

repo_src_path="$(git rev-parse --show-toplevel)"
repo_tmp_path="${repo_src_path}${REPO_TMP_SUFFIX}"
repo_dst_path="${repo_src_path}${REPO_DST_SUFFIX}"

rm -rf "${repo_tmp_path}"
rm -rf "${repo_dst_path}"
git clone \
    --branch "${BRANCH_DST}" \
    --single-branch \
    "${repo_src_path}" \
    "${repo_tmp_path}"
cd "${repo_tmp_path}"

branch_tmp="__tmp__/fixup"
# Deletes the temporary branch if it exists
if git show-ref --verify --quiet "refs/heads/${branch_tmp}"; then
    git branch -D "${branch_tmp}"
fi

# Adds tag to initial commit if missing
initial_cmt="$(git rev-list --max-parents=0 HEAD)"
if ! git tag --points-at "${initial_cmt}" | grep -q .; then
    git tag -a v0.0.0 -m "Initial Commit" "${initial_cmt}"
fi

# Adds tag to current commit if missing
# NOTE: Perhaps it is better to tag all leaf commits
# or to prune after tags having no ancestor tag
current_cmt="$(git rev-parse HEAD)"
if ! git tag --points-at "${current_cmt}" | grep -q .; then
    git tag -a v9999.9999.9999 -m "Current Commit" "${current_cmt}"
fi

# Checks the very unlikely case that the current commit is the initial commit
if [ "${current_cmt}" == "${initial_cmt}" ]; then
    log-info "Current commit is the initial commit. Nothing to squash."
    exit 0
fi

# Gets all annotated tags sorted by date
tags=()
while IFS="" read -r line; do
    tags+=("${line}")
done < <(
    for tag in $(git tag --sort=creatordate); do
        # Check whether tag is annotated.
        if git tag -l "$tag" --format='%(taggername)' | grep -q .; then
            commit_date="$(git log -1 --format="%ct" "$tag")"
            echo "${commit_date} ${tag}"
        fi
    done | sort -n | awk '{print $2}'
)

# Precompute data in one array. Format follows:
# "tag_start|tag_end|author_date".
declare -a intervals=()
for ((i = 0; i < "${#tags[@]}" - 1; i++)); do
    start="${tags[i]}"
    end="${tags[i + 1]}"
    author_date="$(git log -1 --format='%aI' "${end}")"
    intervals+=("${start}|${end}|${author_date}")
done

# Starts a new branch at the oldest tag
git checkout -b "${branch_tmp}" "${tags[0]}"

# Iterates over all intervals and fixups the changes
for interval in "${intervals[@]}"; do
    IFS="|" read -r tag_start tag_end author_date <<< "${interval}"
    log-info "Squashing changes between ${tag_start} and ${tag_end}"
    git reset --hard "${tag_start}"
    git merge --squash "${tag_end}"
    git_env_vars=(
        GIT_AUTHOR_NAME="${BOT_NAME}"
        GIT_AUTHOR_EMAIL="${BOT_EMAIL}"
        GIT_AUTHOR_DATE="${author_date}"
    )
    cmt_msg_head="${tag_end} - ${tag_start}"
    if git diff --cached --quiet; then
        cmt_msg_tail=" == set()"
    else
        cmt_msg_tail=""
    fi
    cmt_msg="${cmt_msg_head}${cmt_msg_tail}"
    env "${git_env_vars[@]}" git commit --allow-empty -m "${cmt_msg}"
done > /dev/null

# Moves pointer of output branch and deletes the temporary branch
git checkout "${BRANCH_DST}"
git reset --hard "${branch_tmp}"

# Deletes all local branches except target branch.
for branch in $(git branch | sed 's/*//'); do
    if [ "${branch}" != "${BRANCH_DST}" ]; then
        git branch -D "${branch}"
    fi
done

# Deletes all local tags
git tag -l |
    xargs -r git tag -d

# Deletes all remote-tracking references
for ref in $(git for-each-ref --format="%(refname)" refs/remotes/); do
    log-info "Deleting ${ref}"
    git update-ref -d "${ref}"
done

# Expires all reflog entries immediately,
# removing history references to unreachable commits
git reflog expire --expire=now --all

# Runs garbage collection to permanently delete all unreachable
# objects (commits, trees, blobs)
git gc --prune=now --aggressive

# NOTE: Unreachable objects can be inspected using:
# ```shell
# git fsck --unreachable
# ```

# # Clones the repository only with manipulated branch to a new directory
# git clone \
#     --branch "${BRANCH_DST}" \
#     --single-branch \
#     "${repo_tmp_path}" \
#     "${repo_dst_path}"
