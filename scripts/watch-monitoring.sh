#!/bin/bash
# Continuous monitoring with periodic updates to file

MONITOR_LOG="/tmp/crop-ai-monitoring.log"

while true; do
    {
        echo "=== CROP-AI MONITORING UPDATE $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo ""
        
        # Services
        echo "📊 SERVICES:"
        for port_service in "5000:Backend" "8000:Django" "4200:Angular" "9090:Prometheus" "3001:Grafana"; do
            port=${port_service%:*}
            service=${port_service#*:}
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo "  ✅ $service"
            else
                echo "  ❌ $service"
            fi
        done
        
        # Resources
        echo ""
        echo "💻 RESOURCES:"
        echo "  CPU: $(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}')%"
        echo "  Memory: $(free | grep Mem | awk '{printf "%.0f%%\n", ($3/$2) * 100}')"
        echo "  Disk: $(df -h / | tail -1 | awk '{print $5}')"
        
        # Git status
        echo ""
        echo "📝 GIT:"
        cd /workspaces/crop-ai
        echo "  Branch: $(git rev-parse --abbrev-ref HEAD)"
        echo "  Changes: $(git status --porcelain | wc -l)"
        
        # Docker
        echo ""
        echo "🐳 DOCKER:"
        if command -v docker &> /dev/null; then
            echo "  Running: $(docker ps -q 2>/dev/null | wc -l) containers"
        fi
        
        echo ""
    } > "$MONITOR_LOG" 2>&1
    
    sleep 10
done
