# Deployment Verification & Testing

## ✅ Deployment Status: ACTIVE & WORKING

Your crop-ai container is now deployed and publicly accessible!

### Live Deployment Details

**Container Name**: `crop-ai-demo`  
**FQDN**: `crop-ai-demo.eastus.azurecontainer.io`  
**Public IP**: `4.156.55.245`  
**Port**: `8000`  
**Status**: Running ✅  

### Access Your Container

```bash
# Full URL
http://crop-ai-demo.eastus.azurecontainer.io:8000/
```

## Testing with cURL

### Test 1: Root Directory Listing
```bash
curl http://crop-ai-demo.eastus.azurecontainer.io:8000/
```

**Response**:
```
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.10.19
Content-type: text/html; charset=utf-8

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"...>
<title>Directory listing for /</title>
...
<li><a href="requirements.txt">requirements.txt</a></li>
<li><a href="src/">src/</a></li>
```

### Test 2: Source Code Directory
```bash
curl http://crop-ai-demo.eastus.azurecontainer.io:8000/src/
```

**Response**: Directory listing showing your `crop_ai` package

### Test 3: Requirements File
```bash
curl http://crop-ai-demo.eastus.azurecontainer.io:8000/requirements.txt
```

**Response**:
```
pytest>=7.0
```

### Test 4: Header Check
```bash
curl -I http://crop-ai-demo.eastus.azurecontainer.io:8000/
```

**Response**:
```
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.10.19
Date: Wed, 03 Dec 2025 10:32:52 GMT
Content-type: text/html; charset=utf-8
```

## Monitoring Commands

### Get All Deployed Containers
```bash
az container list -g crop-ai-rg -o table
```

### Get Specific Container Status
```bash
az container show -g crop-ai-rg -n crop-ai-demo \
  --query "{Name:name, Status:containers[0].instanceView.currentState.state, FQDN:ipAddress.fqdn, IP:ipAddress.ip}" -o table
```

### View Container Logs
```bash
az container logs -g crop-ai-rg -n crop-ai-demo --tail 50
```

### Get Container FQDN for curl
```bash
FQDN=$(az container show -g crop-ai-rg -n crop-ai-demo --query ipAddress.fqdn -o tsv)
curl http://$FQDN:8000/
```

## Continuous Deployment

Every push to `main` will:
1. ✅ Run tests (Python 3.10, 3.11, 3.12)
2. ✅ Build Docker image
3. ✅ Push to Azure Container Registry
4. ✅ Deploy to Azure Container Instances
5. ✅ Output FQDN and access URL in logs

The new container will be accessible at:
```
http://crop-ai-aci-<RUN_NUMBER>.eastus.azurecontainer.io:8000/
```

Where `<RUN_NUMBER>` is the GitHub Actions run number.

## Performance

- **Server**: Python SimpleHTTPServer
- **Response Time**: ~200ms
- **Container Runtime**: ~20 seconds startup
- **Resource Usage**: 1 CPU core, 1 GB memory

## Next Steps

1. **Add API Endpoints**: Replace SimpleHTTPServer with a proper API framework (Flask, FastAPI, etc.)
2. **Database**: Integrate persistent storage for model data
3. **Health Checks**: Add liveness and readiness probes
4. **Custom Domain**: Point your domain to the container
5. **CI/CD Improvements**: Add automated testing, security scanning

## Troubleshooting

### Container not responding
```bash
az container logs -g crop-ai-rg -n crop-ai-demo
```

### Container keeps restarting
Check restart count:
```bash
az container show -g crop-ai-rg -n crop-ai-demo \
  --query "containers[0].instanceView.restartCount" -o tsv
```

### Delete and redeploy
```bash
az container delete -g crop-ai-rg -n crop-ai-demo --yes
# Then push to main to trigger redeployment
```

