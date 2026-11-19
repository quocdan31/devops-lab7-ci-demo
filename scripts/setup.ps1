# scripts/setup.ps1 - Khoi dong Docker stack cho Lab 7 CI Pipeline
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Khoi dong Jenkins + Nexus + SonarQube " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Kiem tra Docker & Compose
docker compose version
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Docker Compose chua san sang!" -ForegroundColor Red
    exit 1
}

# Khoi dong stack
docker compose up -d

Write-Host "Dang cho cac services khoi dong..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Kiem tra containers
docker ps --filter "name=lab7-"

Write-Host "`nLuu y thong tin dang nhap ban dau:" -ForegroundColor Green
Write-Host "1. Jenkins Initial Password:" -ForegroundColor Green
docker exec lab7-jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>$null

Write-Host "`n2. Nexus Initial Password:" -ForegroundColor Green
docker exec lab7-nexus cat /nexus-data/admin.password 2>$null

Write-Host "`n3. URLs:" -ForegroundColor Green
Write-Host " - Jenkins:   http://localhost:8080"
Write-Host " - Nexus:     http://localhost:8081"
Write-Host " - SonarQube: http://localhost:9000"
