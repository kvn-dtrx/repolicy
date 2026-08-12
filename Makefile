# ---
# title: Makefile for git-automatisation
# ---

# Make targets follow paradigmata (install = deploy).

# ---

WIRE := $(CURDIR)/bin/make-wire.bash

.PHONY: help _help install

help _help: ## Displays available targets with description
	@bin/make-help.sh

install: ## Symlink src/wire into MY_LOCAL_HOME via config/wire.ini
	@bash "$(WIRE)" "$(CURDIR)"
