# GitHub Secrets Setup Guide

This guide explains how to set up GitHub repository secrets needed for the CI/CD pipelines to work properly.

## How to Add Secrets

1. Go to your GitHub repository: `https://github.com/dlai-sd/crop-ai`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the name and value
5. Click **Add secret**

## Required Secrets

### 1. **Docker Hub Secrets** (for pushing to Docker Hub)
Required by: `manual-deploy.yml`

#### `DOCKER_HUB_USERNAME`
- **Description**: Your Docker Hub username
- **Obtain from**: https://hub.docker.com/settings/general
- **Example**: `yourname`

#### `DOCKER_HUB_PASSWORD`
- **Description**: Your Docker Hub personal access token (NOT your password)
- **Obtain from**: https://hub.docker.com/settings/security
- **Steps**:
  1. Log in to Docker Hub
  2. Go to Account Settings → Security
  3. Click "New Access Token"
  4. Name it "GitHub Actions"
  5. Select "Read, Write, Delete" permissions
  6. Copy the token

### 2. **Azure Container Registry (ACR) Secrets** (for pushing to Azure)
Required by: `ci.yml`, `deploy.yml`, `manual-deploy.yml`

#### `AZURE_CREDENTIALS`
- **Description**: Full Azure credentials for authentication
- **Obtain from**: Create via Azure CLI
- **Steps**:
  ```bash
  az ad sp create-for-rbac \
    --name "github-actions-crop-ai" \
    --role Contributor \
    --scopes /subscriptions/{subscription-id} \
    --sdk-auth
  ```
- **Value format** (JSON):
  ```json
  {
    "clientId": "xxx",
    "clientSecret": "xxx",
    "subscriptionId": "xxx",
    "tenantId": "xxx"
  }
  ```

#### `ACR_LOGIN_SERVER`
- **Description**: Your Azure Container Registry login server
- **Obtain from**: Azure Portal → Container Registries → Your registry → Login server
- **Example**: `cropairegistry.azurecr.io`

#### `ACR_USERNAME`
- **Description**: Admin username for ACR
- **Obtain from**: Azure Portal → Container Registries → Your registry → Access keys
- **Enable**: Check "Admin user" checkbox

#### `ACR_PASSWORD`
- **Description**: Admin password for ACR
- **Obtain from**: Azure Portal → Container Registries → Your registry → Access keys
- **Note**: This is one of the two passwords shown (either one works)

#### `AZURE_CLIENT_ID`
- **Description**: Service principal client ID
- **Obtain from**: Azure AD → App registrations → Your app → Application (client) ID
- **Or from**: The JSON output of `az ad sp create-for-rbac` above

#### `AZURE_TENANT_ID`
- **Description**: Azure tenant ID
- **Obtain from**: Azure AD → App registrations → Your app → Directory (tenant) ID
- **Or from**: The JSON output of `az ad sp create-for-rbac` above

#### `AZURE_SUBSCRIPTION_ID`
- **Description**: Azure subscription ID
- **Obtain from**: Azure Portal → Subscriptions
- **Or from**: The JSON output of `az ad sp create-for-rbac` above

### 3. **SonarQube Secrets** (optional, for code quality)
Required by: `manual-deploy.yml` (optional - pipeline continues if not set)

#### `SONARQUBE_HOST`
- **Description**: Your SonarQube server URL
- **Example**: `https://sonarqube.example.com`

#### `SONARQUBE_TOKEN`
- **Description**: SonarQube authentication token
- **Obtain from**: SonarQube → User menu → Security → Generate tokens

## Verification

After setting up secrets, you can verify they're working by:

1. Triggering a manual workflow: Go to **Actions** → **Manual Deploy** → **Run workflow**
2. Check the logs - you should see:
   - ✅ Docker build succeeds (build only if no secrets, or push if secrets present)
   - ✅ No "Username and password required" errors
   - ✅ Code quality checks pass

## Minimal Setup (Testing Only)

If you just want the pipeline to complete without pushing to registries:
- **No secrets needed!** The pipeline will:
  - Run all code quality checks
  - Run all unit tests
  - Build Docker images locally (without pushing)
  - Skip Docker push steps gracefully

## Full Setup (Production)

For full functionality with image pushing:
1. Set up Docker Hub secrets (if using Docker Hub)
2. Set up Azure credentials (if using Azure ACR)
3. Set up SonarQube secrets (optional)

## Troubleshooting

### Error: "Username and password required"
- This means the secret is not set or is empty
- Check that the secret name matches exactly (case-sensitive)
- Verify the value is not empty

### Error: "Invalid credentials"
- Double-check the secret value
- Ensure the token hasn't expired
- For Docker Hub, make sure you're using a Personal Access Token, not your password

### ACR Login Fails
- Verify ACR_LOGIN_SERVER is in correct format: `myregistry.azurecr.io`
- Confirm Admin user is enabled in Access keys
- Check that the username/password are correctly copied
