# Strategy Bricks EA - Compile and test script

Write-Host "=== Strategy Bricks EA - Compile and Test All ===" -ForegroundColor Cyan
Write-Host ""

# Resolve MT5 paths
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

if (-not (Test-Path $mt5Path)) {
    Write-Host "Error: MT5 not found" -ForegroundColor Red
    exit 1
}

$metaeditorPath = Join-Path (Split-Path $mt5Path) "metaeditor64.exe"

# Resolve MT5 data directory
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName
Write-Host "Terminal: $terminalDir" -ForegroundColor Green
Write-Host ""

# Step 1: Copy files
Write-Host "[Step 1/4] Copying files..." -ForegroundColor Yellow

# Copy config files
$testFiles = @("active.json", "test_single_blocks.json", "test_single_blocks_extra.json", "test_strategy_advanced.json", "test_strategy_all_blocks.json")
foreach ($file in $testFiles) {
    $source = "ea\tests\$file"
    $dest = Join-Path $terminalDir "MQL5\Files\strategy\$file"
    
    if (Test-Path $source) {
        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        Copy-Item $source $dest -Force
        Write-Host "  Copied: $file" -ForegroundColor Green
    } else {
        Write-Host "  Warning: $file not found" -ForegroundColor Yellow
    }
}

# Copy EA source
$eaSource = "ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"
New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
Copy-Item $eaSource $eaDest -Force
Write-Host "  Copied: EA source" -ForegroundColor Green

# Copy include files
$includeSource = "ea\include"
$includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
Copy-Item $includeSource $includeDest -Recurse -Force
Write-Host "  Copied: Include files" -ForegroundColor Green
Write-Host ""

# Step 2: Compile
Write-Host "[Step 2/4] Compiling EA..." -ForegroundColor Yellow

if (Test-Path $metaeditorPath) {
    $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList "/compile:`"$eaDest`"","/log" -Wait -PassThru -WindowStyle Hidden
    
    $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "  Compilation successful: $ex5Path" -ForegroundColor Green
    } else {
        Write-Host "  Error: Compilation failed" -ForegroundColor Red
        Write-Host "  Check MetaEditor logs for details" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  Error: MetaEditor not found at $metaeditorPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Test configurations
Write-Host "[Step 3/4] Test configurations:" -ForegroundColor Yellow
Write-Host ""

$testConfigs = @(
    @{
        Name = "active.json"
        Description = "Basic sanity check"
        ExpectedTrades = '10-50'
    },
    @{
        Name = "test_single_blocks.json"
        Description = "Single-block unit tests (critical)"
        ExpectedTrades = '50-200'
    },
    @{
        Name = "test_single_blocks_extra.json"
        Description = "Single-block tests beyond MAX_STRATEGIES"
        ExpectedTrades = '1-20'
    },
    @{
        Name = "test_strategy_advanced.json"
        Description = "Advanced strategy integration"
        ExpectedTrades = '5-30'
    },
    @{
        Name = "test_strategy_all_blocks.json"
        Description = "All blocks comprehensive"
        ExpectedTrades = '3-20'
    }
)

for ($i = 0; $i -lt $testConfigs.Count; $i++) {
    $config = $testConfigs[$i]
    Write-Host "  [$($i+1)] $($config.Name)" -ForegroundColor Cyan
    Write-Host "      $($config.Description)" -ForegroundColor White
    Write-Host "      Expected trades: $($config.ExpectedTrades)" -ForegroundColor Gray
    Write-Host ""
}

# Step 4: Launch MT5 for manual testing
Write-Host "[Step 4/4] Starting MT5 for manual testing..." -ForegroundColor Yellow
Start-Process $mt5Path
Write-Host "  MT5 started" -ForegroundColor Green
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run tests in MT5 Strategy Tester:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open Strategy Tester (Ctrl+R)" -ForegroundColor White
Write-Host "2. Settings:" -ForegroundColor White
Write-Host "   - EA: Experts\StrategyBricks\StrategyBricks" -ForegroundColor Cyan
Write-Host "   - Symbol: USDJPYm" -ForegroundColor Cyan
Write-Host "   - Period: M1" -ForegroundColor Cyan
Write-Host "   - Date: 2025.10.01 - 2025.12.31" -ForegroundColor Cyan
Write-Host "   - Deposit: 1,000,000 JPY" -ForegroundColor Cyan
Write-Host "   - Leverage: 1:100" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Input Parameters:" -ForegroundColor White
Write-Host "   - InpConfigPath = strategy/[config file]" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Run each config:" -ForegroundColor White
foreach ($config in $testConfigs) {
    Write-Host "   - $($config.Name)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "5. Verify results:" -ForegroundColor White
Write-Host "   - Trades are within expected range" -ForegroundColor Gray
Write-Host "   - If trades are 0, check logs" -ForegroundColor Gray
Write-Host ""
Write-Host ""
Write-Host "Recommended order: test_single_blocks.json -> test_single_blocks_extra.json -> active.json -> advanced -> all_blocks" -ForegroundColor Yellow
