# Cost Analysis

Generated with [Infracost](https://www.infracost.io/) against `terraform/`, with Container App
compute priced manually since Infracost can't see it. Feeds Cost & Scalability in `Notes.md`.

## Main points

- **Actual monthly cost: ~$16**
  - ~$5 ACR Basic tier (can be overcome by using Docker Hub - free) + ~$11 always-on Container
    App compute (see below) - the two are now comparable line items, not just "ACR is everything."
- Container Apps + Cosmos DB Serverless beats a VM or App Service on cost **and** operational burden.
- **No longer scales to zero** - `minReplicas: 2`, a deliberate change from the original `0` to
  get zone redundancy (see `TODO.md` Reliability section). Accepted tradeoff, reversed: we
  originally accepted a cold-start delay to save the ~$11/month; given the multi-site business
  context, we now pay that ~$11/month instead to keep the app available through a zone failure.

## Current cost (`infracost scan .`)

| Resource | Monthly cost |
|---|---:|
| Container Registry (ACR Basic) | $5.00 |
| Cosmos DB (serverless) | $0.00* |
| Log Analytics Workspace | $0.00* |
| Monitor Action Group | $0.00 (free tier) |
| Virtual Network + subnet | $0.00 (VNets are always free) |
| Everything else (15 resources) | $0.00 |
| **Infracost total** | **~$5.00** |

\* Usage-based, not a hard $0 - see below.

## What Infracost can't see

Container App compute isn't Terraform-managed (it's deployed via `containerapp.yml`, not
Terraform), so it's not in the table above - this is the gap that made the cost doc go stale
after the zone-redundancy change.

- **Compute**: idle-rate billing at `$0.000008`/vCPU-sec + `$0.000001`/GiB-sec, after a 180k
  vCPU-sec / 360k GiB-sec / 2M request free grant per month. At `0.25 vCPU` / `0.5 GiB` and
  `minReplicas: 2` (two always-on replicas, required so zone redundancy actually spreads across
  zones), that's **~$11/month** - see the zone-redundancy cost breakdown discussed when this was
  decided. At the old `minReplicas: 0`, this line was $0.
- **Cosmos RUs (Request Units)**: ~$0.25/million RUs, no minimum. This app's traffic is nowhere near 1M/month →
  effectively **$0**.
- **Log ingestion**: free up to 5GB/month - won't be hit at this scale.

**Bottom line: ~$16/month - ~$5 ACR (Infracost-tracked) + ~$11 always-on compute for zone
redundancy (not Infracost-tracked, priced manually).**

> Scan also flagged Cosmos DB's `backup.storage_redundancy = Geo` as a cost-saving opportunity
> (up to 50% off backup storage). Not actioned here - tracked as a separate reliability tradeoff
> in `TODO.md`.

## Why not a VM or App Service?

| | Monthly cost | Scales to zero? | OS/patch burden |
|---|:---:|:---:|:---:|
| VM (`B1s` + disk + a database) | ~$9-15+ | No | Full burden |
| App Service (`B1`) + Cosmos DB | ~$13-18 | No (Basic tier) | None |
| **Container Apps + Cosmos Serverless (current)** | **~$16** | **No (`minReplicas: 2`, zone-redundant)** | **None** |

**VM** - always-on 24/7 regardless of traffic, still need a database on top, and full OS
patching/security falls on whoever runs it (reopens the "tribal knowledge" problem this project
exists to fix - see `Notes.md` section 5).

**App Service** - managed, no OS patching, but Basic tier has no scale-to-zero (Premium does, at
much higher cost). Paying full price 24/7 for a tool used in bursts, not continuously.

**Current setup** - billed per second of actual use, still cheaper than the alternatives even
after adding redundancy cost. `minReplicas` moved from `0` to `2` deliberately: the app started
mission-critical-adjacent given the multi-site business context (three UK sites depending on it),
so we now pay ~$11/month to keep it available through a single Availability Zone failure rather
than accept the cold-start-on-idle tradeoff. Cosmos DB serverless still mirrors the original idea
on the data side: RU-based billing with no 24/7 floor, vs. provisioned throughput's **~$24/month
minimum** regardless of traffic - that tradeoff wasn't revisited, since Cosmos DB serverless can't
do multi-region/zone redundancy at all regardless of cost (see `TODO.md`), so there was no
availability upside to paying for provisioned throughput instead.

For a low/sporadic-traffic internal tool, consumption billing tracks real usage instead of
provisioned capacity - cheaper now, and scales predictably if usage grows.

---
*VM/App Service figures are Azure's published on-demand rates (not Infracost-computed, since
they're not real resources here) - representative for comparison, cross-check with the Pricing
Calculator for final numbers.*
