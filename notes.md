# Video Script - Talking Points

Living doc - add to this as the project progresses. Bullet points only, not a
word-for-word script. Mapped to what the brief asks the video to cover:
demo, architecture diagram, justification, config decisions/challenges, cost
& scalability. Max 15 minutes.

## 1. Scenario framing (quick, ~30s)

- BritEdge Solutions Ltd: UK B2B manufacturing/logistics, 3 sites, on-prem in
  Manchester, previous head of IT retired after 30 years.
- New head of IT modernising - this project is the proof-of-concept for
  moving the internal manufacturing web app off aging on-prem infra.
- Chose the internal manufacturing web app (not the static site) + a
  database, to demonstrate more of the service surface (compute, data,
  secrets, identity, registry, monitoring).

## 2. Architecture overview - structure

- Azure, resource group `BritEdge_DEV_RG`.
- Compute: Azure Container Apps (Consumption plan) running the Flask app in
  a Docker container, inside a Container App Environment.
- Registry: Azure Container Registry (ACR, Basic) stores the built image.
- Data: Azure Cosmos DB for NoSQL - documents, two containers (users, jobs).
- Secrets: Azure Key Vault - ACR credentials + Cosmos key/endpoint.
- Identity: a user-assigned managed identity, attached to the Container App,
  granted access to Key Vault - no secrets hardcoded anywhere in code or
  workflow files.
- Observability: Log Analytics workspace wired to the Container App
  Environment.
- [TODO once diagram is drawn: point at each box while explaining]

## 3. How things move between resources (data/control flow)

- **Deploy flow**: GitHub Actions builds the Docker image -> pushes to ACR
  -> Container App pulls it from ACR (auth via Key-Vault-backed secret) ->
  new revision goes live.
- **Infra flow**: Terraform provisions everything except the Container App
  itself (resource group, ACR, Cosmos account, Key Vault, identity, Log
  Analytics, environment) - kept deliberately separate so app deploys don't
  need a `terraform apply` every time.
- **Secrets flow**: Container App doesn't hold secret values - it holds a
  reference (`keyVaultUrl`) + the managed identity's ID; Azure resolves the
  actual secret value from Key Vault at revision-provisioning time using
  that identity.
- **Runtime flow**: user hits the Container App's public ingress -> Flask
  app -> `data` package -> Cosmos DB (documents for users/jobs).
- **Same codebase, multiple backends**: `config.py` picks SQLite / Azure
  SQL / PostgreSQL / Cosmos purely from which env vars are set - no code
  changes needed to retarget the database. Worth demoing this as a
  "no vendor lock-in on day one" point.

## 4. Why Azure / why these services (justification)

- [TODO: add explicit "considered X, chose Y" comparisons for the video -
  e.g. Container Apps vs App Service vs AKS; Cosmos vs Azure SQL]
- Container Apps over App Service: container-native, scale-to-zero on
  Consumption plan, no need to manage a VM or plan tier sizing up front.
- Container Apps over AKS: far less operational overhead for a small
  internal app - no cluster to patch/manage, fits a small IT team better.
- Cosmos DB (NoSQL) over Azure SQL/PostgreSQL: app already supports both via
  the same abstraction, but Cosmos was chosen to demonstrate the NoSQL path
  and its native fit with Container Apps' identity-based access model.
- Key Vault + managed identity over storing secrets in App Settings/GitHub
  Secrets only: centralises secret rotation, removes plaintext secrets from
  YAML/pipeline entirely.

## 5. Why this structure - the "new IT technician" angle

- Previous system: 30 years of on-prem accumulated knowledge left with the
  retiring head of IT - undocumented, hard to hand over.
- This setup is entirely defined as code (Terraform + YAML + GitHub
  Actions) - a new technician can read the repo and understand the whole
  environment, not rely on tribal knowledge.
- Same app code works locally (SQLite, zero config), on a VM, or on
  Container Apps - lowers the learning curve for anyone joining the team,
  easy to reproduce locally before touching production.
- CI/CD pipeline means deploys are a button-click (`workflow_dispatch`), not
  a manual, error-prone process - reduces reliance on one person's
  knowledge the way the previous 30-year setup did.

## 6. Cost considerations

- [TODO: fill in real Pricing Calculator numbers once done]
- Cosmos DB: currently provisioned throughput (~400 RU/s minimum, billed
  24/7 regardless of traffic) - switching to serverless capacity mode is
  the planned change, since this is a low/sporadic-traffic demo workload
  and serverless is pay-per-request.
- Container Apps Consumption plan: pay only while replicas are running;
  scale-to-zero when idle removes cost during no-traffic periods.
- ACR Basic tier: cheapest SKU, sufficient for a single small image with no
  geo-replication need.
- Key Vault + Log Analytics: both consumption-based, negligible cost at
  this scale.

## 7. Scalability

- [TODO: confirm final scale rule config once added to containerapp.yml]
- Container Apps scale rule: min/max replicas + HTTP concurrency-based
  scaling - handles traffic spikes (e.g. month-end job reporting across 3
  sites) without manual intervention, scales back down to control cost.
- Cosmos DB serverless scales throughput automatically with request volume
  - no capacity planning needed up front.
- Stateless app design (no local session state) means horizontal scaling
  (more replicas) just works.

## 8. Security considerations

- No secrets in source control or pipeline YAML - all Key-Vault-backed,
  resolved via managed identity at deploy time.
- Managed identity access policy scoped to least privilege (read-only on
  secrets, not write) - [TODO: confirm once tightened from Get/Set/List to
  Get only].
- [TODO: mention if ACR auth gets moved from admin credentials to identity-
  based AcrPull role]
- Passwords hashed (werkzeug) before storage, never stored/logged in plain
  text.

## 9. Configuration decisions & challenges (good "critical thinking" content)

- **Terraform state was never synced with reality** - resources existed in
  Azure with no local/remote state tracking them (no backend configured).
  Fixed via `terraform import` blocks to bring existing resources under
  management before continuing.
- **ACR/Container App chicken-and-egg problem**: can't create a Container
  App without a valid image reference, can't push an image before the ACR
  exists. Solved with a placeholder image at Terraform-creation time, with
  `ignore_changes` so Terraform never fights the image tag that CI deploys.
- **Identity-before-secrets ordering constraint**: Azure Container Apps
  can't assign a managed identity *and* resolve Key-Vault-referenced
  secrets using that identity in the same creation call - the identity has
  to already be attached before secrets can reference it. Solved with an
  idempotent "bootstrap if missing" step in the GitHub Actions workflow:
  create a bare container app + attach identity first (only on first run),
  then always apply the full config as an update.
- **Missing Key Vault access policy**: the container app's identity had no
  permission on the vault at all initially (Terraform never got that far
  before earlier failures) - diagnosed by comparing the vault's actual
  access policies against what Terraform expected, fixed by letting
  Terraform create the missing policy rather than trying to import a
  resource that didn't exist yet.
- **Azure student account limitations**: couldn't get a service principal
  set up cleanly via the auto-created Deployment Center wizard (no role
  assignment/credentials) - fixed by manually assigning `Contributor` and
  generating credentials via `az ad app credential reset`.

## 10. Not yet covered / still to do

- [ ] Draw and insert architecture diagram, walk through it live
- [ ] Live demo of the deployed app (register, create job, view job)
- [ ] Final real cost numbers from the Pricing Calculator
- [ ] Confirm scale rule + Cosmos serverless changes before recording
- [ ] Decide on and mention any stretch items actually implemented
      (AcrPull identity-based ACR auth, tightened Key Vault permissions,
      remote Terraform backend)
