# Cost Analysis

Generated with [Infracost](https://www.infracost.io/) against `terraform/`. Feeds Cost &
Scalability in `script.md`/`Notes.md`.

## Main points

- **Actual monthly cost: ~$5**
  - Almost entirely the ACR Basic tier (can be overcome by using Docker Hub - free).
- Container Apps + Cosmos DB Serverless beats a VM or App Service on cost **and** operational burden.
- **Scales to zero when idle** - `minReplicas: 0`. Accepted tradeoff: a cold-start delay on the
  first request after idle, deemed acceptable since this app isn't mission-critical.

## Current cost (`infracost scan .`)

| Resource | Monthly cost |
|---|---:|
| Container Registry (ACR Basic) | $5.00 |
| Cosmos DB (serverless) | $0.00* |
| Log Analytics Workspace | $0.00* |
| Monitor Action Group | $0.00 (free tier) |
| Everything else (14 resources) | $0.00 |
| **Total** | **~$5.00** |

\* Usage-based, not a hard $0 - see below.

## What Infracost can't see

Container App compute isn't Terraform-managed, so it's not in the table above.

- **Compute**: free up to 180k vCPU-sec / 360k GiB-sec / 2M requests per month. At `0.25 vCPU`,
  `minReplicas: 0`, this app stays inside that grant → effectively **$0**.
- **Cosmos RUs (Request Units)**: ~$0.25/million RUs, no minimum. This app's traffic is nowhere near 1M/month →
  effectively **$0**.
- **Log ingestion**: free up to 5GB/month - won't be hit at this scale.

**Bottom line: ~$5/month, ~100% attributable to ACR.**

> Scan also flagged Cosmos DB's `backup.storage_redundancy = Geo` as a cost-saving opportunity
> (up to 50% off backup storage). Not actioned here - tracked as a separate reliability tradeoff
> in `TODO.md`.

## Why not a VM or App Service?

| | Monthly cost | Scales to zero? | OS/patch burden |
|---|:---:|:---:|:---:|
| VM (`B1s` + disk + a database) | ~$9-15+ | No | Full burden |
| App Service (`B1`) + Cosmos DB | ~$13-18 | No (Basic tier) | None |
| **Container Apps + Cosmos Serverless (current)** | **~$5** | **Yes** | **None** |

**VM** - always-on 24/7 regardless of traffic, still need a database on top, and full OS
patching/security falls on whoever runs it (reopens the "tribal knowledge" problem this project
exists to fix - see `Notes.md` section 5).

**App Service** - managed, no OS patching, but Basic tier has no scale-to-zero (Premium does, at
much higher cost). Paying full price 24/7 for a tool used in bursts, not continuously.

**Current setup** - billed per second of actual use, zero replicas when idle. `minReplicas: 0`
was chosen deliberately: this app isn't mission-critical, so the occasional cold-start delay on
the first request after idle is an acceptable tradeoff for not paying for capacity nobody's
using. Cosmos DB serverless mirrors the same idea: RU-based billing with no 24/7 floor, vs.
provisioned throughput's **~$24/month minimum** regardless of traffic.

For a low/sporadic-traffic internal tool, consumption billing tracks real usage instead of
provisioned capacity - cheaper now, and scales predictably if usage grows.

---
*VM/App Service figures are Azure's published on-demand rates (not Infracost-computed, since
they're not real resources here) - representative for comparison, cross-check with the Pricing
Calculator for final numbers.*
