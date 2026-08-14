# Video Script - Talking Points

Living doc - bullet points only, not a script. Maps to the brief: demo, architecture diagram,
justification, config decisions/challenges, cost & scalability. Max 15 minutes.

## 1. Scenario framing (~30s)

- BritEdge Solutions Ltd: UK B2B manufacturing/logistics, 3 sites, on-prem in Manchester,
  30-year head of IT just retired - undocumented, tribal-knowledge setup.
- This project: proof-of-concept for moving the internal job-management web app + database off
  that aging on-prem infra.

## 2. Architecture overview

Resource group `BritEdge_DEV_RG`. Point at the diagram for each of these:

- **Compute**: Container Apps (Consumption), 2 replicas min/3 max, zone-redundant across 3 AZs,
  inside a VNet-injected, delegated subnet.
- **Registry**: ACR Basic, stores the built image.
- **Data**: Cosmos DB NoSQL, serverless, two containers (users, jobs), geo-redundant backups.
- **Secrets**: Key Vault - Cosmos key/endpoint, ACR admin creds. Nothing hardcoded anywhere.
- **Identity**: user-assigned managed identity, attached to the Container App, `Get`-only on
  Key Vault.
- **Observability**: Log Analytics workspace, fed by diagnostic settings from Cosmos DB, Key
  Vault, ACR, and the Container App Environment - not just the app's own console logs.
- **Alerting**: CPU metric alert (>80% of 0.25 vCPU) -> action group -> email. Turns passive
  logging into active monitoring - a genuinely distinct integrated service.
- **State**: Terraform remote backend in a *separate* resource group (`BritEdge_TFSTATE_RG`), so
  it survives even a full teardown of the app's resource group.

## 3. Data/control flow

- **Deploy**: GitHub Actions builds -> pushes to ACR -> Container App pulls (admin creds via Key
  Vault) -> new revision live.
- **Infra**: Terraform provisions everything except the Container App itself (that's
  `containerapp.yml` + the deploy workflow) - deliberately separate so app deploys don't need a
  `terraform apply`.
- **Secrets**: Container App holds a `keyVaultUrl` reference + the identity's ID, not values -
  Azure resolves the real value at revision-provisioning time.
- **Runtime**: ingress -> Flask -> `data` package -> Cosmos DB.
- **Same codebase, multiple DB backends**: `config.py` picks SQLite/Azure SQL/Postgres/Cosmos
  purely from env vars - good "no vendor lock-in" demo moment.

## 4. Why these services

- Container Apps over App Service: container-native, no VM/tier sizing up front.
- Container Apps over AKS: no cluster to patch/manage - fits a small IT team.
- Cosmos DB over Azure SQL/Postgres: app supports both via the same abstraction; chose Cosmos to
  demo the NoSQL path + its identity-based access fit with Container Apps.
- Key Vault + managed identity over App Settings/GitHub Secrets: centralised rotation, zero
  plaintext secrets in YAML.
- Zone redundancy over multi-region: multi-site business context justified real redundancy, but
  Cosmos DB serverless is hard-restricted to single-region (no workaround short of abandoning
  serverless) - so Container App zone redundancy was the achievable piece, Cosmos DB got
  geo-redundant *backups* instead as the next-best option.

## 5. "New IT technician" angle

- Everything defined as code (Terraform + YAML + GitHub Actions) - readable, not tribal
  knowledge.
- Same app code runs locally (SQLite, zero config), on a VM, or on Container Apps.
- CI/CD is a button-click (`workflow_dispatch`), not a manual process.
- Proactive alerting (section 2) vs. the old world where nobody knew something broke until a
  user reported it - direct callback to the retiring head of IT problem.

## 6. Cost (`markdown/COST_ANALYSIS.md` has the full breakdown)

- **~$16/month total**: ~$5 ACR Basic + ~$11 always-on Container App compute.
- Priced with Infracost against the real deployed Terraform resources (not the official Pricing
  Calculator - mention this is a deliberate substitute, prices actual resources directly).
- The ~$11/month is new: `minReplicas` moved `0 -> 2` for zone redundancy. Explicitly reversed
  tradeoff - originally accepted cold-start-on-idle to save that money, now pay it for
  availability given the multi-site context. Good "we made a cost/availability call and can
  justify it" moment.
