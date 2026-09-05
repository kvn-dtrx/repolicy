# ---
# title: Makefile for repolicy
# ---

# Make targets follow paradigmata (install-user = deploy).

# ---

WIRE := $(CURDIR)/bin/make-wire.py
LOG_LIBEXEC := $(CURDIR)/src/wire/libexec
MY_LOCAL_HOME ?= $(HOME)/.local
REPOLICY_DEST := $(MY_LOCAL_HOME)/libexec/repolicy
RULES_DEST := $(REPOLICY_DEST)/rules
ACTIONS_DEST := $(REPOLICY_DEST)/actions
ADAPTERS_DEST := $(REPOLICY_DEST)/adapters
GIT_HOOKS_DEST := $(REPOLICY_DEST)/git-hooks

.PHONY: help _help install install-user test

help _help: ## Displays available targets with description
	@bin/make-help.sh

install: install-user ## Alias for install-user

install-user: ## Symlink Repolicy runtime, rules, actions, and adapters
	@if [ ! -f "$(LOG_LIBEXEC)/log-error" ]; then \
	    command -v dia > /dev/null 2>&1 || { \
	        printf 'Missing %s (dia not on PATH to pull scripts/log-*)\n' \
	            "$(LOG_LIBEXEC)/log-error" >&2; \
	        exit 1; \
	    }; \
	    dia "$(LOG_LIBEXEC)"; \
	fi
	@python3 "$(WIRE)" "$(CURDIR)"
	@mkdir -p "$(REPOLICY_DEST)"
	@ln -sfn "$(CURDIR)/src/rules" "$(RULES_DEST)"
	@ln -sfn "$(CURDIR)/src/actions" "$(ACTIONS_DEST)"
	@ln -sfn "$(CURDIR)/src/adapters" "$(ADAPTERS_DEST)"
	@ln -sfn "$(CURDIR)/src/adapters/git-hooks/entry" "$(GIT_HOOKS_DEST)"
	@printf 'symlinked %s -> %s\n' "$(RULES_DEST)" "$(CURDIR)/src/rules"
	@printf 'symlinked %s -> %s\n' "$(ACTIONS_DEST)" "$(CURDIR)/src/actions"
	@printf 'symlinked %s -> %s\n' "$(ADAPTERS_DEST)" "$(CURDIR)/src/adapters"
	@printf 'symlinked %s -> %s\n' "$(GIT_HOOKS_DEST)" "$(CURDIR)/src/adapters/git-hooks/entry"

test: ## Runs the Repolicy runtime tests
	@bash tests/attributes.bash
	@bash tests/run-repolicy-catalog.bash
	@bash tests/filenames-formatted.bash
	@bash tests/ci-policy.bash
