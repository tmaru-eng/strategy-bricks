# MT5 Strategy Tester バッチ実行スクリプト
# 複数の設定ファイルを自動的にテストする

param(
    [string[]]$ConfigFiles = @(),
    [string]$Symbol = "USDJPYm",
    [string]$Period = "M1",
    [string]$DateFrom = "2025.10.01",
    [string]$DateTo = "2025.12.31",
    [int]$Deposit = 1000000,
    [string]$Currency = "JPY",
    [int]$Leverage = 100
)

Write-Host "=== MT5 Strategy Tester - Batch Execution ===" -ForegroundColor Cyan
Write-Host ""

# MT5のパスを取得
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

if (-not (Test-Path $mt5Path)) {
    Write-Host "Error: MT5 not found" -ForegroundColor Red
    exit 1
}

# MT5のデータディレクトリを取得
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName

# 設定ファイルリストを取得
if ($ConfigFiles.Count -eq 0) {
    $strategyDir = Join-Path $terminalDir "MQL5\Files\strategy"
    $ConfigFiles = Get-ChildItem $strategyDir -Filter "*.json" | Select-Object -ExpandProperty Name
}

Write-Host "Testing $($ConfigFiles.Count) configuration(s):" -ForegroundColor Green
foreach ($file in $ConfigFiles) {
    Write-Host "  - $file" -ForegroundColor Cyan
}
Write-Host ""

$results = @()

foreach ($configFile in $ConfigFiles) {
    Write-Host "--- Testing: $configFile ---" -ForegroundColor Yellow
    
    # テスター設定ファイルを作成
    $configName = [System.IO.Path]::GetFileNameWithoutExtension($configFile)
    $iniPath = Join-Path $terminalDir "config\tester_$configName.ini"
    
    $iniContent = @"
[Tester]
Expert=Experts\StrategyBricks\StrategyBricks
ExpertParameters=InpConfigPath=strategy/$configFile
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
Report=$configName
ReplaceReport=1
ShutdownTerminal=1
Deposit=$Deposit
Currency=$Currency
Leverage=1:$Leverage
UseLocal=0
UseRemote=0
UseCloud=0
"@

    New-Item -ItemType Directory -Path (Split-Path $iniPath) -Force | Out-Null
    $iniContent | Out-File -FilePath $iniPath -Encoding ASCII -Force
    
    Write-Host "  Config: $iniPath" -ForegroundColor Gray
    Write-Host "  Starting test..." -ForegroundColor Gray
    
    # MT5を起動してテスト実行
    $process = Start-Process -FilePath $mt5Path -ArgumentList "/config:`"$iniPath`"" -PassThru
    
    # プロセスが終了するまで待機（タイムアウト10分）
    $timeout = 600
    $elapsed = 0
    while (-not $process.HasExited -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host "." -NoNewline
    }
    Write-Host ""
    
    if ($process.HasExited) {
        Write-Host "  Test completed" -ForegroundColor Green
    } else {
        Write-Host "  Timeout, stopping MT5..." -ForegroundColor Yellow
        Stop-Process -Id $process.Id -Force
    }
    
    # レポートを確認
    $reportPath = Join-Path $terminalDir "Tester\$configName.htm"
    if (Test-Path $reportPath) {
        $reportContent = Get-Content $reportPath -Raw
        
        # 取引回数を抽出
        $totalTrades = 0
        if ($reportContent -match 'Total trades.*?(\d+)') {
            $totalTrades = [int]$Matches[1]
        }
        
        # 純利益を抽出
        $netProfit = 0
        if ($reportContent -match 'Total net profit.*?([-\d.]+)') {
            $netProfit = [double]$Matches[1]
        }
        
        Write-Host "  Total trades: $totalTrades" -ForegroundColor $(if ($totalTrades -eq 0) { "Red" } else { "Green" })
        Write-Host "  Net profit: $netProfit" -ForegroundColor $(if ($netProfit -lt 0) { "Red" } else { "Green" })
        
        $results += @{
            Config = $configFile
            TotalTrades = $totalTrades
            NetProfit = $netProfit
            ReportPath = $reportPath
            Success = $totalTrades -gt 0
        }
    } else {
        Write-Host "  Warning: Report not found" -ForegroundColor Yellow
        $results += @{
            Config = $configFile
            TotalTrades = 0
            NetProfit = 0
            ReportPath = ""
            Success = $false
        }
    }
    
    Write-Host ""
}

# 結果サマリー
Write-Host "=== Test Results Summary ===" -ForegroundColor Cyan
Write-Host ""

$successCount = ($results | Where-Object { $_.Success }).Count
$failCount = $results.Count - $successCount

Write-Host "Total: $($results.Count)" -ForegroundColor White
Write-Host "Success: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Success) { "✓" } else { "✗" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    
    Write-Host "$status $($result.Config)" -ForegroundColor $color
    Write-Host "  Trades: $($result.TotalTrades), Profit: $($result.NetProfit)" -ForegroundColor Gray
    if ($result.ReportPath) {
        Write-Host "  Report: $($result.ReportPath)" -ForegroundColor Gray
    }
    Write-Host ""
}

# レポートをブラウザで開く
if ($results.Count -gt 0 -and $results[0].ReportPath) {
    Write-Host "Opening first report in browser..." -ForegroundColor Yellow
    Start-Process $results[0].ReportPath
}

Write-Host "=== Batch Test Complete ===" -ForegroundColor Cyan
