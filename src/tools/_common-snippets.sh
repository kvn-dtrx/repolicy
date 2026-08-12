# shellcheck disable=all

# ---
# description: >-
#   Runs common snippets
# ---

# ---

# NOTE: Prefer log-info / log-warn / log-error from src/wire/libexec when adapting real tools.

# Checks whether the script is executed as root
[ "$(id -u)" -ne 0 ] && {
    printf "Run this script as root" >&2
    exit 1
}

# ---

# Triggers exit if a command has a non-zero code.
set -o errexit # or set -e
# NOTE: Of course, failed conditionals of if or while clauses are not affected
# NOTE: The POSIX standard does not prescribe how `errexit` shall behave for
# non-zero exit codes from process substitutions; to be on the safe side,
# append `|| exit 1`

# ---

# Triggers exit if an unset variable is read
set -o nounset # or set -u
# NOTE: Empty variables are not unset!

# ---

# Sets the exit code of a pipe to the first non-zero code of a constituent
# if present; otherwise, zero is returned
set -o pipefail
# NOTE: By default, the exit code of a pipe equals the exit code of
# its last constituent
# NOTE: This option is not POSIX-compliant

# ---

# NOTE: The command `set -o` lists all available option
# plus their current values

# ---

# We now assume that `errexit` and `nounset` are true.

# Sets environment variables—with uppercased identifiers, of course
FOO="bar"
BAZ="42"

# ---

# Switches to parent directory of the current script
# NOTE: realpath is not POSIX-compliant
script="$(realpath "${0}")"
script_name="$(basename "${script%.*}")"
script_dir="$(dirname "${script}")"

# ---

# Logs begin of a run
printf "☝️ BEG: %s\n" "${script_name}"

# Promises to log the end of a failed run
trap 'printf "\n👎 END: %s\n" "${script_name}"' INT TERM

# Logs end of a successful run
printf "👍 END: %s\n" "${script_name}"

# ---

cd "${script_dir}"
# Switches to the repository root the script is subordinate to
project_dir="$(git rev-parse --show-toplevel)"

# ---

# Creates an application related temporary directory
tmp_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
mkdir -p "${tmp_dir}"
tmp_stem="${script_name}.$(date "+%Y%m%d-%H%M%S")"
tmp_dir="$(mktemp -d "${tmp_dir}/${tmp_stem}.XXXXXXX")"

# NOTE: We adhere to the convention of using XXXXXXX as prefix length—seven times X!

# Removes the temporary directory associated with the
# current run of the script
trap 'rm -rf -- "${tmp_dir}"' EXIT INT TERM

# ---

# Creates an application related state directory
parent_state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/${script_name}"
mkdir -p "${parent_state_dir}"
state_stem="$(date "+%y%m%d-%H%M%S")"
state_dir="$(
    mktemp -d "${parent_state_dir}/${state_stem}.XXXXXXX"
)"
# NOTE: mktemp does not create missing parents

# ---

# Checks for the correct number of passed arguments
[ "${#}" -eq 1 ] || {
    printf "Please specify exactly one argument\n" >&2
    exit 1
}

# ---

cd "${project_dir}"
# Provides current directory as argument if no arguments are given
set -- "${@:-.}"

# ---

# Finds all (including symlinked) files that are not subordinate
# to a hidden directory.
find -L "${@}" \
    \( -type d -path "*/.*" -prune \) -o \
    \( -type f -print \)

# ---

# Logs the directory or file that is currently processed
printf "🪣 Processing: %s\n" "DIRECTORY/FILE"
