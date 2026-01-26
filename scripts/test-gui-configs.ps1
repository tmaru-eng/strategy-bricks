# Quick test script for GUI-generated configs
Write-Host "=== Testing GUI-Generated Configs ===" -ForegroundColor Cyan
Write-Host ""

# Find MT5 terminal directory
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName
$filesDir = Join-Path $terminalDir "MQL5\Files\strategy"

# Copy GUI-generated configs
Write-Host "[1/2] Copying GUI-generated configs..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $filesDir -Force | Out-Null

$guiConfigs = @("basic-strategy.json", "trend-only.json", "multi-trigger.json")
foreach ($config in $guiConfigs) {
    $source = "ea\tests\$config"
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $filesDir $config) -Force
        Write-Host "  Copied: $config" -ForegroundColor Green
    }
}

# Verify files
Write-Host ""
Write-Host "[2/2] Verifying configs..." -ForegroundColor Yellow
foreach ($config in $guiConfigs) {
    $path = Join-Path $filesDir $config
    if (Test-Path $path) {
        $content = Get-Content $path -Raw | ConvertFrom-Json
        $blockCount = $content.blocks.Count
        $strategyCount = $content.strategies.Count
        Write-Host "  ✓ $config" -ForegroundColor Green
        Write-Host "    Strategies: $strategyCount, Blocks: $blockCount" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $config not found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Ready for EA Testing ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configs are ready at: $filesDir" -ForegroundColor White
Write-Host ""
Write-Host "To test in MT5:" -ForegroundColor Yellow
Write-Host "1. Open MT5 Strategy Tester (Ctrl+R)" -ForegroundColor White
Write-Host "2. Select EA: StrategyBricks" -ForegroundColor White
Write-Host "3. Set InpConfigPath to one of:" -ForegroundColor White
foreach ($config in $guiConfigs) {
    Write-Host "   - strategy/$config" -ForegroundColor Cyan
}
Write-Host ""
