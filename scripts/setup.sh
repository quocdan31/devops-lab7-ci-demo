#!/bin/bash
# scripts/setup.sh - Khoi dong Docker stack cho Lab 7 CI Pipeline

echo "=========================================="
echo " Khoi dong Jenkins + Nexus + SonarQube "
echo "=========================================="

docker compose up -d

echo "Dang cho cac services khoi dong..."
sleep 30

docker ps --filter "name=lab7-"

echo ""
echo "Jenkins Initial Admin Password:"
docker exec lab7-jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "(Jenkins dang khoi dong, vui long thu lai sau vai giay)"

echo ""
echo "Nexus Initial Admin Password:"
docker exec lab7-nexus cat /nexus-data/admin.password 2>/dev/null || echo "(Nexus dang khoi dong, vui long thu lai sau vai giay)"

echo ""
echo "URLs:"
echo " - Jenkins:   http://localhost:8080"
echo " - Nexus:     http://localhost:8081"
echo " - SonarQube: http://localhost:9000"
