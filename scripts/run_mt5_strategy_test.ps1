# MT5 Strategy Tester 自動実行スクリプト
# Usage: .\scripts\run_mt5_strategy_test.ps1 -ConfigFile "active.json" -Symbol "USDJPYm" -Period "M1"

param(
    [string]$ConfigFile = "active.json",
    [string]$ConfigPath,
    [string]$ExpertPath = "StrategyBricks\StrategyBricks",
    [string]$Symbol = "USDJPYm",
    [string]$Period = "M1",
    [string]$DateFrom = "2025.10.01",
    [string]$DateTo = "2025.12.31",
    [int]$Deposit = 1000000,
    [string]$Currency = "JPY",
    [int]$Leverage = 100,
    [bool]$Portable = $true,
    [string]$ReportPath,
    [string]$MT5Path = "C:\Program Files\MetaTrader 5\terminal64.exe",
    [bool]$SyncEA = $true
)

Write-Host "=== MT5 Strategy Tester 自動実行 ===" -ForegroundColor Cyan

$configFileName = $ConfigFile
if ($ConfigPath) {
    if (-not (Test-Path $ConfigPath -PathType Leaf)) {
        Write-Host "Error: Config path must be an existing file: $ConfigPath" -ForegroundColor Red
        exit 1
    }
    $configItem = Get-Item $ConfigPath
    $configSource = $configItem.FullName
    $configFileName = $configItem.Name
} else {
    $configSource = Join-Path $PSScriptRoot "..\ea\tests\$ConfigFile"
}

Write-Host "Config: $configFileName"
Write-Host "Expert: $ExpertPath"
Write-Host "Symbol: $Symbol"
Write-Host "Period: $Period"
$periodMap = @{
    "M1" = "1"; "M5" = "5"; "M15" = "15"; "M30" = "30";
    "H1" = "60"; "H4" = "240"; "D1" = "1440"
}
$periodValue = ""
if ($periodMap.ContainsKey($Period)) {
    $periodValue = $periodMap[$Period]
} elseif ($Period -match '^\d+$') {
    $periodValue = $Period
} else {
    throw "Invalid period '$Period'. Supported values are M1, M5, M15, M30, H1, H4, D1, or a number of minutes."
}

Write-Host "Tester Period: $periodValue"
Write-Host "Date: $DateFrom - $DateTo"
Write-Host ""

# MT5のデータディレクトリを取得
if (-not $MT5Path -or -not (Test-Path $MT5Path)) {
    Write-Host "Error: MT5 executable not found: $MT5Path" -ForegroundColor Red
    exit 1
}
if ($Portable) {
    $terminalDir = Split-Path $MT5Path
    Write-Host "Terminal (portable): $terminalDir" -ForegroundColor Green
} else {
    $mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
    $terminals = @(Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match "^[A-F0-9]{32}$" } | Sort-Object LastWriteTime -Descending)

    if ($terminals.Count -eq 0) {
        Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
        exit 1
    }

    $terminalDir = $terminals[0].FullName
    Write-Host "Terminal: $terminalDir" -ForegroundColor Green
}
# 設定ファイルをコピー
# Report file naming (default: same as config file)
$configBaseName = [System.IO.Path]::GetFileNameWithoutExtension($configFileName)
$reportIniValue = $configBaseName
if ($ReportPath) {
    $reportOutputPath = $ReportPath
    if (-not [System.IO.Path]::IsPathRooted($reportOutputPath)) {
        $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
        $reportOutputPath = Join-Path $repoRoot $reportOutputPath
    }
    if ([System.IO.Path]::GetExtension($reportOutputPath) -eq "") {
        $reportOutputPath = "$reportOutputPath.htm"
    }
    $reportIniValue = [System.IO.Path]::GetFileNameWithoutExtension($reportOutputPath)
} else {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    $reportOutputPath = Join-Path $repoRoot "ea\tests\results\$configBaseName.htm"
}
$reportDir = Split-Path $reportOutputPath
if ($reportDir) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}
Write-Host "Report (ini name): $reportIniValue" -ForegroundColor Gray
Write-Host "Report (output): $reportOutputPath" -ForegroundColor Gray
$configDest = Join-Path $terminalDir "MQL5\Files\strategy\$configFileName"

if (-not (Test-Path $configSource)) {
    Write-Host "Error: Config file not found: $configSource" -ForegroundColor Red
    exit 1
}

Write-Host "Copying config file..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path (Split-Path $configDest) -Force | Out-Null
Copy-Item $configSource $configDest -Force
Write-Host "Config copied to: $configDest" -ForegroundColor Green

# FILE_COMMON (MetaQuotes Common) 用にもコピー
$commonStrategyDir = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files\strategy"
New-Item -ItemType Directory -Path $commonStrategyDir -Force | Out-Null
$commonConfigDest = Join-Path $commonStrategyDir $configFileName
Copy-Item $configSource $commonConfigDest -Force
Write-Host "Config copied to common: $commonConfigDest" -ForegroundColor Green

