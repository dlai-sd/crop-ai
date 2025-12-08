#!/bin/bash

# Real-time monitoring dashboard for crop-ai
# Displays system metrics, service status, and pipeline progress

clear

echo "🔍 CROP-AI MONITORING DASHBOARD"
echo "======================================"
echo "Last Updated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m'

# Function to check service status
check_service() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $service (port $port)"
        return 0
    else
        echo -e "${RED}❌${NC} $service (port $port)"
        return 1
    fi
}

# Function to get git status
git_status() {
    cd /workspaces/crop-ai
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local commits_behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    local uncommitted=$(git status --porcelain | wc -l)
    
    echo "Branch: $branch"
    echo "Uncommitted: $uncommitted"
    echo "Ahead/Behind: $commits_ahead/$commits_behind"
}

# Function to get system resources
system_resources() {
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Memory
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    # Disk
    local disk_info=$(df -h / | tail -1)
    local disk_used=$(echo $disk_info | awk '{print $3}')
    local disk_total=$(echo $disk_info | awk '{print $2}')
    local disk_percent=$(echo $disk_info | awk '{print $5}' | sed 's/%//')
    
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory: ${mem_used}MB / ${mem_total}MB (${mem_percent}%)"
    echo "Disk: ${disk_used} / ${disk_total} (${disk_percent}%)"
}

# Function to check Docker containers
docker_status() {
    if command -v docker &> /dev/null; then
        local running=$(docker ps -q 2>/dev/null | wc -l)
        local total=$(docker ps -a -q 2>/dev/null | wc -l)
        echo "Docker Containers: $running/$total running"
        
        if [ $running -gt 0 ]; then
            docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -5
        fi
    else
        echo "Docker: Not installed"
    fi
}

# Function to check GitHub Actions
github_actions_status() {
    if command -v gh &> /dev/null; then
        local workflow_runs=$(gh run list --limit 5 2>/dev/null || echo "")
        if [ -n "$workflow_runs" ]; then
            echo "$workflow_runs" | head -5
        else
            echo "Unable to fetch workflow status"
        fi
    else
        echo "GitHub CLI: Not installed"
    fi
}

# Section: Services Status
echo -e "${BLUE}📊 SERVICES STATUS${NC}"
echo "────────────────────────────────────────"
check_service 5000 "FastAPI Backend"
check_service 8000 "Django Gateway"
check_service 4200 "Angular Frontend"
check_service 9090 "Prometheus"
check_service 3001 "Grafana"
check_service 3100 "Loki"
check_service 16686 "Jaeger"
check_service 9093 "AlertManager"
echo ""

# Section: System Resources
echo -e "${BLUE}💻 SYSTEM RESOURCES${NC}"
echo "────────────────────────────────────────"
system_resources
echo ""

# Section: Git Status
echo -e "${BLUE}📝 GIT STATUS${NC}"
echo "────────────────────────────────────────"
git_status
echo ""

# Section: Recent Commits
echo -e "${BLUE}📋 RECENT COMMITS${NC}"
echo "────────────────────────────────────────"
cd /workspaces/crop-ai
git log --oneline -5 2>/dev/null | while read commit msg; do
    echo "  $commit - $msg"
done
echo ""

# Section: Docker Status
echo -e "${BLUE}🐳 DOCKER STATUS${NC}"
echo "────────────────────────────────────────"
docker_status
echo ""

# Section: Log Summary
echo -e "${BLUE}📂 LOG FILES STATUS${NC}"
echo "────────────────────────────────────────"
for logfile in /tmp/crop-ai-logs/*.log; do
    if [ -f "$logfile" ]; then
        filename=$(basename "$logfile")
        size=$(du -h "$logfile" | awk '{print $1}')
        lines=$(wc -l < "$logfile")
        echo "  $filename: $size ($lines lines)"
    fi
done
echo ""

# Section: Alerts
echo -e "${BLUE}🚨 ACTIVE ALERTS${NC}"
echo "────────────────────────────────────────"
if curl -s http://localhost:9093/api/v1/alerts 2>/dev/null | jq '.data[]' 2>/dev/null | head -5; then
    echo "  (No critical alerts)"
else
    echo "  Unable to fetch alerts (AlertManager may not be running)"
fi
echo ""

# Section: Quick Links
echo -e "${BLUE}🔗 QUICK LINKS${NC}"
echo "────────────────────────────────────────"
echo "GitHub Repo: https://github.com/dlai-sd/crop-ai"
echo "GitHub Actions: https://github.com/dlai-sd/crop-ai/actions"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3001 (admin/admin)"
echo "Jaeger: http://localhost:16686"
echo ""

# Footer
echo "────────────────────────────────────────"
echo "Next update: $(date -d '+5 seconds' '+%H:%M:%S')"
echo "Press Ctrl+C to exit, or run 'watch -n 5 $0' for continuous monitoring"
