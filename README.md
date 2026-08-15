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
│   ├── adapters/
│   │   ├── git-hooks/
│   │   │   ├── entry/               # core.hooksPath entry points
│   │   │   ├── run-rule
│   │   │   └── run-action
│   │   └── github-actions/
│   │       └── run-rule
│   └── wire/libexec/                # catalog runner and log helpers
├── .github/workflows/               # reusable CI adapters
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

This installs the runtime below `~/.local/libexec/repolicy/`, including `rules/`,
`actions/`, `adapters/`, and `git-hooks/`. `MY_LOCAL_HOME` overrides `~/.local`.

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
cli     sanitise-shell                 --staged
rule    filenames-formatted.bash
rule    shellcheck-clean.bash
attribute repolicy-sanitise
```

Supported row kinds:

| Kind | Meaning |
| --- | --- |
| `cli` | Run an external command with the configured arguments. Missing commands are skipped with a warning. |
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

Every catalog step uses a three-state exit contract:

| Status | Meaning | Catalog behaviour |
| --- | --- | --- |
| `0` | Successful, no mutation | Continue |
| `3` | Files were changed | Continue all remaining steps, then reject the Git operation |
| Any other non-zero status | Validation or execution failed | Stop immediately with that status |

The dedicated status `3` avoids confusing a formatter's expected mutation
with the ordinary failure status `1`. Repolicy reports all formatting changes
before asking for review and restaging.

## GitHub Actions

Reusable workflows under `.github/workflows/` prepare pull-request or repository
inputs and invoke the same files under `src/rules/`. Additional workflows cover
policies that are naturally CI-native:

- `links-work.yaml` checks links but does not create issues or other external
  state.
- `command-succeeds.yaml` runs a caller-supplied command; environment setup and
  operating-system matrices remain the caller repository's responsibility.

## Colophon

- **Author:** Kvn Dtrx
- **License:** MIT (`LICENSE.txt`)
- **Forge:** <https://github.com/kvn-dtrx/repolicy>
