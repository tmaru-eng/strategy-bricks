param(
    [string]$ConfigDir,
    [string]$Pattern = "strategy_*.json",
    [switch]$AllJson,
    [switch]$ExcludeActive,
    [string]$Scenario = "recent-7d",
    [string]$ScenarioFile,
    [string]$SymbolBase,
    [string]$Timeframe,
    [string]$Start,
    [string]$End,
    [int]$Days = 0,
    [switch]$StopMt5,
    [bool]$Portable = $false,
    [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$targetDir = if ($ConfigDir) {
    if (Test-Path $ConfigDir) {
        (Resolve-Path $ConfigDir).Path
    } else {
        $candidate = Join-Path $repoRoot $ConfigDir
        if (-not (Test-Path $candidate)) {
            throw "ConfigDir not found: $ConfigDir"
        }
        (Resolve-Path $candidate).Path
    }
} else {
    Join-Path $repoRoot "ea\tests"
}

Write-Host "=== GUI Integration Suite ===" -ForegroundColor Cyan
Write-Host "ConfigDir: $targetDir" -ForegroundColor Gray
Write-Host "Scenario: $Scenario" -ForegroundColor Gray

$filterLabel = if ($AllJson) { "*.json" } else { $Pattern }
$files = Get-ChildItem -Path $targetDir -File -ErrorAction SilentlyContinue
$configs = if ($AllJson) {
    $files | Where-Object { $_.Name -like "*.json" }
} else {
    $files | Where-Object { $_.Name -like $Pattern }
}
$configs = @(
    $configs |
        Where-Object { $_.Name -notlike "*_results.json" } |
        Where-Object { -not $ExcludeActive -or $_.Name -ne "active.json" } |
        Sort-Object Name
)

Write-Host "Candidates: $($configs.Count)" -ForegroundColor Gray
foreach ($cfg in $configs) {
    Write-Host "  - $($cfg.Name)" -ForegroundColor DarkGray
}

if (-not $configs -or $configs.Count -eq 0) {
    throw "No config files found in $targetDir (filter: $filterLabel)"
}

$flowScript = Join-Path $PSScriptRoot "run_gui_integration_flow.ps1"
if (-not (Test-Path $flowScript)) {
    throw "Flow script not found: $flowScript"
}

$success = @()
$failed = @()

foreach ($config in $configs) {
    Write-Host ""
    Write-Host ">>> Running: $($config.FullName)" -ForegroundColor Yellow

    try {
        & $flowScript -ConfigPath $config.FullName -Scenario $Scenario -ScenarioFile $ScenarioFile -SymbolBase $SymbolBase -Timeframe $Timeframe -Start $Start -End $End -Days $Days -StopMt5:$StopMt5 -Portable:$Portable
        if ($LASTEXITCODE -eq 0) {
            $success += $config.FullName
        } else {
            $failed += $config.FullName
            if (-not $ContinueOnError) {
                throw "Flow failed for $($config.FullName)"
            }
        }
    } catch {
        $failed += $config.FullName
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if (-not $ContinueOnError) {
            throw
        }
    }
}

Write-Host ""
Write-Host "=== Suite Summary ===" -ForegroundColor Cyan
Write-Host "Success: $($success.Count)" -ForegroundColor Green
Write-Host "Failed: $($failed.Count)" -ForegroundColor $(if ($failed.Count -gt 0) { "Red" } else { "Green" })

if ($failed.Count -gt 0) {
    Write-Host "Failed configs:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
