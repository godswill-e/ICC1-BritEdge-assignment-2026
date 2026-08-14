# TODO

Living checklist - add to this as we go. Ordered roughly by marks-per-effort
(rubric weight in brackets where relevant). Not the video/diagram
themselves - those are tracked in `markdown/Notes.md`.

## Cost & Scalability (10%) - currently the weakest graded area

- [x] Switch Cosmos DB to serverless capacity mode (`capabilities { name =
      "EnableServerless" }` in `cosmos_db.tf`) - currently provisioned
      throughput, billed ~400 RU/s minimum 24/7 regardless of traffic.
- [x] Add an explicit `scale:` block to `containerapp.yml` (min/max
      replicas + HTTP concurrency rule) - currently relying on undeclared
      defaults (`minReplicas: null`, `rules: null`), not demonstrable as an
      intentional decision.
- [x] Cost pass with actual SKUs in use, recorded in `markdown/COST_ANALYSIS.md` - used
      Infracost against `terraform/` (~$5/month, mostly ACR) plus manually-priced Container App
      compute (~$11/month for `minReplicas: 2`) since Infracost can't see non-Terraform-managed
      compute. ~$16/month total. Used Infracost instead of the official Pricing Calculator since
      it prices the actual deployed resources directly - cross-check a couple of headline figures
      against the Pricing Calculator before recording if you want a second source.

## Security - push Architecture criterion toward Outstanding

- [x] Tighten `container_identity`'s Key Vault access policy from
      `Get, Set, List` down to `Get` only - it only ever reads secrets.
- [ ] ~~Move ACR pull auth from admin username/password to an `AcrPull` role
      assignment for `container_identity`, and drop the ACR admin
      credentials/secrets entirely.~~

## New resource: Azure Monitor

- [x] Add Azure Monitor alert rule(s) on top of the existing Log Analytics
      workspace - done in `terraform/monitoring.tf`: diagnostic settings
      (Cosmos DB, Key Vault, ACR, Container App Environment) feeding the
      workspace, an action group emailing on trigger, and a CPU metric
      alert (`UsageNanoCores > 80%`) on the Container App. Applied and
      confirmed live.
- [ ] ~~Decide whether to also wire up Application Insights for app-level
      request/dependency tracing, or keep it to infra-level alerts only -
      infra-level is enough for the "distinct service" count, App Insights
      is a stretch item if there's time.~~
- [x] Mentioned in `markdown/Notes.md` section 2 (architecture overview)
      and section 5 (new IT technician angle).
- [ ] Still need to capture the alert actually firing/emailing for the
      video - the Portal/CLI synthetic test-notification feature is
      blocked on this Free/Student subscription (`(Conflict) Free
      subscription not supported`), so this means generating real load
      against the ingress URL for 5+ minutes to cross the CPU threshold for
      real. See `markdown/Notes.md` section 9.

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
- [x] Add more/better redundancy for Cosmos DB and the containers:
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
  - [x] Container App redundancy/failover - done: added a VNet + delegated
        subnet (`terraform/networking.tf`), set `infrastructure_subnet_id`
        + `zone_redundancy_enabled = true` on `container_env`, and bumped
        `minReplicas` to `2` in `containerapp.yml` so the environment
        actually spreads replicas across Availability Zones (zone
        redundancy needs ≥2 replicas to mean anything). Required a manual
        `az containerapp delete` before `terraform apply` since Azure won't
        replace an environment that still has apps in it. Costs ~$11/month
        extra (was $0 at `minReplicas: 0`) - see `markdown/COST_ANALYSIS.md`.
        Deployed and confirmed working. Note: Azure doesn't expose which
        zone each replica actually landed in (Portal, CLI, and API all lack
        this - open upstream feature request), so this can't be visually
        proven on camera, only the environment's `zoneRedundant: true`
        setting and the running replica count can be shown.

## Before recording anything

- [ ] Smoke-test the live app end to end: load the ingress URL, register a
      user, create a job, confirm it round-trips through Cosmos DB.
