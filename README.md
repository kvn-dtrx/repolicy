---
title: Repolicy
---

# Repolicy

## Synopsis

Repolicy defines repository policies once and enforces them through Git hooks
and CI. Rules receive explicit values or paths; adapters translate execution
contexts such as the Git index or a GitHub pull request into those inputs.

Repolicy is optional. Pointing `core.hooksPath` at its conventional installation
path is safe even when Repolicy is absent: Git simply finds no hooks. Installing
Repolicy without policy TSVs is also inert.

## Architecture

```text
repolicy/
├── src/
│   ├── rules/                       # context-independent validations
│   ├── actions/                     # explicit mutations, kept separate
│   ├── wire/bin/                    # manual `repolicy` command
│   ├── adapters/
│   │   ├── git-hooks/
│   │   │   ├── entry/               # core.hooksPath entry points
│   │   │   ├── run-rule
│   │   │   └── run-action
│   │   ├── ci/                       # forge-neutral CI runner and contexts
│   │   └── github-actions/           # compatibility entry points
│   └── wire/libexec/                # catalog runner and log helpers
├── config/ci.tsv                     # default forge-neutral CI policy
├── .github/workflows/               # reusable GitHub workflow
├── templates/repolicy.yml           # reusable GitLab CI component
├── .gitlab-ci.yml                    # exercises the component on GitLab
├── .github/workflow-templates/      # small caller examples
├── config/wire.ini
└── Makefile
```

The boundary is deliberate:

- Rules validate repository state and are safe to run repeatedly.
- Actions may modify immediate working inputs, such as a commit-message file.
- Adapters discover context; rules never guess whether they are running in a
  hook, a pull request, or another CI system.
- History rewriting, publishing, repository creation, and force-pushing are Git
  maintenance tools, not Repolicy responsibilities.

## Installation

Run:

```sh
make install
```

This installs the `repolicy` command below `~/.local/bin/` and the runtime below
`~/.local/libexec/repolicy/`, including `rules/`, `actions/`, `adapters/`, and
`git-hooks/`. `MY_LOCAL_HOME` overrides `~/.local`.

Configure Git, typically through Dotfiles:

```gitconfig
[core]
    hooksPath = ~/.local/libexec/repolicy/git-hooks

[repolicy]
    policyPath = ~/.config/repolicy
```

Project-local executable hooks under `.git/hooks/` take precedence when a
Repolicy entry hook finds one.

## Git-hook policy

Policy consists of one TSV catalog per Git event, for example
`~/.config/repolicy/pre-commit.tsv`:

```text
# kind  target                         args
sanitiser sanitise-shell               --staged
rule    filenames-formatted.bash
cli     check-shell                    --staged
cli     check-python                   --staged
attribute repolicy-sanitise
```

Supported row kinds:

| Kind | Meaning |
| --- | --- |
| `cli` | Run an external command with the configured arguments. Missing commands are skipped with a warning. |
| `sanitiser` | Run a mutating CLI; as `cli`, but also eligible for deliberate manual sanitation. |
| `rule` | Run a shared Repolicy rule through the Git adapter. |
| `action` | Run an explicitly mutating Repolicy action through the Git adapter. |
| `attribute` | Dispatch staged paths according to a local Git attribute. |

The `repolicy-sanitise` and `repolicy-check` attributes are normally kept in
the unversioned `.git/info/attributes`, allowing private path policy without
changing a shared repository.

Missing catalogs are empty policies. A catalog that names an unavailable rule
or action is a broken installation and fails visibly.

`filenames-formatted.bash` permits ASCII letters in arbitrary casing, digits,
`#`, `+`, `_`, and `-` within each path segment. Dots may introduce a hidden
name or separate non-empty name parts. Segments beginning with `-`, whitespace,
and other special characters are rejected.

### Step exit contract

Every catalog step uses a four-state exit contract:

| Status | Meaning | Catalog behaviour |
| --- | --- | --- |
| `0` | Successful, no mutation | Continue |
| `3` | Files were changed | Continue all remaining steps, then reject the Git operation |
| `4` | Checker reported findings | Continue all remaining steps, then reject the Git operation |
| Any other non-zero status | Fatal validation or execution failure | Stop immediately with that status |

The dedicated statuses distinguish expected checker findings and formatter
mutations from broken policy execution. Repolicy runs all checks after either
status, then reports every applicable summary. Findings (`4`) take precedence
over changes (`3`) when both occur; fatal failures still stop immediately.

## Manual sanitation

The mutating portion of the pre-commit policy may be run without staging or
committing anything:

```sh
repolicy sanitise
repolicy sanitise ~/data/projects
repolicy sanitise --no-recursive ~/data/projects/example
```

By default the command starts at the current working directory, or at the
directories supplied as arguments, and recursively discovers every Git work
tree below them, including linked worktrees. `--no-recursive` restricts each
argument to the work tree containing it. The command continues after a failure
so that all repositories are visited. It applies the catalog's `sanitiser` rows
and its `repolicy-sanitise` attribute to every tracked and untracked,
non-ignored regular file. Nested repositories are treated independently. A
successful run exits with zero even when files were modified; actual execution
failures produce a non-zero status.

## GitHub Actions and GitLab CI

The default CI policy is declared once in `config/ci.tsv`. Its columns are a
repository scope (`branch`, `commits`, `tracked`, `changed`, or `repository`),
a rule, and optional tab-separated arguments. `src/adapters/ci/run-policy`
obtains normalized branch and revision information from the current forge and
supplies the selected repository data to the shared rule.

GitHub repositories call `.github/workflows/repolicy.yaml` as a reusable
workflow. GitLab repositories include the component in
`templates/repolicy.yml`. These files deliberately contain only forge-specific
checkout, trigger, and variable translation. Consumers can supply a catalog
path of their own when the default policy is inappropriate.

A GitHub caller needs only:

```yaml
jobs:
  repolicy:
    uses: kvn-dtrx/repolicy/.github/workflows/repolicy.yaml@v1
```

The corresponding GitLab entry point is:

```yaml
include:
  - component: gitlab.com/kvn-dtrx/repolicy/repolicy@1.0.0
```

Pin both integrations to a release tag or commit and mirror that ref between
the forges. Forks can select their own Repolicy repository/project through the
respective input without changing the common policy runner. On GitHub the
runtime automatically follows the repository and exact commit containing the
called workflow; an explicit repository or revision is only an override.

The existing focused reusable workflows remain as compatibility entry points.
Additional workflows cover policies that need CI-specific setup:

- `links-verified.yaml` checks links in documentation, configuration, and
  source files with the same Lychee engine as the local `check-links` CLI, but
  does not create issues or other external state.
- `command-succeeds.yaml` runs a caller-supplied command; environment setup and
  operating-system matrices remain the caller repository's responsibility.

## Colophon

- **Author:** Kvn Dtrx
- **License:** MIT (`LICENSE.txt`)
- **Forge:** <https://github.com/kvn-dtrx/repolicy>
