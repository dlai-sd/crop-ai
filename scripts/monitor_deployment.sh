#!/bin/bash
# Monitor Azure Container Instances deployment

RESOURCE_GROUP="crop-ai-rg"

echo "=== Monitoring crop-ai Deployment ==="
echo ""

# Get all containers
echo "Active Containers:"
az container list -g $RESOURCE_GROUP -o table --query "[].{Name:name, Status:containers[0].instanceView.currentState.state, Restarts:containers[0].instanceView.restartCount, CPU:containers[0].resources.requests.cpu, Memory:containers[0].resources.requests.memoryInGb}"

echo ""
echo "Container Details:"
for container in $(az container list -g $RESOURCE_GROUP -o tsv --query "[].name"); do
  echo ""
  echo "=== $container ==="
  az container show -g $RESOURCE_GROUP -n $container \
    --query "{Name:name, Status:containers[0].instanceView.currentState.state, FQDN:ipAddress.fqdn, Ports:ipAddress.ports, CreatedTime:containers[0].instanceView.createdTime}" -o table
  
  echo "Recent Logs:"
  az container logs -g $RESOURCE_GROUP -n $container --tail 10 || echo "(No logs yet)"
done

echo ""
echo "=== Image Registry Info ==="
az acr repository list --name cropaiacr -o table
echo ""
echo "Latest Image Tag:"
az acr repository show-tags --name cropaiacr --repository crop-ai --top 5 -o table
