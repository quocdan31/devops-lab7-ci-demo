# scripts/verify.ps1 - Kiem tra trang thai Lab 7
Write-Host "=== 1. Kiem tra Containers ===" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=lab7-"

Write-Host "`n=== 2. Kiem tra Java & Maven Local ===" -ForegroundColor Cyan
$sampleApp = Join-Path $PSScriptRoot "..\sample-java-app"
Push-Location $sampleApp
mvn clean test
Pop-Location

Write-Host "`n=== 3. Kiem tra HTTP Endpoints ===" -ForegroundColor Cyan
@(
    @{ Name = "Jenkins";   Url = "http://localhost:8080" },
    @{ Name = "Nexus";     Url = "http://localhost:8081" },
    @{ Name = "SonarQube"; Url = "http://localhost:9000" }
) | ForEach-Object {
    try {
        $res = Invoke-WebRequest -Uri $_.Url -UseBasicParsing -TimeoutSec 5
        Write-Host "[$($_.Name)] OK - Status: $($res.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "[$($_.Name)] Chua san sang hoac loi ket noi" -ForegroundColor Yellow
    }
}
