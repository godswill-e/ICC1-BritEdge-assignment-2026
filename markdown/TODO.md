# TODO

Living checklist - add to this as we go. Ordered roughly by marks-per-effort
(rubric weight in brackets where relevant). Not the video/diagram
themselves - those are tracked in `script.md`.

## Cost & Scalability (10%) - currently the weakest graded area

- [x] Switch Cosmos DB to serverless capacity mode (`capabilities { name =
      "EnableServerless" }` in `cosmos_db.tf`) - currently provisioned
      throughput, billed ~400 RU/s minimum 24/7 regardless of traffic.
- [x] Add an explicit `scale:` block to `containerapp.yml` (min/max
      replicas + HTTP concurrency rule) - currently relying on undeclared
      defaults (`minReplicas: null`, `rules: null`), not demonstrable as an
      intentional decision.
- [ ] Run a real Azure Pricing Calculator pass with the actual SKUs in use
      and record the numbers (for `script.md` section 6).

## Security - push Architecture criterion toward Outstanding

- [x] Tighten `container_identity`'s Key Vault access policy from
      `Get, Set, List` down to `Get` only - it only ever reads secrets.
- [ ] ~~Move ACR pull auth from admin username/password to an `AcrPull` role
      assignment for `container_identity`, and drop the ACR admin
      credentials/secrets entirely.~~

## New resource: Azure Monitor

- [ ] Add Azure Monitor alert rule(s) on top of the existing Log Analytics
      workspace (e.g. `azurerm_monitor_metric_alert` for high CPU/memory,
      or a scheduled query alert for HTTP 5xx rate) - turns the current
      passive logging into active monitoring, and is a genuinely distinct
      additional integrated service for the rubric's service-selection
      criterion.
- [ ] ~~Decide whether to also wire up Application Insights for app-level
      request/dependency tracing, or keep it to infra-level alerts only -
      infra-level is enough for the "distinct service" count, App Insights
      is a stretch item if there's time.~~
- [ ] Mention this in `script.md` section 2 (architecture overview) and
      section 5 (new IT technician angle - proactive alerting vs. the old
      setup where nobody would know something broke until a user reported
      it).

## Cleanup

- [x] Delete or explain `test-container` - untracked resource in
      `BritEdge_DEV_RG`, not defined anywhere in Terraform.
- [x] Fix the `cosmos-enpoint` typo (container app secret name) to
      `cosmos-endpoint` for consistency with the actual Key Vault secret
      name.
- [ ] Architecture diagram:
  - [ ] To have secrets/keys inside square of keyvault
  - [ ] Add Azure monitor, actions, and diagnostic settings
  - [ ] Update Analytics Workspace
  - [ ] Locations of resources

## Reliability

- [x] Add a remote Terraform backend (Storage Account + container for
      `.tfstate`) so state is shared between local runs and CI instead of
      being local-only.
- [ ] Add more/better redundancy for Cosmos DB and the containers:
  - [x] Cosmos DB multi-region `geo_location` - investigated, ruled out:
        serverless accounts are hard-restricted to a single region, no
        workaround short of giving up serverless (reverses the earlier cost
        decision). Not worth it for this workload.
  - [x] Cosmos DB backup redundancy - changed `backup.storage_redundancy`
        from `Local` to `Geo` in `cosmos_db.tf` (in-place update, confirmed
        via `terraform plan`, no data loss). Backups now survive a regional
        outage even though live data doesn't fail over; restore is still a
        Microsoft support request, not self-service (would need to migrate
        to Continuous backup mode for that - considered a stretch item, one-
        way migration, not done).
  - [ ] Container App redundancy/failover - no minimum replica floor
        (`minReplicas: 0`) and the environment isn't zone-redundant. Next up.

## Before recording anything

- [ ] Smoke-test the live app end to end: load the ingress URL, register a
      user, create a job, confirm it round-trips through Cosmos DB.
