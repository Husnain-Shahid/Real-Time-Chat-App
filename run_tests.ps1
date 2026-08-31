Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "         Running Flutter CI Test Suite Locally" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Fetching dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] flutter pub get failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "[2/3] Running Static Analysis..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] flutter analyze detected issues!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "[3/3] Running Unit, Widget, Mock and Integration Tests..." -ForegroundColor Yellow
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] One or more tests failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   SUCCESS: All Flutter CI Tests Passed Successfully!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
