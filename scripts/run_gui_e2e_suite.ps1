param(
    [string]$E2EOutputDir,
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
$guiDir = Join-Path $repoRoot "gui"
$outputDir = if ($E2EOutputDir) {
    if ([System.IO.Path]::IsPathRooted($E2EOutputDir)) {
        $E2EOutputDir
    } else {
        Join-Path $repoRoot $E2EOutputDir
    }
} else {
    Join-Path $repoRoot "tmp\strategy-bricks-e2e"
}

Write-Host "=== GUI E2E + Integration Suite ===" -ForegroundColor Cyan
Write-Host "Output dir: $outputDir" -ForegroundColor Gray

$env:E2E_EXPORT_DIR = $outputDir

if (-not (Test-Path $guiDir)) {
    throw "GUI directory not found: $guiDir"
}

Push-Location $guiDir
try {
    Write-Host "Running GUI E2E (Playwright)..." -ForegroundColor Yellow
    cmd /c "npm run e2e"
    if ($LASTEXITCODE -ne 0) {
        throw "GUI E2E failed (exit code: $LASTEXITCODE)"
    }
} finally {
    Pop-Location
}

$suiteScript = Join-Path $PSScriptRoot "run_gui_integration_suite.ps1"
if (-not (Test-Path $suiteScript)) {
    throw "Suite script not found: $suiteScript"
}

Write-Host ""
Write-Host "Running integration suite on E2E outputs..." -ForegroundColor Yellow

& $suiteScript `
    -ConfigDir $outputDir `
    -Pattern "*.json" `
    -ExcludeActive `
    -Scenario $Scenario `
    -ScenarioFile $ScenarioFile `
    -SymbolBase $SymbolBase `
    -Timeframe $Timeframe `
    -Start $Start `
    -End $End `
    -Days $Days `
    -StopMt5:$StopMt5 `
    -Portable:$Portable `
    -ContinueOnError:$ContinueOnError
