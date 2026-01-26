# Test backtest engine with embedded Python

Write-Host "=== Embedded Python Backtest Test ===" -ForegroundColor Cyan
Write-Host ""

# Embedded Python path
$pythonExe = "gui\python-embedded\python.exe"

if (-not (Test-Path $pythonExe)) {
    Write-Host "X Embedded Python not found: $pythonExe" -ForegroundColor Red
    exit 1
}

Write-Host "OK Embedded Python detected: $pythonExe" -ForegroundColor Green
Write-Host ""

# Check Python version
Write-Host "Python version:" -ForegroundColor Yellow
& $pythonExe --version
Write-Host ""

# Check MetaTrader5 library
Write-Host "MetaTrader5 library:" -ForegroundColor Yellow
& $pythonExe -c "import MetaTrader5; print('OK Installed')"
Write-Host ""

# Create test strategy config
Write-Host "Creating test strategy config..." -ForegroundColor Yellow

$testConfig = @{
    meta = @{
        formatVersion = "1.0"
        name = "Embedded Python Test Strategy"
        generatedBy = "Test Script"
        generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    globalGuards = @{
        timeframe = "M1"
        useClosedBarOnly = $true
        noReentrySameBar = $true
        maxPositionsTotal = 1
        maxPositionsPerSymbol = 1
        maxSpreadPips = 30.0
        session = @{
            enabled = $true
            windows = @(@{ start = "00:00"; end = "23:59" })
            weekDays = @{
                sun = $false; mon = $true; tue = $true
                wed = $true; thu = $true; fri = $true; sat = $false
            }
        }
    }
    strategies = @(
        @{
            id = "S1"
            name = "Test Strategy"
            enabled = $true
            priority = 10
            conflictPolicy = "firstOnly"
            directionPolicy = "both"
            entryRequirement = @{
                type = "OR"
                ruleGroups = @(
                    @{
                        id = "rulegroup-1"
                        type = "AND"
                        conditions = @(
                            @{ blockId = "filter.spreadMax#1" }
                            @{ blockId = "trend.maRelation#1" }
                        )
                    }
                )
            }
            lotModel = @{ type = "lot.fixed"; params = @{ lots = 0.1 } }
            riskModel = @{ type = "risk.fixedSLTP"; params = @{ slPips = 30; tpPips = 30 } }
            exitModel = @{ type = "exit.none"; params = @{} }
            nanpinModel = @{ type = "nanpin.off"; params = @{} }
        }
    )
    blocks = @(
        @{
            id = "filter.spreadMax#1"
            typeId = "filter.spreadMax"
            params = @{ maxSpreadPips = 30 }
        }
        @{
            id = "trend.maRelation#1"
            typeId = "trend.maRelation"
            params = @{
                period = 20
                maMethod = "SMA"
                appliedPrice = "CLOSE"
                relation = "above"
            }
        }
    )
}

$timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$configPath = "ea\tests\test_embedded_$timestamp.json"
$resultsPath = "ea\tests\test_embedded_results_$timestamp.json"

$configJson = $testConfig | ConvertTo-Json -Depth 10
# UTF-8 without BOM
[System.IO.File]::WriteAllText($configPath, $configJson, [System.Text.UTF8Encoding]::new($false))

Write-Host "OK Config file created: $configPath" -ForegroundColor Green
Write-Host ""

# Run backtest
Write-Host "Running backtest..." -ForegroundColor Yellow
Write-Host "  Note: Make sure MT5 terminal is running" -ForegroundColor Cyan
Write-Host ""

$symbol = "USDJPY"
$timeframe = "M1"
$startDate = "2024-01-01T00:00:00Z"
$endDate = "2024-01-31T23:59:59Z"

Write-Host "  Symbol: $symbol" -ForegroundColor Gray
Write-Host "  Timeframe: $timeframe" -ForegroundColor Gray
Write-Host "  Period: $startDate - $endDate" -ForegroundColor Gray
Write-Host ""

$args = @(
    "python\backtest_engine.py",
    "--config", $configPath,
    "--symbol", $symbol,
    "--timeframe", $timeframe,
    "--start", $startDate,
    "--end", $endDate,
    "--output", $resultsPath
)

Write-Host "Command:" -ForegroundColor Gray
Write-Host "  $pythonExe $($args -join ' ')" -ForegroundColor DarkGray
Write-Host ""

try {
    & $pythonExe @args
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "OK Backtest succeeded!" -ForegroundColor Green
        Write-Host ""
        
        if (Test-Path $resultsPath) {
            $results = Get-Content $resultsPath | ConvertFrom-Json
            
            Write-Host "=== Backtest Results ===" -ForegroundColor Cyan
            Write-Host "  Total trades: $($results.summary.totalTrades)" -ForegroundColor White
            Write-Host "  Winning trades: $($results.summary.winningTrades)" -ForegroundColor Green
            Write-Host "  Losing trades: $($results.summary.losingTrades)" -ForegroundColor Red
            Write-Host "  Win rate: $($results.summary.winRate)%" -ForegroundColor White
            Write-Host "  Total P/L: $($results.summary.totalProfitLoss)" -ForegroundColor $(if ($results.summary.totalProfitLoss -gt 0) { "Green" } else { "Red" })
            Write-Host ""
        }
    } else {
        Write-Host ""
        Write-Host "X Backtest failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "X Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Generated files:" -ForegroundColor Cyan
Write-Host "  - Config: $configPath" -ForegroundColor Gray
Write-Host "  - Results: $resultsPath" -ForegroundColor Gray
Write-Host ""