- Cosmos DB serverless: RU-based, no 24/7 floor, vs. ~$24/month minimum on provisioned
  throughput - still worth it even though it blocked geo-redundancy.
- Still far cheaper than a VM (~$9-15+, full OS burden) or App Service (~$13-18, no scale-to-zero
  on Basic).

## 7. Scalability & redundancy

- Container Apps scale rule: `minReplicas: 2` / `maxReplicas: 3`, HTTP concurrency-based scaling.
- Zone redundancy needs the VNet-injected subnet delegated to `Microsoft.App/environments`, and
  needs ≥2 replicas to actually spread across zones - `minReplicas: 1` would defeat the point.
- **Caveat to state on camera**: Azure doesn't expose which zone each replica landed in -
  Portal, CLI, and API all lack this (open upstream feature request). Can only show
  `zoneRedundant: true` on the environment and the running replica count, not a literal
  per-zone breakdown. Say this outright rather than fake it.
- Cosmos DB serverless scales RU/s automatically with load - no capacity planning.
- Stateless app design means horizontal scaling (more replicas) just works.

## 8. Security

- No secrets in source control or pipeline YAML - all Key Vault-backed, resolved via managed
  identity.
- Managed identity Key Vault access tightened to `Get` only (was `Get, Set, List`).
- **Considered and reverted**: identity-based `AcrPull` role instead of ACR admin credentials -
  implemented, then rolled back (kept admin creds since the CI push step still needs them
  regardless). Mention as a considered-but-not-taken improvement, not a failure.
- Passwords hashed (werkzeug), never logged in plain text.

## 9. Configuration decisions & challenges (critical-thinking content)

- **Terraform state was never synced with reality** - resources existed in Azure with no state
  tracking them. Fixed via `terraform import` blocks.
- **ACR/Container App chicken-and-egg**: can't create a Container App without a valid image,
  can't push an image before the ACR exists. Solved with a placeholder image + `ignore_changes`.
- **Identity-before-secrets ordering**: Container Apps can't assign an identity *and* resolve
  Key-Vault-referenced secrets using it in the same call. Solved with an idempotent
  "bootstrap if missing" step in the GitHub Actions workflow.
- **Zone redundancy requires VNet injection**, which is create-time-only - forces a full
  destroy/recreate of the environment. Azure also won't delete an environment while it still has
  apps inside it (and the app isn't Terraform-managed), so the real sequence was: manually
  delete the container app -> `terraform apply` -> re-run the deploy workflow to rebuild it.
  Also hit `ManagedEnvironmentSubnetDelegationError` first time - subnet needs an explicit
  `delegation` block for `Microsoft.App/environments`, not just VNet injection.
- **Azure Student subscription limitations** (came up twice):
  1. No clean service-principal setup via the Deployment Center wizard - fixed by manually
     assigning `Contributor` + `az ad app credential reset`.
  2. Action Group **synthetic** test notifications are blocked entirely (`(Conflict) Free
     subscription not supported`, both Portal and CLI) - real alerts still fire and email
     normally, only the test button is restricted. Proof for the video needs a real CPU spike,
     not the test feature.
- **Renaming a Log Analytics workspace forces recreation** - `name` is immutable, wipes log
  history. Good "why we don't rename resources casually" Terraform point.
- **Remote Terraform backend**: was local-only. Fixed with a Storage Account + blob container in
  a *separate* resource group (chicken-and-egg - can't store state for a resource in a backend
  that resource itself would create), then `terraform init -migrate-state`.

## 10. Before recording - final checklist

- [ ] **Smoke-test the live app end to end**: register, create a job, confirm it round-trips
      through Cosmos DB. Hard gate, not done yet.
- [ ] **Capture the alert actually firing/emailing** - generate real load against the ingress
      URL for 5+ minutes to cross the CPU threshold (test button doesn't work, see section 9).
- [ ] **Confirm the architecture diagram** covers: secrets inside the Key Vault box, Azure
      Monitor/action group/diagnostic settings, Log Analytics Workspace, resource locations -
      a redone icon-style version exists, confirm it's final before recording.
- [ ] Decide how much airtime the AcrPull revert gets (section 8) - one line is enough.
- [ ] Walk through `markdown/COST_ANALYSIS.md` numbers live rather than reciting from memory.
