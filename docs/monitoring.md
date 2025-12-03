# Monitoring & Deployment Status

## Deployment Overview

Your crop-ai application is deployed to Azure Container Instances with the following setup:

### Infrastructure
- **Resource Group**: `crop-ai-rg`
- **Container Registry**: `cropaiacr.azurecr.io`
- **Container Service**: Azure Container Instances (ACI)
- **Region**: East US

### Container Configuration
- **Image**: `crop-ai:latest` (auto-updated on each main branch push)
- **CPU**: 1 core
- **Memory**: 1 GB
- **Port**: 8000 (HTTP server)
- **Restart Policy**: Always (restarts on failure)

## Monitoring Commands

### Check Deployment Status
```bash
# List all containers
az container list -g crop-ai-rg -o table

# Get detailed status of a specific container
az container show -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER>

# View container logs
az container logs -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER> --tail 20
```

### Automated Monitoring Script
```bash
# Run the monitoring script
./scripts/monitor_deployment.sh
```

This script shows:
- All active containers
- Container status and resource usage
- FQDN and exposed ports
- Recent container logs
- Available images in registry

### Check Image Registry
```bash
# List all images
az acr repository list --name cropaiacr

# List all tags for crop-ai image
az acr repository show-tags --name cropaiacr --repository crop-ai

# Get image metadata
az acr repository show --name cropaiacr --image crop-ai:latest
```

## How Deployment Works

1. **Push to main** → GitHub Actions triggered
2. **Tests** → Run on Python 3.10, 3.11, 3.12
3. **Build** → Docker image created
4. **Push** → Image pushed to ACR
5. **Deploy** → New container deployed to ACI

## Access Your Application

Once deployed, your container will be accessible at:
```
http://<FQDN>:8000/
```

To find the FQDN:
```bash
az container show -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER> \
  --query ipAddress.fqdn -o tsv
```

## Troubleshooting

### Container keeps restarting
Check logs:
```bash
az container logs -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER> --tail 50
```

### Container not starting
Verify image exists:
```bash
az acr repository show --name cropaiacr --image crop-ai:latest
```

### Check recent deployments
```bash
az container list -g crop-ai-rg -o table --query "[].{Name:name, Status:containers[0].instanceView.currentState.state, Created:containers[0].instanceView.createdTime}"
```

## Cost Management

To avoid unexpected charges:

### Stop a container
```bash
az container stop -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER>
```

### Delete a container
```bash
az container delete -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER> --yes
```

### List all containers for cleanup
```bash
az container list -g crop-ai-rg --query "[].name" -o tsv
```

### Delete all containers
```bash
az container list -g crop-ai-rg --query "[].name" -o tsv | xargs -I {} az container delete -g crop-ai-rg -n {} --yes
```

## Logs & Metrics

### View recent logs
```bash
az container logs -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER> --tail 100
```

### Follow logs in real-time
```bash
az container attach -g crop-ai-rg -n crop-ai-aci-<RUN_NUMBER>
```

## CI/CD Pipeline Status

Check the automated deployments:
- Go to: https://github.com/dlai-sd/crop-ai/actions
- Select the latest workflow run
- View build, test, and deployment logs

## Next Steps

1. **Monitor** - Run `./scripts/monitor_deployment.sh` regularly
2. **Access** - Use the container's FQDN to test the HTTP server
3. **Scale** - Update CPU/memory in `.github/workflows/ci.yml` as needed
4. **Integrate** - Add API endpoints to your application

