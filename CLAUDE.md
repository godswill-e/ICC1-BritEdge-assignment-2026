# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flask job-management web app (BritEdge Job Management) built for the Ada ICC1 "Introduction to Cloud
Computing" module capstone. The point of the codebase is that the *same, unmodified* application code can run
against four different database backends and on two different hosting targets, selected entirely via
environment variables — this is the core design constraint, not incidental.

## Commands

Run locally (uv is the primary workflow; `uv run` creates `.venv` and installs from `uv.lock` automatically):
```sh
uv run python3 application.py
```
Pip fallback:
```sh
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python3 application.py
```
App listens on `:8080` by default (`PORT` env var to override). With no `.env`/env vars set it uses SQLite
with zero configuration.

Docker (mirrors the App Service/Container Apps gunicorn startup — use this to test that config locally):
```sh
docker build -t britedge-app .
docker run --env-file .env -p 8080:8080 britedge-app
```

Terraform (from `terraform/`):
```sh
terraform init
terraform plan
terraform apply
```
`az login` must be active first — there is no service principal available for local runs (Azure student
account limitations; see Notes.md), so Terraform relies on the logged-in user's credentials both locally and
was intended to via a service principal in CI.

There is no test suite, linter, or formatter configured in this repo (no `tool.ruff`/pytest config in
`pyproject.toml`, no `tests/` directory) — don't assume `pytest`/`ruff` commands exist.

## Architecture

**Backend abstraction is the central pattern.** `routes.py` and `application.py` only ever call functions on
the `data` package (`data.get_all_jobs()`, `data.create_job(...)`, etc.) — never SQLAlchemy or the Cosmos SDK
directly. `data/__init__.py` picks one of two same-signature implementations at import time based on
`Config.DB_MODE`:
- `data/sql_backend.py` — SQLAlchemy models/queries, used for SQLite, Azure SQL, and PostgreSQL alike (only
  the connection string differs).
- `data/nosql_backend.py` — Azure Cosmos DB for NoSQL, documents in two containers (`users`, `jobs`) each
  partitioned on `/id`. No joins: `NoSQLJob` documents carry `user_id` and `get_all_jobs()` manually resolves
  and attaches the author so templates can use `job.author.username` the same way as the SQL backend.

When adding a new route or feature, add the function to *both* backends with the same signature, then wire it
into the `if Config.DB_MODE == 'nosql': ... else: ...` import block in `data/__init__.py`.

**Backend selection happens once, in `config.py`**, purely from which env vars are set (checked in this
order): `COSMOS_ENDPOINT` → NoSQL; else `AZURE_SQL_SERVER`+`AZURE_SQL_USER`+`AZURE_SQL_PASSWORD` (all three
required together, enforced by a `raise` in `Config`) → Azure SQL; else `PG_HOST`+`PG_USER`+`PG_PASSWORD` (all
three required together) → PostgreSQL; else SQLite fallback. `.env.example` documents every variable and its
optional overrides.

**Import order in `application.py` is load-bearing**, not stylistic: `Config` must be applied to the Flask app
before `import data` (data layer reads `Config.DB_MODE` at import time), and `routes.py` is imported last,
after `data.init_backend(app)` has run, to avoid circular imports (`routes.py` imports `app` back from
`application.py`).

## Infrastructure (`terraform/`) and deployment (`.github/workflows/`)

Two-stage, both manually triggered (`workflow_dispatch`, not on push):
1. `terraform-infra.yml` runs `terraform apply` in `terraform/` — provisions the resource group, Container
   Registry (ACR), Container App Environment + Log Analytics, Cosmos DB account, Key Vault, and a
   user-assigned managed identity with Key Vault access.
2. `azure_container_app_deploy.yml` builds/pushes the Docker image to ACR, resolves the managed identity's
   resource ID via `az identity show` and substitutes it into `.github/containerapp.yml` (the `az
   container-apps-deploy-action` config), then deploys/updates the Container App itself.

Notable details future work should respect:
- **The Container App resource itself is not Terraform-managed** — it's created/updated by the deploy action
  reading `.github/containerapp.yml`, deliberately kept separate from the Terraform-managed environment it
  runs in (`managedEnvironmentId` is hardcoded in that YAML, pointing at the Terraform-created environment).
- **Secrets in `containerapp.yml` are Key-Vault-backed** (`keyVaultUrl` + `identity:` referencing the
  user-assigned identity), not literal values — this depends on that identity already having `Get`/`List`
  secret permissions on the vault, granted via `azurerm_key_vault_access_policy` in Terraform.
- **`provider.tf` has no `backend` block** — Terraform state is local-only and not shared between machines/CI
  runs. `terraform/imports.tf` holds one-off `import` blocks for resources that already existed in Azure
  before being brought under state; safe to delete once `terraform state list` confirms they're tracked.
- The ACR/Container App chicken-and-egg problem (can't create a Container App without a valid image, can't
  push an image before the ACR exists) is solved with a placeholder image plus `ignore_changes` in Terraform,
  so `terraform apply` never fights the image tag that CI deploys.
