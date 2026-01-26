# MT5テスト準備スクリプト
# このスクリプトは、MT5でテストを実行するための準備を行います
# 実際のテスト実行は、MT5のGUIから手動で行う必要があります

param(
    [string]$ConfigFile = "active.json"
)

Write-Host "=== MT5 Test Preparation ===" -ForegroundColor Cyan
Write-Host ""

# MT5のデータディレクトリを取得
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName
Write-Host "Terminal: $terminalDir" -ForegroundColor Green
Write-Host ""

# 1. 設定ファイルをコピー
Write-Host "[1/3] Copying config file..." -ForegroundColor Yellow
$configSource = Join-Path $PSScriptRoot "..\ea\tests\$ConfigFile"
$configDest = Join-Path $terminalDir "MQL5\Files\strategy\$ConfigFile"

if (-not (Test-Path $configSource)) {
    Write-Host "Error: Config file not found: $configSource" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path (Split-Path $configDest) -Force | Out-Null
Copy-Item $configSource $configDest -Force
Write-Host "  Config: $configDest" -ForegroundColor Green
Write-Host ""

# 2. EAソースをコピー
Write-Host "[2/3] Copying EA source..." -ForegroundColor Yellow
$eaSource = Join-Path $PSScriptRoot "..\ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"

New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
Copy-Item $eaSource $eaDest -Force

# インクルードファイルもコピー
$includeSource = Join-Path $PSScriptRoot "..\ea\include"
$includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
Copy-Item $includeSource $includeDest -Recurse -Force
Write-Host "  EA: $eaDest" -ForegroundColor Green
Write-Host "  Include: $includeDest" -ForegroundColor Green
Write-Host ""

# 3. MT5を起動
Write-Host "[3/3] Starting MT5..." -ForegroundColor Yellow
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

if (Test-Path $mt5Path) {
    Start-Process $mt5Path
    Write-Host "  MT5 started" -ForegroundColor Green
} else {
    Write-Host "  Warning: MT5 not found at default location" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Preparation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. MT5で MetaEditor を開く (F4キー)" -ForegroundColor White
Write-Host "  2. Experts\StrategyBricks\StrategyBricks.mq5 を開く" -ForegroundColor White
Write-Host "  3. F7キーでコンパイル" -ForegroundColor White
Write-Host "  4. MT5で Strategy Tester を開く (Ctrl+R)" -ForegroundColor White
Write-Host "  5. 以下の設定でテスト実行:" -ForegroundColor White
Write-Host ""
Write-Host "     EA: Experts\StrategyBricks\StrategyBricks" -ForegroundColor Cyan
Write-Host "     Symbol: USDJPYm" -ForegroundColor Cyan
Write-Host "     Period: M1" -ForegroundColor Cyan
Write-Host "     Date: 2025.10.01 - 2025.12.31" -ForegroundColor Cyan
Write-Host "     Deposit: 1,000,000 JPY" -ForegroundColor Cyan
Write-Host "     Leverage: 1:100" -ForegroundColor Cyan
Write-Host ""
Write-Host "     Input Parameters:" -ForegroundColor Cyan
Write-Host "       InpConfigPath = strategy/$ConfigFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  6. Start ボタンをクリック" -ForegroundColor White
Write-Host ""
Write-Host "Results will be shown in the Strategy Tester window." -ForegroundColor Yellow
Write-Host ""
