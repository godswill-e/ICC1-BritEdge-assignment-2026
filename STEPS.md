## Steps taken for assignment

1. Download azure CLI
    - Login
2. Fork the assignment repo
    - Created the folder structure for Terraform and github actions
    - Create branch/s for features that im working on
3. Creating Credentials for Terraform
    - Cannot create credentials for github actions due to student account limitations for Azure Entra ID
    - Terraform will use my az login credentials automatically
4. The chicken-and-egg problem: ACA requires a valid image reference at creation time, but you can't push an image until the ACR exists.
   - Solution: use a placeholder image in Terraform.
   - Terraform creates ACR + ACA using this public placeholder. Your GitHub Action then pushes the real image and updates the revision. Add ignore_changes so Terraform never fights with what CI deploys: