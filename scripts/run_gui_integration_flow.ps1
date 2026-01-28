param(
    [string]$ConfigPath,
    [string]$Scenario = "recent-7d",
    [string]$ScenarioFile,
    [string]$SymbolBase,
    [string]$Timeframe,
    [string]$Start,
    [string]$End,
    [int]$Days = 0,
    [switch]$StopMt5,
    [bool]$Portable = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ConfigPath {
    param([string]$PathHint)

    if ($PathHint) {
        if (-not (Test-Path $PathHint)) {
            throw "Config path not found: $PathHint"
        }
        $resolved = (Resolve-Path $PathHint).Path
        if ($resolved -match "_results\\.json$") {
            $candidate = $resolved -replace "_results\\.json$", ".json"
            if (Test-Path $candidate) {
                return (Resolve-Path $candidate).Path
            }
            throw "Results file provided. Expected config at: $candidate"
        }
        return $resolved
    }

    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    $testsDir = Join-Path $repoRoot "ea\tests"
    $latest = Get-ChildItem -Path $testsDir -Filter "strategy_*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^strategy_\\d+\\.json$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw "No strategy_*.json found in $testsDir. Provide -ConfigPath."
    }

    return $latest.FullName
}

function Get-ScenarioMap {
    param([string]$Path)

    $default = @{
        "recent-7d"  = @{ symbol = "USDJPY"; timeframe = "M1"; days = 7 }
        "recent-30d" = @{ symbol = "USDJPY"; timeframe = "M1"; days = 30 }
    }

    $pathProvided = [bool]$Path
    if (-not $Path) {
        $Path = Join-Path $PSScriptRoot "scenarios\gui_integration_scenarios.json"
    }

    if (-not (Test-Path $Path)) {
        if ($pathProvided) {
            throw "Scenario file not found: $Path"
        }
        return $default
    }

    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    if (-not $content) {
        return $default
    }

    $parsed = $content | ConvertFrom-Json
    $map = @{}
    foreach ($prop in $parsed.PSObject.Properties) {
        $map[$prop.Name] = $prop.Value
    }
    foreach ($key in $default.Keys) {
        if (-not $map.ContainsKey($key)) {
            $map[$key] = $default[$key]
        }
    }
    return $map
}

function Get-ScenarioValue {
    param(
        [hashtable]$Map,
        [string]$Name,
        [string]$Field
    )

    if (-not $Map.ContainsKey($Name)) {
        return $null
    }
    $entry = $Map[$Name]
    if (-not $entry) {
        return $null
    }
    $prop = $entry.PSObject.Properties[$Field]
    if ($prop) {
        return $prop.Value
    }
    return $null
}

function Parse-DateUtc {
    param([string]$Value)
    if (-not $Value) {
        return $null
    }
    $dto = [DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
    return $dto.UtcDateTime
}

function Resolve-SymbolCandidate {
    param([string]$SymbolBaseValue)

    if (-not $SymbolBaseValue) {
        return $SymbolBaseValue
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        return $SymbolBaseValue
    }

    $script = @'
import MetaTrader5 as mt5
import sys

base = sys.argv[1]
if not mt5.initialize():
    print(base)
    sys.exit(0)

info = mt5.symbol_info(base)
symbol = base
if info is None or not getattr(info, "visible", False):
    symbols = mt5.symbols_get() or []
    candidates = [s for s in symbols if s.name.startswith(base)]
    visible = [s.name for s in candidates if getattr(s, "visible", False)]
    if visible:
        symbol = visible[0]
    elif candidates:
        symbol = candidates[0].name

print(symbol)
mt5.shutdown()
'@

    $resolved = $script | python - $SymbolBaseValue 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $resolved) {
        return $SymbolBaseValue
    }

    $lines = @(($resolved -split "`r?`n") | Where-Object { $_ -and ($_ -match '^[A-Za-z0-9._-]+$') })
    if ($lines.Count -eq 0) {
        return $SymbolBaseValue
    }
    return $lines[-1]
}

Write-Host "=== GUI Integration Flow ===" -ForegroundColor Cyan

$configPathResolved = Resolve-ConfigPath $ConfigPath
$configJson = Get-Content -Path $configPathResolved -Raw -Encoding UTF8 | ConvertFrom-Json

$scenarioMap = Get-ScenarioMap $ScenarioFile
$scenarioSymbol = Get-ScenarioValue $scenarioMap $Scenario "symbol"
$scenarioTimeframe = Get-ScenarioValue $scenarioMap $Scenario "timeframe"
$scenarioStart = Get-ScenarioValue $scenarioMap $Scenario "start"
$scenarioEnd = Get-ScenarioValue $scenarioMap $Scenario "end"
$scenarioDays = Get-ScenarioValue $scenarioMap $Scenario "days"

$symbolBaseValue = if ($SymbolBase) { $SymbolBase } elseif ($scenarioSymbol) { $scenarioSymbol } else { "USDJPY" }
$resolvedSymbol = Resolve-SymbolCandidate $symbolBaseValue
if ($resolvedSymbol -and $resolvedSymbol -ne $symbolBaseValue) {
    Write-Host "Resolved symbol: $resolvedSymbol (from $symbolBaseValue)" -ForegroundColor Gray
}
$symbolForEngine = if ($resolvedSymbol) { $resolvedSymbol } else { $symbolBaseValue }
$timeframeValue = if ($Timeframe) { $Timeframe } elseif ($scenarioTimeframe) { $scenarioTimeframe } elseif ($configJson.globalGuards.timeframe) { $configJson.globalGuards.timeframe } else { "M1" }

$startDate = Parse-DateUtc $Start
$endDate = Parse-DateUtc $End

if ($Start -or $End) {
    if (-not $startDate -or -not $endDate) {
        throw "Both -Start and -End are required when either is provided."
    }
} elseif ($scenarioStart -and $scenarioEnd) {
    $startDate = Parse-DateUtc $scenarioStart
    $endDate = Parse-DateUtc $scenarioEnd
} else {
    $daysValue = if ($Days -gt 0) { $Days } elseif ($scenarioDays) { [int]$scenarioDays } else { 7 }
    $endDate = (Get-Date).ToUniversalTime()
    $startDate = $endDate.AddDays(-$daysValue)
}

if ($startDate -ge $endDate) {
    throw "Invalid date range: start must be before end."
}

$startIso = $startDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
$endIso = $endDate.ToString("yyyy-MM-ddTHH:mm:ssZ")

$configDir = Split-Path $configPathResolved
$configBase = [System.IO.Path]::GetFileNameWithoutExtension($configPathResolved)
$resultsPath = Join-Path $configDir ("{0}_results.json" -f $configBase)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$engineExe = Join-Path $repoRoot "python\dist\backtest_engine.exe"
$engineScript = Join-Path $repoRoot "python\backtest_engine.py"

Write-Host "Config: $configPathResolved" -ForegroundColor Green
Write-Host "Scenario: $Scenario" -ForegroundColor Gray
Write-Host "Symbol base: $symbolBaseValue" -ForegroundColor Gray
Write-Host "Symbol (engine): $symbolForEngine" -ForegroundColor Gray
Write-Host "Timeframe: $timeframeValue" -ForegroundColor Gray
Write-Host "Range: $startIso - $endIso" -ForegroundColor Gray
Write-Host "Results: $resultsPath" -ForegroundColor Gray

Write-Host ""
Write-Host "[1/2] GUI backtest (engine)" -ForegroundColor Yellow
$engineArgs = @("--config", $configPathResolved, "--symbol", $symbolForEngine, "--timeframe", $timeframeValue, "--start", $startIso, "--end", $endIso, "--output", $resultsPath)

if (Test-Path $engineExe) {
    & $engineExe @engineArgs
} elseif (Test-Path $engineScript) {
    & "python" $engineScript @engineArgs
} else {
    throw "Backtest engine not found. Build python/dist/backtest_engine.exe first."
}

if ($LASTEXITCODE -ne 0) {
    throw "GUI backtest failed (exit code: $LASTEXITCODE)"
}

if (-not (Test-Path $resultsPath)) {
    throw "Results file not found: $resultsPath"
}

$resultsJson = Get-Content -Path $resultsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$testerSymbol = $resultsJson.metadata.symbol
if (-not $testerSymbol) {
    Write-Host "Warning: metadata.symbol not found. Falling back to symbol base." -ForegroundColor Yellow
    $testerSymbol = $symbolBaseValue
}

Write-Host ""
Write-Host "[2/2] MT5 Strategy Tester" -ForegroundColor Yellow
Write-Host "Tester symbol: $testerSymbol" -ForegroundColor Gray

if ($StopMt5) {
    $mt5 = Get-Process terminal64 -ErrorAction SilentlyContinue
    if ($mt5) {
        Write-Host "Stopping MT5..." -ForegroundColor Yellow
        $mt5 | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
} else {
    $mt5Running = Get-Process terminal64 -ErrorAction SilentlyContinue
    if ($mt5Running) {
        Write-Host "Warning: MT5 is running. Close it if tester config is ignored." -ForegroundColor Yellow
    }
}

$testerScript = Join-Path $PSScriptRoot "run_mt5_strategy_test.ps1"
if (-not (Test-Path $testerScript)) {
    throw "Tester script not found: $testerScript"
}

$testerFrom = $startDate.ToString("yyyy.MM.dd")
$testerTo = $endDate.ToString("yyyy.MM.dd")

& $testerScript -ConfigPath $configPathResolved -Symbol $testerSymbol -Period $timeframeValue -DateFrom $testerFrom -DateTo $testerTo -Portable:$Portable

Write-Host ""
Write-Host "Flow completed." -ForegroundColor Green
