#!/bin/bash

# Continuous monitoring every 3 minutes with detailed status

MONITOR_LOG="/tmp/crop-ai-deploy-monitor.log"
mkdir -p /tmp/crop-ai-logs

echo "🔍 Starting 3-minute interval monitoring..."
echo "Log file: $MONITOR_LOG"
echo ""

iteration=0
while true; do
    iteration=$((iteration + 1))
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "════════════════════════════════════════════════════════════════════════"
        echo "CROP-AI DEPLOYMENT MONITOR - Update #$iteration at $timestamp"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        
        # Check FastAPI Backend
        echo "📊 BACKEND (FastAPI - Port 5000):"
        if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "  ✅ Status: RUNNING"
            if curl -s http://localhost:5000/health 2>/dev/null | grep -q "healthy"; then
                echo "  ✅ Health Check: PASSED"
            else
                echo "  ⚠️  Health Check: Pending or failed"
            fi
            ps aux | grep -E "uvicorn.*5000" | grep -v grep | awk '{print "  PID:", $2, "Memory:", $6"KB", "CPU:", $3"%"}' || true
        else
            echo "  ❌ Status: NOT RUNNING"
        fi
        echo ""
        
        # Check Django Gateway
        echo "📊 DJANGO GATEWAY (Port 8000):"
        if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "  ✅ Status: RUNNING"
            if curl -s http://localhost:8000/ >/dev/null 2>&1; then
                echo "  ✅ Health Check: PASSED"
            else
                echo "  ⚠️  Health Check: Pending or failed"
            fi
            ps aux | grep -E "manage.py.*8000" | grep -v grep | awk '{print "  PID:", $2, "Memory:", $6"KB", "CPU:", $3"%"}' || true
        else
            echo "  ❌ Status: NOT RUNNING"
        fi
        echo ""
        
        # Check Angular Frontend
        echo "📊 ANGULAR FRONTEND (Port 4200):"
        if lsof -Pi :4200 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "  ✅ Status: RUNNING"
            if curl -s http://localhost:4200/ >/dev/null 2>&1; then
                echo "  ✅ Health Check: PASSED"
            else
                echo "  ⚠️  Health Check: Pending or failed"
            fi
            ps aux | grep "ng serve" | grep -v grep | awk '{print "  PID:", $2, "Memory:", $6"KB", "CPU:", $3"%"}' || true
        else
            echo "  ❌ Status: NOT RUNNING"
        fi
        echo ""
        
        # System Resources
        echo "💻 SYSTEM RESOURCES:"
        cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        mem_percent=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
        disk_percent=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
        echo "  CPU: ${cpu_idle}%"
        echo "  Memory: ${mem_percent}%"
        echo "  Disk: ${disk_percent}%"
        echo ""
        
        # Log files
        echo "�� LOG FILES:"
        for logfile in /tmp/crop-ai-logs/*.log; do
            if [ -f "$logfile" ]; then
                filename=$(basename "$logfile")
                size=$(du -h "$logfile" 2>/dev/null | awk '{print $1}')
                lines=$(wc -l < "$logfile" 2>/dev/null || echo "0")
                tail_msg=$(tail -1 "$logfile" 2>/dev/null)
                echo "  $filename:"
                echo "    Size: $size ($lines lines)"
                echo "    Last: $tail_msg"
            fi
        done
        echo ""
        
        # Open ports
        echo "🔌 OPEN PORTS:"
        lsof -i -P -n 2>/dev/null | grep LISTEN | grep -E ":5000|:8000|:4200|:9090|:3001" | while read line; do
            echo "  $line"
        done || echo "  (No crop-ai ports listening)"
        echo ""
        
        # Git status
        echo "📝 GIT STATUS:"
        cd /workspaces/crop-ai
        branch=$(git rev-parse --abbrev-ref HEAD)
        commit=$(git rev-parse --short HEAD)
        changes=$(git status --porcelain | wc -l)
        echo "  Branch: $branch"
        echo "  Latest: $commit"
        echo "  Changes: $changes files"
        echo ""
        
        # Docker status
        echo "🐳 DOCKER STATUS:"
        if command -v docker &> /dev/null; then
            running=$(docker ps -q 2>/dev/null | wc -l)
            total=$(docker ps -a -q 2>/dev/null | wc -l)
            echo "  Containers: $running/$total running"
            docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -3 || echo "  (No containers)"
        else
            echo "  Docker: Not available"
        fi
        echo ""
        
        # Summary
        echo "════════════════════════════════════════════════════════════════════════"
        backend_ok=false
        django_ok=false
        angular_ok=false
        
        lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1 && backend_ok=true
        lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 && django_ok=true
        lsof -Pi :4200 -sTCP:LISTEN -t >/dev/null 2>&1 && angular_ok=true
        
        if [ "$backend_ok" = true ] && [ "$django_ok" = true ] && [ "$angular_ok" = true ]; then
            echo "✅ ALL SERVICES RUNNING - Deployment Successful!"
        elif [ "$backend_ok" = true ] || [ "$django_ok" = true ] || [ "$angular_ok" = true ]; then
            echo "⚠️  PARTIAL DEPLOYMENT - Some services running"
        else
            echo "🔄 DEPLOYMENT IN PROGRESS - Waiting for services to start..."
        fi
        echo "Next check: $(date -d '+3 minutes' '+%H:%M:%S')"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        
    } | tee -a "$MONITOR_LOG"
    
    # Wait 3 minutes before next check
    sleep 180
done
