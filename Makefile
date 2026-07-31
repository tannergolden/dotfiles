# --- Developer entry points ---
#
# The standards require every project to map local operations to `make`, so
# continuous integration can run the same commands a contributor does
# without knowing anything about the stack. `ci.yml` resolves a stage to
# `make <stage>` when a target of that name exists, which is why these
# names are not a matter of taste.
#
# WHAT BELONGS HERE: the commands a person or a gate runs. No logic. Every
# target is a one-line call into scripts/, so this file cannot drift away
# from what those scripts actually do.
#
# THREE OF THE SEVEN STANDARD TARGETS DO NOT APPLY, and pretending
# otherwise would be worse than saying so. `dev` and `deploy` have no
# meaning for a dotfiles repository: there is no server to start and no
# artifact to promote. They exist as documented no-ops so that a caller
# expecting the standard interface gets a clean exit and an explanation
# rather than "No rule to make target".
#
# `lint-docs` is genuinely unimplementable here. It is provided by
# scripts/update-doc-indexes.py inside the standards repository, and
# copying a standard into a consuming repository is explicitly forbidden.
# This repository takes the conventions and not the automation, so it
# calls no shared gate workflow and there is therefore no spelling or
# link checking anywhere in it - stated plainly, because this comment
# used to claim ci.yml provided that coverage and no such workflow is
# called from here.

# NO VERSION PINS LIVE HERE. Two variables used to, and nothing read
# them: the real chezmoi pin is in scripts/bootstrap.sh and .ps1 (which
# download and checksum it) and in the workflow's env, and shellcheck is
# whatever CI's apt provides. A pin nothing enforces is worse than no pin,
# because it is quoted as though it were true.

.PHONY: help setup lint lint-shell lint-shell-templates lint-powershell \
        lint-format test build dev deploy render prefixes ci-parity apply \
        diff verify

help: ## Show the available targets
	@grep -hE '^[a-z][a-z-]*:.*?## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Install the pinned tools these targets need
	@scripts/bootstrap.sh

# ci-parity is last and checks the others: it fails if a prerequisite on
# this line is not also run by the workflow, because the pipeline lists
# these as separate steps for granularity and the two lists were
# previously kept equal by memory alone.
lint: lint-shell lint-shell-templates lint-powershell render prefixes ci-parity ## Run every static check CI runs

lint-shell: ## ShellCheck over the shell this repository ships
	@command -v shellcheck >/dev/null 2>&1 \
		|| { echo "shellcheck not installed; skipping (CI installs it)"; exit 0; }
	@shellcheck --severity=style install.sh scripts/*.sh \
		home/dot_local/bin/executable_ai-* \
		&& echo "ok   shellcheck clean"

lint-shell-templates: ## ShellCheck the shell the templates GENERATE
	@scripts/check-shell-templates.sh

lint-powershell: ## Parse every .ps1, which nothing checked before
	@REPO_DIR="$(CURDIR)" scripts/check-powershell.sh

render: ## Render every template for every platform, from this platform
	@scripts/render-all-os.sh

prefixes: ## Fail if a chezmoi attribute prefix leaked into a target path
	@scripts/check-prefixes.sh

ci-parity: ## Fail if CI stopped running everything 'make lint' runs
	@scripts/check-ci-parity.sh

test: ## Apply, backup, restore and idempotency proof against a throwaway HOME
	@scripts/smoke-test.sh

build: ## Prove the source state renders and applies without touching $HOME
	@scripts/render-all-os.sh >/dev/null && echo "ok   source state builds"

dev: ## Not applicable: there is no development server to start
	@echo "make dev: not applicable to a dotfiles repository."
	@echo "Use 'make diff' to preview changes, 'make apply' to apply them."

deploy: ## Not applicable: applying to a machine is 'make apply'
	@echo "make deploy: not applicable to a dotfiles repository."
	@echo "There is no artifact to promote. 'make apply' configures this machine."

# --- everyday convenience --------------------------------------------------

diff: ## Show what applying would change on this machine
	@chezmoi diff --source=$(CURDIR)

apply: ## Apply the source state to this machine
	@chezmoi apply --source=$(CURDIR)

verify: ## Exit non-zero if this machine has drifted from the source state
	@chezmoi verify --source=$(CURDIR) && echo "ok   no drift"
