# scripts/cleanup.ps1 - Don dep containers Lab 7
Write-Host "Dang dung va go bo cac containers Lab 7..." -ForegroundColor Yellow
docker compose down

Write-Host "Trang thai containers sau khi don dep:" -ForegroundColor Green
docker ps -a --filter "name=lab7-"
