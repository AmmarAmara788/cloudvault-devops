# CloudVault — common developer tasks
# Usage: `make <target>`. Run `make help` to list targets.

SHELL := /bin/bash
COMPOSE := docker compose

.DEFAULT_GOAL := help

.PHONY: help up down restart seed test logs ps build clean rebuild wait

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Build (if needed) and start the whole stack in the background
	@test -f .env || (echo "No .env found — copying .env.example"; cp .env.example .env)
	$(COMPOSE) up -d --build
	@echo ""
	@echo "CloudVault is starting. Web UI: http://localhost:5173  Gateway: http://localhost:8080"
	@echo "Run 'make seed' once services are healthy to create the demo user + bucket."

down: ## Stop and remove containers, networks, and volumes
	$(COMPOSE) down -v

restart: down up ## Full restart (down then up)

build: ## Build all images without starting
	$(COMPOSE) build

seed: ## Create the S3 bucket + demo user + sample data
	./scripts/seed.sh

test: ## Run each service's test suite (Node's built-in test runner)
	@set -e; for s in gateway auth-service files-service upload-service thumbnail-worker notification-service; do \
		echo "==> testing $$s"; \
		( cd services/$$s && npm test --silent ); \
	done
	@echo "All service tests passed."

logs: ## Tail logs from all services
	$(COMPOSE) logs -f --tail=100

ps: ## Show container status
	$(COMPOSE) ps

wait: ## Block until the gateway reports healthy
	@echo "Waiting for gateway health..."
	@until curl -fsS http://localhost:8080/healthz >/dev/null 2>&1; do sleep 2; printf '.'; done; echo " ready"

clean: ## Remove build artifacts and node_modules
	find . -name node_modules -type d -prune -exec rm -rf {} + 2>/dev/null || true
	find . -name dist -type d -prune -exec rm -rf {} + 2>/dev/null || true

rebuild: ## No-cache rebuild of all images
	$(COMPOSE) build --no-cache

db-backup:
	@./scripts/backup.sh

db-restore:
	@if [ -z "$(db)" ]; then \
		echo "Usage: make db-restore db=<authdb|filesdb|notifdb>"; \
		exit 1; \
	fi
	@./scripts/restore.sh $(db) latest --force

db-clean-archives:
	@./scripts/clean-archives.sh

db-list-backups:
	@./scripts/list-backups.sh

health:
	@./scripts/health-check.sh