# Strategy Tester (Agent) 用にもコピー
$testerRoot = Join-Path $terminalDir "Tester"
if (Test-Path $testerRoot) {
    $agentDirs = Get-ChildItem $testerRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Agent-*" }
    foreach ($agent in $agentDirs) {
        $agentStrategyDir = Join-Path $agent.FullName "Files\strategy"
        New-Item -ItemType Directory -Path $agentStrategyDir -Force | Out-Null
        $agentConfigDest = Join-Path $agentStrategyDir $configFileName
        Copy-Item $configSource $agentConfigDest -Force
        Write-Host "Config copied to agent: $agentConfigDest" -ForegroundColor Green
    }
}

# Create tester .set file to override InpConfigPath.
$testerProfilesDir = Join-Path $terminalDir "MQL5\\Profiles\\Tester"
New-Item -ItemType Directory -Path $testerProfilesDir -Force | Out-Null
$setFileName = "StrategyBricks_" + [System.IO.Path]::GetFileNameWithoutExtension($configFileName) + ".set"
$setPath = Join-Path $testerProfilesDir $setFileName
$setContent = @"
InpConfigPath=strategy/$configFileName
"@
$setContent | Out-File -FilePath $setPath -Encoding ASCII -Force
Write-Host "Tester .set created: $setPath" -ForegroundColor Green

# EAソースをコピー（初回のみ必要）
$eaSource = Join-Path $PSScriptRoot "..\ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"

if ($SyncEA -or -not (Test-Path $eaDest)) {
    Write-Host "Syncing EA source..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
    Copy-Item $eaSource $eaDest -Force

    # Sync include files
    $includeSource = Join-Path $PSScriptRoot "..\ea\include"
    $includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
    Copy-Item (Join-Path $includeSource "*") $includeDest -Recurse -Force
    Write-Host "EA source synced" -ForegroundColor Green
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
Expert=$ExpertPath
ExpertParameters=$setFileName
Symbol=$Symbol
Period=$periodValue
Model=0
ExecutionMode=0
Optimization=0
OptimizationCriterion=0
FromDate=$DateFrom
ToDate=$DateTo
ForwardMode=0
ForwardDate=$DateFrom
Report=$reportIniValue
ReplaceReport=1
ShutdownTerminal=1
Deposit=$Deposit
Currency=$Currency
Leverage=1:$Leverage
UseLocal=0
UseRemote=0
UseCloud=0

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
$arguments = @()
if ($Portable) {
    $arguments += "/portable"
}
$arguments += "/config:`"$iniPath`""
$arguments += "/tester"

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
$reportCandidates = @(
    (Join-Path $terminalDir "Tester\$reportIniValue.htm"),
    (Join-Path $terminalDir "$reportIniValue.htm")
)
$reportPath = $reportCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($reportPath) {
    if ($reportOutputPath) {
        Copy-Item $reportPath $reportOutputPath -Force
        $reportPath = $reportOutputPath
    }
    Write-Host ""
    Write-Host "=== Test Report ===" -ForegroundColor Cyan
    Write-Host "Report: $reportPath" -ForegroundColor Green
    
    # レポートから初期証拠金を抽出
    $reportContent = Get-Content $reportPath -Raw
    if ($reportContent -match '(?:\u521d\u671f\u8a3c\u62e0\u91d1|Initial\s+deposit):</td>\s*<td[^>]*><b>([^<]+)</b>') {
        $initialDeposit = $Matches[1].Trim()
        Write-Host "Initial deposit (report): $initialDeposit" -ForegroundColor Gray
        if ($initialDeposit -eq "0") {
            Write-Host "WARNING: Initial deposit is 0. The report may be from a failed or aborted run." -ForegroundColor Yellow
        }
    }
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
    Write-Host "Warning: Report file not found. Checked:" -ForegroundColor Yellow
    foreach ($candidate in $reportCandidates) {
        Write-Host "  - $candidate" -ForegroundColor Yellow
    }
}

Write-Host ""

# Summarize block evaluation from tester log (best-effort)
$summaryScript = Join-Path $PSScriptRoot "summarize_tester_log.py"
if (Test-Path $summaryScript) {
    $testerLogCandidates = @(
        (Join-Path $terminalDir "Tester\Agent-127.0.0.1-3000\logs")
    )
    if (-not $Portable) {
        $terminalId = Split-Path $terminalDir -Leaf
        $testerLogCandidates = @(
            (Join-Path $env:APPDATA "MetaQuotes\Tester\$terminalId\Agent-127.0.0.1-3000\logs")
        ) + $testerLogCandidates
    }
    $testerLogDir = $testerLogCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($testerLogDir) {
        $logFile = Get-ChildItem -Path $testerLogDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($logFile) {
            $summaryJson = Join-Path (Split-Path $reportOutputPath) ("{0}_block_summary.json" -f $reportIniValue)
            $summaryText = Join-Path (Split-Path $reportOutputPath) ("{0}_block_summary.txt" -f $reportIniValue)
            Write-Host "Summarizing block evaluation..." -ForegroundColor Yellow
            & python $summaryScript --log "$($logFile.FullName)" --config "$configSource" --json "$summaryJson" --text "$summaryText"
        } else {
            Write-Host "Warning: Tester log file not found in $testerLogDir" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: Tester log directory not found" -ForegroundColor Yellow
    }
}
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
