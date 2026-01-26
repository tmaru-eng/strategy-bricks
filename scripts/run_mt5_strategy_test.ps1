# MT5 Strategy Tester 自動実行スクリプト
# Usage: .\scripts\run_mt5_strategy_test.ps1 -ConfigFile "active.json" -Symbol "USDJPYm" -Period "M1"

param(
    [string]$ConfigFile = "active.json",
    [string]$Symbol = "USDJPYm",
    [string]$Period = "M1",
    [string]$DateFrom = "2025.10.01",
    [string]$DateTo = "2025.12.31",
    [int]$Deposit = 1000000,
    [string]$Currency = "JPY",
    [int]$Leverage = 100,
    [string]$MT5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
)

Write-Host "=== MT5 Strategy Tester 自動実行 ===" -ForegroundColor Cyan
Write-Host "Config: $ConfigFile"
Write-Host "Symbol: $Symbol"
Write-Host "Period: $Period"
Write-Host "Date: $DateFrom - $DateTo"
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

# 設定ファイルをコピー
$configSource = Join-Path $PSScriptRoot "..\ea\tests\$ConfigFile"
$configDest = Join-Path $terminalDir "MQL5\Files\strategy\$ConfigFile"

if (-not (Test-Path $configSource)) {
    Write-Host "Error: Config file not found: $configSource" -ForegroundColor Red
    exit 1
}

Write-Host "Copying config file..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path (Split-Path $configDest) -Force | Out-Null
Copy-Item $configSource $configDest -Force
Write-Host "Config copied to: $configDest" -ForegroundColor Green

# EAソースをコピー（初回のみ必要）
$eaSource = Join-Path $PSScriptRoot "..\ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"

if (-not (Test-Path $eaDest)) {
    Write-Host "Copying EA source..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
    Copy-Item $eaSource $eaDest -Force
    
    # インクルードファイルもコピー
    $includeSource = Join-Path $PSScriptRoot "..\ea\include"
    $includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
    Copy-Item $includeSource $includeDest -Recurse -Force
    Write-Host "EA source copied" -ForegroundColor Green
}

# MT5のコンパイラでEAをコンパイル
$metaeditor = Join-Path (Split-Path $MT5Path) "metaeditor64.exe"
if (Test-Path $metaeditor) {
    Write-Host "Compiling EA..." -ForegroundColor Yellow
    & $metaeditor /compile:"$eaDest" /log | Out-Null
    Start-Sleep -Seconds 2
    
    $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "EA compiled successfully: $ex5Path" -ForegroundColor Green
    } else {
        Write-Host "Warning: EA compilation may have failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: MetaEditor not found, skipping compilation" -ForegroundColor Yellow
}

# テスター設定ファイルを作成
$iniPath = Join-Path $terminalDir "config\tester.ini"
$iniContent = @"
[Tester]
Expert=Experts\StrategyBricks\StrategyBricks
Symbol=$Symbol
Period=$Period
Model=0
ExecutionMode=0
Optimization=0
OptimizationCriterion=0
FromDate=$DateFrom
ToDate=$DateTo
ForwardMode=0
ForwardDate=$DateFrom
Report=report
ReplaceReport=1
ShutdownTerminal=1
Deposit=$Deposit
Currency=$Currency
Leverage=1:$Leverage
UseLocal=0
UseRemote=0
UseCloud=0

[Inputs]
InpConfigPath=strategy/$ConfigFile
"@

Write-Host "Creating tester config..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path (Split-Path $iniPath) -Force | Out-Null
$iniContent | Out-File -FilePath $iniPath -Encoding ASCII -Force
Write-Host "Tester config created: $iniPath" -ForegroundColor Green

# MT5を起動してテスト実行
Write-Host ""
Write-Host "Starting MT5 Strategy Tester..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

# MT5のコマンドライン引数
# /portable - ポータブルモード
# /config - 設定ファイル
$arguments = @(
    "/portable",
    "/config:`"$iniPath`""
)

Write-Host "Command: $MT5Path $($arguments -join ' ')" -ForegroundColor Gray
$process = Start-Process -FilePath $MT5Path -ArgumentList $arguments -PassThru

# プロセスが終了するまで待機
$timeout = 600 # 10分
$elapsed = 0
while (-not $process.HasExited -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "." -NoNewline
}
Write-Host ""

if ($process.HasExited) {
    Write-Host "MT5 test completed" -ForegroundColor Green
} else {
    Write-Host "Warning: Test timeout, stopping MT5..." -ForegroundColor Yellow
    Stop-Process -Id $process.Id -Force
}

# レポートを確認
$reportPath = Join-Path $terminalDir "Tester\report.htm"
if (Test-Path $reportPath) {
    Write-Host ""
    Write-Host "=== Test Report ===" -ForegroundColor Cyan
    Write-Host "Report: $reportPath" -ForegroundColor Green
    
    # レポートから取引回数を抽出
    $reportContent = Get-Content $reportPath -Raw
    if ($reportContent -match 'Total trades.*?(\d+)') {
        $totalTrades = $Matches[1]
        Write-Host "Total trades: $totalTrades" -ForegroundColor $(if ($totalTrades -eq "0") { "Red" } else { "Green" })
        
        if ($totalTrades -eq "0") {
            Write-Host ""
            Write-Host "WARNING: No trades executed!" -ForegroundColor Red
            Write-Host "Possible causes:" -ForegroundColor Yellow
            Write-Host "  1. Conditions are too strict (spread, session, trend filters)" -ForegroundColor Yellow
            Write-Host "  2. Block implementation issues" -ForegroundColor Yellow
            Write-Host "  3. Strategy configuration errors" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Check logs in: $terminalDir\MQL5\Logs" -ForegroundColor Yellow
        }
    }
    
    # レポートをブラウザで開く
    Start-Process $reportPath
} else {
    Write-Host "Warning: Report file not found: $reportPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
