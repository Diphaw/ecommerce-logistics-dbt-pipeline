SHELL := /bin/bash
VENV ?= venv
BIN := $(VENV)/bin
DBT_DIR := dbt_olist_logistics

# Load DB_* variables from .env and expose them to child processes (dbt reads them via env_var()).
ifneq (,$(wildcard .env))
include .env
export
endif

DBT := $(BIN)/dbt
DBT_FLAGS := --project-dir $(DBT_DIR) --profiles-dir $(DBT_DIR)

.DEFAULT_GOAL := help
.PHONY: help setup clean-venv up down ingest dbt-debug dbt-run dbt-test dbt-build dbt-docs pipeline lint format

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Create standalone virtualenv (--copies) and install dependencies
	python3 -m venv --copies $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -r requirements-dev.txt

clean-venv: ## Remove existing virtualenv
	rm -rf $(VENV)

up: ## Start PostgreSQL
	docker compose up -d

down: ## Stop PostgreSQL (data volume is kept)
	docker compose down

ingest: ## Load raw CSVs into the `raw` schema
	$(BIN)/python -m ingestion.load_raw

dbt-debug: ## Verify the dbt connection
	$(DBT) debug $(DBT_FLAGS)

dbt-run: ## Build all dbt models
	$(DBT) run $(DBT_FLAGS)

dbt-test: ## Run all dbt tests
	$(DBT) test $(DBT_FLAGS)

dbt-build: ## Build models and run tests in DAG order
	$(DBT) build $(DBT_FLAGS)

dbt-docs: ## Generate and serve dbt docs (lineage graph)
	$(DBT) docs generate $(DBT_FLAGS)
	$(DBT) docs serve $(DBT_FLAGS)

pipeline: ingest dbt-build ## Run the full pipeline: ingest then dbt build

lint: ## Lint Python code
	$(BIN)/ruff check .

format: ## Auto-format Python code
	$(BIN)/ruff check --fix .
	$(BIN)/ruff format .

