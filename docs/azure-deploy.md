# Azure CI/CD deployment — setup guide

This project includes a GitHub Actions deploy job that uses a service principal for authentication. The job runs only on pushes to `main` and requires repository secrets.

## Architecture

The CI/CD pipeline:
1. **Test job** — runs `pytest` across Python versions, lint/format checks, and Docker build.
2. **Deploy job** (gated on `main`) — authenticates with a service principal, builds and pushes the container image to ACR, and deploys to Azure Web App.

## Required repository secrets

- `AZURE_CREDENTIALS` — JSON-formatted service principal credentials (recommended for production security).
- `ACR_LOGIN_SERVER` — the login server of your ACR (e.g., `myregistry.azurecr.io`).
- `AZURE_WEBAPP_NAME` — name of your Azure Web App configured for container deployment.

Alternative (less secure): if you prefer ACR admin credentials instead of a service principal:
- `ACR_USERNAME` and `ACR_PASSWORD` — admin username/password for ACR.
- `AZURE_WEBAPP_PUBLISH_PROFILE` — publish profile XML (deprecated; less secure).

## Quick setup (recommended: Service Principal)

### 1. Create Azure resources

```bash
# Create resource group
az group create -n crop-ai-rg -l eastus

# Create ACR (use Standard sku for better perf)
az acr create -n <ACR_NAME> -g crop-ai-rg --sku Standard

# Create App Service plan and Web App (Linux container)
az appservice plan create -g crop-ai-rg -n crop-ai-plan --is-linux --sku B1
az webapp create -g crop-ai-rg -p crop-ai-plan -n <WEBAPP_NAME> --deployment-container-image-name hello-world
```

Replace `<ACR_NAME>` with a unique registry name (e.g., `cropaiacr`).
Replace `<WEBAPP_NAME>` with a unique web app name.

### 2. Create a service principal for GitHub Actions (recommended)

```bash
# Create a service principal with Contributor role scoped to the resource group
az ad sp create-for-rbac \
  --name crop-ai-ci-sp \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/crop-ai-rg \
  --json-auth > azure-sp.json
```

This outputs a JSON file with `clientId`, `clientSecret`, `subscriptionId`, and `tenantId`. Copy the entire JSON content.

### 3. Add GitHub repository secrets

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Add the following secrets:

- **`AZURE_CREDENTIALS`**: paste the entire JSON content from `azure-sp.json`.
- **`ACR_LOGIN_SERVER`**: value is `<ACR_NAME>.azurecr.io`.
- **`AZURE_WEBAPP_NAME`**: your Web App name.

### 4. Grant the service principal access to ACR

```bash
# Get the service principal's object ID (use the clientId from azure-sp.json)
SP_OBJECT_ID=$(az ad sp show --id <CLIENT_ID_FROM_JSON> --query id -o tsv)

# Assign the AcrPush role to the service principal
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/crop-ai-rg/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

### 5. Test the pipeline

Push a commit to `main`. GitHub Actions will:
- Run tests, lint, and format checks.
- Build the Docker image.
- Log into Azure using the service principal.
- Push the image to ACR.
- Deploy the image to the Web App.

You can monitor the run in the **Actions** tab of your GitHub repository.

## Security best practices

- Use a service principal with minimal required scope (Contributor on the resource group, not subscription-wide).
- Use the `AcrPush` role for ACR access instead of admin credentials.
- Rotate secrets regularly (GitHub allows secret rotation; service principal credentials can be rotated via Azure CLI).
- For production, consider using GitHub Environments with required reviewers (`environment: production` enforces this).
- Keep the `azure-sp.json` file safe and never commit it to the repository.

## Troubleshooting

- **"Insufficient privileges to complete the operation"**: ensure the service principal has the Contributor role in the resource group.
- **"Failed to push to ACR"**: verify the `ACR_LOGIN_SERVER` secret and confirm the service principal has `AcrPush` role.
- **"Failed to login to Azure"**: verify the `AZURE_CREDENTIALS` JSON is correctly formatted (use `az ad sp show` to validate).
- **"Web App deployment failed"**: ensure `AZURE_WEBAPP_NAME` is correct and the Web App is configured for container deployment.

## Cleanup

To remove resources and service principal:

```bash
# Delete the resource group (removes ACR and Web App)
bash scripts/delete_crop_ai_rg.sh --yes

# Delete the service principal
SP_ID=$(jq -r '.clientId' < azure-sp.json)
az ad sp delete --id $SP_ID

# Remove GitHub secrets: use GitHub UI or
gh secret delete AZURE_CREDENTIALS -R <owner>/<repo>
gh secret delete ACR_LOGIN_SERVER -R <owner>/<repo>
gh secret delete AZURE_WEBAPP_NAME -R <owner>/<repo>
```

## Additional resources

- [GitHub Actions — Azure Login](https://github.com/Azure/login)
- [Azure Docs — Service Principal creation](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [Azure Docs — Role-Based Access Control](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli)
