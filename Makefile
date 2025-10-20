.PHONY: test test-find-venv test-plugin test-switching clean help

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

test: test-find-venv test-switching ## Run all tests

test-find-venv: ## Run focused tests for the find_venv function
	@echo "Running find_venv function tests..."
	./test-find-venv.sh

test-switching: ## Test venv switching behavior (Issue #6)
	@echo "Running venv switching tests..."
	zsh ./test-venv-switching.sh

test-plugin: ## Run full plugin tests (may have compatibility issues)
	@echo "Running full plugin tests..."
	./test.sh

test-with-uv: ## Test with real uv environments
	@echo "Testing with real uv environments..."
	@mkdir -p test-temp-dotenv test-temp-venv
	@cd test-temp-dotenv && uv venv .venv && echo "✅ Created .venv environment"
	@cd test-temp-venv && uv venv venv && echo "✅ Created venv environment"
	@cd test-temp-dotenv && bash -c "source ../zsh-uv-env.plugin.zsh 2>/dev/null; find_venv" | grep -q ".venv" && echo "✅ .venv detection works"
	@cd test-temp-venv && bash -c "source ../zsh-uv-env.plugin.zsh 2>/dev/null; find_venv" | grep -q "venv" && echo "✅ venv detection works"
	@rm -rf test-temp-dotenv test-temp-venv
	@echo "✅ All real uv environment tests passed"

clean: ## Clean up test artifacts
	@echo "Cleaning up test artifacts..."
	@rm -rf test-temp-* /tmp/zsh-uv-env-test-*
	@echo "✅ Cleanup complete"

install-hooks: ## Install git pre-commit hooks
	@echo "Installing git pre-commit hooks..."
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo 'make test-find-venv' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Pre-commit hook installed"
