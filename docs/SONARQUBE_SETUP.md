# SonarQube Setup Guide

SonarQube is optional but highly recommended for continuous code quality analysis. It provides detailed insights into code issues, vulnerabilities, and technical debt.

## Option 1: Using SonarQube Cloud (Free Tier - Recommended)

SonarQube Cloud is a free hosted service perfect for open source and small projects.

### Step 1: Create SonarQube Cloud Account
1. Go to https://sonarcloud.io
2. Click **Sign Up**
3. Choose **GitHub** as your login method
4. Authorize SonarCloud to access your GitHub account
5. You'll be logged in automatically

### Step 2: Import Your Repository
1. After login, click **Import an organization**
2. Select your GitHub organization
3. Choose **Free plan** if prompted
4. Find `crop-ai` repository and click **Set up**
5. Choose **GitHub Actions** as your CI system
6. Follow the setup wizard

### Step 3: Generate Token
1. Go to https://sonarcloud.io/account/security
2. Click **Generate Tokens**
3. Enter token name: `GitHub Actions`
4. Select **No expiration** (or set expiry date)
5. Click **Generate**
6. **Copy the token immediately** - you won't see it again!

### Step 4: Add to GitHub Secrets
1. Go to your GitHub repo: https://github.com/dlai-sd/crop-ai
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

**Secret 1: `SONARQUBE_HOST`**
- **Name**: `SONARQUBE_HOST`
- **Value**: `https://sonarcloud.io`
- Click **Add secret**

**Secret 2: `SONARQUBE_TOKEN`**
- **Name**: `SONARQUBE_TOKEN`
- **Value**: Paste the token you copied
- Click **Add secret**

### Step 5: Update Workflow (if using SonarCloud)
The current workflow is configured for self-hosted SonarQube. For SonarCloud, you may need to update it.

Current workflow file: `.github/workflows/manual-deploy.yml` (lines 44-50)

For SonarCloud, the configuration would be:
```yaml
env:
  SONAR_HOST_URL: https://sonarcloud.io
  SONAR_TOKEN: ${{ secrets.SONARQUBE_TOKEN }}
```

This is already set up correctly!

---

## Option 2: Self-Hosted SonarQube (Advanced)

If you have your own SonarQube server:

### Step 1: Get Your Server URL
- Your SonarQube server URL (e.g., `https://sonarqube.yourcompany.com`)

### Step 2: Generate Token
1. Log in to your SonarQube instance
2. Click your user avatar (top right) → **My Account**
3. Go to **Security** tab
4. Click **Generate Tokens**
5. Enter name: `GitHub Actions`
6. Click **Generate**
7. Copy the token

### Step 3: Add to GitHub Secrets
1. Go to your GitHub repo: https://github.com/dlai-sd/crop-ai
2. **Settings** → **Secrets and variables** → **Actions**
3. Add two secrets:

**Secret 1: `SONARQUBE_HOST`**
- **Value**: Your server URL (e.g., `https://sonarqube.yourcompany.com`)

**Secret 2: `SONARQUBE_TOKEN`**
- **Value**: The token you generated

---

## Verification

### Check if SonarQube is Working:
1. Trigger a workflow: **Actions** → **Manual Deploy** → **Run workflow**
2. Check the **Code Review & Analysis** job
3. Look for "SonarQube Scan" step
4. Should show either:
   - ✅ "Analysis Complete" (if secrets are set)
   - ⏭️ "Skipped" (if secrets are not set - this is OK, workflow continues)

### View Results:
- **SonarCloud**: https://sonarcloud.io/organizations/dlai-sd/projects
- **Self-Hosted**: `https://your-sonarqube-url/dashboard?id=crop-ai`

---

## What SonarQube Analyzes

Once set up, SonarQube will scan for:
- **Code Smells**: Maintainability issues
- **Vulnerabilities**: Security issues
- **Bugs**: Likely bugs in code
- **Coverage**: Unit test coverage
- **Duplications**: Code duplication
- **Technical Debt**: Overall code quality score

---

## Important Notes

### SonarQube Cloud (Recommended) Features:
- ✅ Free for public repositories
- ✅ Free for open source projects
- ✅ No server setup needed
- ✅ Beautiful dashboard
- ✅ GitHub integration

### Self-Hosted SonarQube:
- For enterprise use
- Requires server installation
- More control over data
- Not recommended for most projects

---

## Troubleshooting

### Error: "Skipped" in workflow
- This means secrets are not configured
- Set `SONARQUBE_HOST` and `SONARQUBE_TOKEN` secrets
- Workflow will automatically use them next run

### Error: "Invalid token"
- Token may have expired (for self-hosted)
- Generate a new token and update the secret

### Error: "Invalid host URL"
- Check URL format matches exactly
- For SonarCloud: must be `https://sonarcloud.io`
- For self-hosted: ensure URL is accessible

---

## Skip SonarQube (Optional)

If you don't want to use SonarQube:
- Leave the secrets unset
- Pipeline will skip the SonarQube step
- Everything else continues normally
- **This is perfectly fine!**

The workflow is configured to continue even if SonarQube fails or is not available.
