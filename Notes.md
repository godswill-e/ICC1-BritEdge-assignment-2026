# Notes for 
ICC1-BritEdge-assignment-2026 

- [Forked Repo](https://github.com/godswill-e/ICC1-BritEdge-assignment-2026/tree/main)
- [Main Repo](https://github.com/Ada-Apprenticeships/ICC1-BritEdge-assignment-2026)
- [Assignment Doc](https://docs.google.com/document/d/1Hu925tlfzn7OUAINB0maNzSgo_XsUTHQuZDNpNgAXek/edit?tab=t.0)
- [Labs](https://docs.google.com/document/d/1vdpeQEqq-bGNqyv0sRaso-UDMc295THiHCJ-BpHMM8w/edit?tab=t.q546ozbnk7s7)
- References:
  - [Terraform Tutorial](https://www.youtube.com/watch?v=YcJ9IeukJL8)
  - [Iac & DevOps](https://www.youtube.com/watch?v=9GXKjDJNB9s)
  - [Terraform Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/)
## Terraform Phases:
Create Terraform configuration 
- Main.tf
- Variables file
- Ouputs file


### ARG - Azure Resource Graph
- KQL

### GitHub Actions for CICD
Terraform creates the Azure infrastructure:
- Resource Group
- Web App
- Database
- Storage, etc.

GitHub Actions deploys the application code:
- Detects a push to GitHub
- Builds the application
- Deploys it to the specific Azure Web App

Flow:

GitHub Repo -> Terraform -> Azure Resources Created

GitHub Repo -> GitHub Actions -> Deploy Code → Azure Web App

Terraform creates the environment; GitHub Actions puts the code into it.

## Azure Services to use:
Containers, Kubernetes?

"listOfAllowedLocations": {
        "value": [
          "germanywestcentral",
          "uaenorth",
          "polandcentral",
          "italynorth",
          "spaincentral"
        ]
      }