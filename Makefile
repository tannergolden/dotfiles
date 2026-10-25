# Dotfiles commands. The agents targets install the universal rules from
# tannergolden/intelligence into every AI app's home folder;
# docs/technical/AI-Agent-Rules.md explains them. `make help` lists every target.

VERSION ?=

.PHONY: help agents agents-check agents-uninstall agents-pin

help: ## List every target
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:.*## /|/' | awk -F '|' '{ printf "  %-17s %s\n", $$1, $$2 }'

agents: ## Install the pinned universal rules into every AI app's home folder
	@sh agents/home-kit.sh install

agents-check: ## Compare every installed copy with the pinned release
	@sh agents/home-kit.sh check

agents-uninstall: ## Put back what was there before the rules were installed
	@sh agents/home-kit.sh uninstall

agents-pin: ## Pin VERSION, recording the SHA-256 of each file it serves
	@sh agents/home-kit.sh pin $(VERSION)
