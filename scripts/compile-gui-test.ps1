# Compile and run GUI config test
Write-Host "=== Compiling GUI Config Test ===" -ForegroundColor Cyan

# Find MT5
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

if (-not (Test-Path $mt5Path)) {
    Write-Host "Error: MT5 not found" -ForegroundColor Red
    exit 1
}

$metaeditorPath = Join-Path (Split-Path $mt5Path) "metaeditor64.exe"

# Find terminal directory
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName

# Copy test EA
Write-Host "Copying test EA..." -ForegroundColor Yellow
$testEA = "ea\src\TestGuiGeneratedConfigs.mq5"
$destEA = Join-Path $terminalDir "MQL5\Scripts\StrategyBricks\TestGuiGeneratedConfigs.mq5"
New-Item -ItemType Directory -Path (Split-Path $destEA) -Force | Out-Null
Copy-Item $testEA $destEA -Force

# Copy includes
$includeSource = "ea\include"
$includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
Copy-Item $includeSource $includeDest -Recurse -Force
Write-Host "  ✓ Files copied" -ForegroundColor Green

# Compile
Write-Host ""
Write-Host "Compiling..." -ForegroundColor Yellow
if (Test-Path $metaeditorPath) {
    $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList "/compile:`"$destEA`"","/log" -Wait -PassThru -WindowStyle Hidden
    
    $ex5Path = $destEA -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "  ✓ Compilation successful" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Compilation failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✗ MetaEditor not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Ready to Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run the test:" -ForegroundColor Yellow
Write-Host "1. Open MT5" -ForegroundColor White
Write-Host "2. Open Navigator (Ctrl+N)" -ForegroundColor White
Write-Host "3. Find Scripts > StrategyBricks > TestGuiGeneratedConfigs" -ForegroundColor White
Write-Host "4. Drag it to any chart" -ForegroundColor White
Write-Host "5. Check the Experts tab for results" -ForegroundColor White
Write-Host ""
Write-Host "Or run automatically:" -ForegroundColor Yellow
Write-Host "  Start-Process '$mt5Path'" -ForegroundColor Cyan
Write-Host ""
