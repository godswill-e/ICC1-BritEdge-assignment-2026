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
  - [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

## Terraform:
Create Terraform configuration 
- main.tf - Top level resources/configuration
- provider.tf - telling terraform which cloud service I'm using 
- Variables file
- Ouputs file -  Printing the output of what we've created after it has been created
- Subfiles for each resource for modularisation (Keeping code clean) and to easily keep track resources


### ARG - Azure Resource Graph
- KQL

### GitHub Actions for CICD
Terraform creates the Azure infrastructure:
- Resource Group/s
- Web App
- Database
- Storage
- Containers, etc

GitHub Actions deploys the application code:
- Detects a push/commit/PR to GitHub
- Builds the application
- Deploys it to the specific resource

Flow:

GitHub Repo -> Terraform -> Azure Resources Created

GitHub Repo -> GitHub Actions -> Deploy Code → Azure Web App

Terraform creates the environment; GitHub Actions puts the code into it.

## Azure Services to use:
1 Azure Container App running the Flask application

1 Azure Container Registry storing the Docker image

1 Azure Cosmos DB Account for NoSQL data

1 Cosmos DB Database and Container for storing jobs/users

1 Resource Group organising the entire solution

#### listOfAllowedLocations for resources
  ` "value": [
    "germanywestcentral",
    "uaenorth",
    "polandcentral",
    "italynorth",
    "spaincentral"
  ]`
      

## Cost optimisation and Other Solutions
[Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
After creating resources: check the real cost. Once the resources are deployed, Azure can show the actual cost and usage.

Go to:
- Azure Portal → Cost Management + Billing
- Cost analysis
- Filter by your Resource Group

Or using Infracost to estimate usage:
- [Infracost](https://www.infracost.io/docs/) integrates with Infrastructure as Code (IaC) pipelines to help you eliminate cloud waste and budget overruns before and after you deploy.
- It also checks that your resources are using the correct conventions for names and tags
- Create New branch for alternative that works but costs more to show the differences.


| Service | What you manage |
|---|---|
| Static Web Apps | Only static frontend files |
| Azure Functions | Small pieces of code triggered by events |
| Logic Apps | Workflows between services |
| App Service | A full web application |
| Container Apps | A containerised application |
| Container Instances | A single container |
| Kubernetes Service (AKS) | A full container orchestration platform |
| Spring Apps | Java Spring Boot applications |


# Azure Login Fix — GitHub Actions
To deploy via service principle to Azure student acc via CLI

### Problem

The GitHub Action's `azure/login` step was failing because the service principal Azure's Deployment Center auto-created had no role assignment and no credentials — the wizard created the SP object but silently failed on the next two setup steps.

## Fix

**1. Found the orphaned SP:**
```bash
az ad sp list --show-mine -o table
```

**2. Confirmed it had no roles or credentials:**
```bash
az role assignment list --assignee <appId> -o table
az ad app credential list --id <appId> -o table
az ad app federated-credential list --id <appId> -o table
```
All returned empty.

**3. Assigned it `Contributor` on the resource group:**
```bash
az role assignment create \
  --assignee <appId> \
  --role Contributor \
  --scope /subscriptions/<subscriptionId>/resourceGroups/BritEdge_DEV_RG
```

**4. Generated a client secret:**
```bash
az ad app credential reset --id <appId> --append
```

**5. Built the `AZURE_CREDENTIALS` JSON** from the output (`clientId`, `clientSecret`, `subscriptionId`, `tenantId`), and updated the `CONTAINERAPPBRITEDGE_AZURE_CREDENTIALS` GitHub secret with it.

## Result

The SP now had both the permissions and the credentials it was missing, so `azure/login` could authenticate successfully.