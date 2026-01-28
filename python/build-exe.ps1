# Build backtest_engine.exe with PyInstaller

$ErrorActionPreference = "Stop"

Write-Host "=== Build backtest engine exe ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check PyInstaller
Write-Host "[1/4] Checking PyInstaller..." -ForegroundColor Yellow
python -m pip show pyinstaller | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK PyInstaller is installed" -ForegroundColor Green
}
else {
    Write-Host "  Installing PyInstaller..." -ForegroundColor Gray
    python -m pip install pyinstaller
    Write-Host "  OK PyInstaller installed" -ForegroundColor Green
}
Write-Host ""

# 2. Install dependencies
Write-Host "[2/4] Installing dependencies..." -ForegroundColor Yellow
python -m pip install -r requirements.txt
Write-Host "  OK Dependencies installed" -ForegroundColor Green
Write-Host ""

# 3. Build exe
Write-Host "[3/4] Building exe..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

# Build using spec file
python -m PyInstaller backtest_engine.spec --clean --noconfirm

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Build succeeded" -ForegroundColor Green
Write-Host ""

# 4. Verify
Write-Host "[4/4] Verifying exe..." -ForegroundColor Yellow
$exePath = Join-Path "dist" "backtest_engine.exe"

if (Test-Path $exePath) {
    Write-Host "  OK exe created: $exePath" -ForegroundColor Green

    # Show file size
    $fileSize = (Get-Item $exePath).Length / 1MB
    Write-Host "  File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray

    # Run --help
    Write-Host "  Testing exe..." -ForegroundColor Gray
    & $exePath --help 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK exe runs" -ForegroundColor Green
    }
    else {
        Write-Host "  WARNING exe test failed" -ForegroundColor Yellow
        Write-Host "  NOTE: This is expected without MT5 installed" -ForegroundColor Gray
    }
}
else {
    Write-Host "  ERROR exe not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "=== Build complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Generated exe: $exePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Launch GUI app and test backtest feature" -ForegroundColor Gray
Write-Host "  2. electron-builder will bundle exe for production builds" -ForegroundColor Gray
Write-Host ""
