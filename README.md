---
title: Git Automatisation
---

---

# Git Automatisation

## Synopsis

A library of **native Git hook** scripts (plus small shared `log-*` helpers). This is not a [pre-commit](https://pre-commit.com/) Python-framework project: the scripts are meant to be installed or dispatched as ordinary Git hooks (`pre-commit`, `commit-msg`, `pre-push`, and so on).

**WARNING:** Parts of the tree outside `src/hooks/` and `src/wire/libexec/` are still work in progress. Prefer the hook scripts themselves unless you have verified a given CI or tool path.

## Dendron

```
git-automatisation/
├── src/
│   ├── hooks/                # native Git hook scripts (library core)
│   │   ├── applypatch-msg/
│   │   │   └── example.sh
│   │   ├── pre-applypatch/
│   │   │   └── example.sh
│   │   ├── post-applypatch/
│   │   │   └── example.sh
│   │   ├── pre-commit/
│   │   │   ├── filenames-formatted.bash
│   │   │   ├── notebooks-cleared.bash
│   │   │   ├── contains-ignored-files.sh
│   │   │   └── branch-name-valid.bash
│   │   ├── prepare-commit-msg/
│   │   │   └── example.sh
│   │   ├── commit-msg/
│   │   │   ├── format-commit-message.sh
│   │   │   └── commit-message-valid.sh
│   │   ├── post-commit/
│   │   │   └── example.sh
│   │   ├── pre-rebase/
│   │   │   └── example.sh
│   │   ├── post-checkout/
│   │   │   └── example.sh
│   │   ├── pre-merge-commit/
│   │   │   └── example.sh
│   │   ├── post-merge/
│   │   │   └── example.sh
│   │   ├── pre-push/
│   │   │   └── pushes-to-protected-branch.sh
│   │   ├── push-to-checkout/
│   │   │   └── example.sh
│   │   ├── pre-auto-gc/
│   │   │   └── example.sh
│   │   ├── post-rewrite/
│   │   │   └── example.sh
│   │   └── sendemail-validate/
│   │       └── example.sh
│   ├── wire/
│   │   └── libexec/          # log-* helpers (wire Form B)
│   ├── ci/                   # residual / WIP — scripts fetched by Actions
│   └── tools/                # residual / WIP — ad-hoc local git helpers
├── bin/
│   ├── make-wire.bash        # wire installer (mounts from config/wire.ini)
│   ├── make-help.sh          # lists Makefile targets with ## descriptions
│   └── _ls-make-targets.awk  # helper for make-help.sh
├── config/
│   └── wire.ini              # mounts libexec → ${MY_LOCAL_HOME}/libexec/${pkg}
├── Makefile                  # make / make help; make install → bin/make-wire.bash
├── .github/                  # residual / WIP — workflows and templates
├── LICENSE.txt
└── README.md
```

## How to use

Point your global or per-repo hooks at these scripts via `core.hooksPath`, or call them from a thin dispatcher in your dotfiles (one entrypoint per Git hook name that execs the matching script here).

`log-*` helpers live under `src/wire/libexec/`. `config/wire.ini` plus `bin/make-wire.bash` mounts them to `${MY_LOCAL_HOME}/libexec/git-automatisation`. Run:

```
make install
```

or:

```
bash bin/make-wire.bash
```

## Colophon

- **Author:** Kvn Dtrx
- **License:** MIT (`LICENSE.txt`)
- **Forge:** https://github.com/kvn-dtrx/git-automatisation
