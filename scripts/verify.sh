#!/bin/bash
# scripts/verify.sh - Kiem tra trang thai Lab 7

echo "=== 1. Kiem tra Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=lab7-"

echo ""
echo "=== 2. Kiem tra Java & Maven Local ==="
cd "$(dirname "$0")/../sample-java-app" || exit 1
mvn clean test

echo ""
echo "=== 3. Kiem tra HTTP Endpoints ==="
for svc in "Jenkins:http://localhost:8080" "Nexus:http://localhost:8081" "SonarQube:http://localhost:9000"; do
    NAME=${svc%%:*}
    URL=${svc#*:}
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL" || echo "000")
    echo "[$NAME] ($URL) - HTTP Code: $HTTP_CODE"
done
