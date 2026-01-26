# Strategy Bricks - 完全自動テストスクリプト
# GUIテスト → コンパイル → MT5テスト実行 → 結果レポート

param(
    [switch]$SkipGUITest = $false
)

Write-Host "=== Strategy Bricks - Fully Automated Test ===" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"

# MT5のパスを取得
$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

if (-not (Test-Path $mt5Path)) {
    Write-Host "Error: MT5 not found" -ForegroundColor Red
    exit 1
}

$metaeditorPath = Join-Path (Split-Path $mt5Path) "metaeditor64.exe"

# MT5のデータディレクトリを取得（最新のものを使用）
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' } | Sort-Object LastWriteTime -Descending

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName
$terminalId = Split-Path $terminalDir -Leaf
Write-Host "Using Terminal: $terminalId" -ForegroundColor Green
Write-Host ""

# ステップ1: GUIのe2eテストを実行
if (-not $SkipGUITest) {
    Write-Host "[Step 1/5] Running GUI e2e test..." -ForegroundColor Yellow
    Push-Location gui
    npm run e2e 2>&1 | Out-Null
    $e2eResult = $LASTEXITCODE
    Pop-Location

    if ($e2eResult -ne 0) {
        Write-Host "  Error: GUI e2e test failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "  PASS GUI e2e test completed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[Step 1/5] Skipping GUI test..." -ForegroundColor Gray
    Write-Host ""
}

# ステップ2: 生成されたファイルを確認
Write-Host "[Step 2/5] Checking generated files..." -ForegroundColor Yellow
$guiOutputDir = "$env:TEMP\strategy-bricks-e2e"

if (-not (Test-Path $guiOutputDir)) {
    Write-Host "  Error: Output directory not found" -ForegroundColor Red
    exit 1
}

$generatedFiles = Get-ChildItem $guiOutputDir -Filter "*.json" | Where-Object { $_.Name -ne "active.json" }
Write-Host "  PASS Found $($generatedFiles.Count) test config(s)" -ForegroundColor Green

$testConfigs = @()
foreach ($file in $generatedFiles) {
    Write-Host "    - $($file.Name)" -ForegroundColor Cyan
    $testConfigs += @{
        Name = $file.BaseName
        FileName = $file.Name
        Path = $file.FullName
    }
}
Write-Host ""

# ステップ3: MT5にファイルをコピー
Write-Host "[Step 3/5] Copying files to MT5..." -ForegroundColor Yellow

$mt5FilesDir = Join-Path $terminalDir "MQL5\Files\strategy"
New-Item -ItemType Directory -Path $mt5FilesDir -Force | Out-Null

foreach ($file in $generatedFiles) {
    $dest = Join-Path $mt5FilesDir $file.Name
    Copy-Item $file.FullName $dest -Force
}

$eaSource = "ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"
New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
Copy-Item $eaSource $eaDest -Force

$includeSource = "ea\include"
$includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
Copy-Item $includeSource $includeDest -Recurse -Force

Write-Host "  PASS Files copied" -ForegroundColor Green
Write-Host ""

# ステップ4: コンパイル
Write-Host "[Step 4/5] Compiling EA..." -ForegroundColor Yellow

if (Test-Path $metaeditorPath) {
    $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList "/compile:`"$eaDest`"","/log" -Wait -PassThru -WindowStyle Hidden
    
    $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "  PASS Compilation successful" -ForegroundColor Green
    } else {
        Write-Host "  FAIL Compilation failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  FAIL MetaEditor not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ステップ5: テスト実行
Write-Host "[Step 5/5] Running tests..." -ForegroundColor Yellow
Write-Host ""

$results = @()

foreach ($config in $testConfigs) {
    Write-Host "  Testing: $($config.Name)" -ForegroundColor Cyan
    
    # テスター設定ファイルを作成
    $iniPath = Join-Path $terminalDir "config\tester_$($config.Name).ini"
    
    $iniContent = @"
[Tester]
Expert=Experts\StrategyBricks\StrategyBricks
ExpertParameters=<parameters>InpConfigPath=strategy/$($config.FileName)</parameters>
Symbol=USDJPYm
Period=1
Model=0
ExecutionMode=0
Optimization=0
FromDate=2025.10.01
ToDate=2025.12.31
ForwardMode=0
Report=$($config.Name)
ReplaceReport=1
ShutdownTerminal=1
Deposit=1000000
Currency=JPY
Leverage=1:100
"@

    New-Item -ItemType Directory -Path (Split-Path $iniPath) -Force | Out-Null
    $iniContent | Out-File -FilePath $iniPath -Encoding ASCII -Force
    
    # MT5を起動してテスト実行
    $process = Start-Process -FilePath $mt5Path -ArgumentList "/config:`"$iniPath`"" -PassThru -WindowStyle Minimized
    
    # プロセスが終了するまで待機（タイムアウト5分）
    $timeout = 300
    $elapsed = 0
    while (-not $process.HasExited -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline
    }
    Write-Host ""
    
    if (-not $process.HasExited) {
        Write-Host "    Timeout, stopping..." -ForegroundColor Yellow
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    
    # レポートを確認
    Start-Sleep -Seconds 2
    $reportPath = Join-Path $terminalDir "Tester\$($config.Name).htm"
    
    if (Test-Path $reportPath) {
        $reportContent = Get-Content $reportPath -Raw -ErrorAction SilentlyContinue
        
        $totalTrades = 0
        if ($reportContent -match 'Total trades.*?(\d+)') {
            $totalTrades = [int]$Matches[1]
        }
        
        $netProfit = 0.0
        if ($reportContent -match 'Total net profit.*?([-\d.,]+)') {
            $profitStr = $Matches[1] -replace ',', ''
            $netProfit = [double]$profitStr
        }
        
        $status = if ($totalTrades -gt 0) { "PASS" } else { "FAIL" }
        $color = if ($totalTrades -gt 0) { "Green" } else { "Red" }
        
        Write-Host "    $status Trades: $totalTrades, Profit: $netProfit" -ForegroundColor $color
        
        $results += @{
            Config = $config.Name
            TotalTrades = $totalTrades
            NetProfit = $netProfit
            ReportPath = $reportPath
            Success = $totalTrades -gt 0
        }
    } else {
        Write-Host "    FAIL Report not found" -ForegroundColor Red
        $results += @{
            Config = $config.Name
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

Write-Host "Total Tests: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

Write-Host "Details:" -ForegroundColor Yellow
foreach ($result in $results) {
    $status = if ($result.Success) { "PASS" } else { "FAIL" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    
    Write-Host "  $status $($result.Config)" -ForegroundColor $color
    Write-Host "      Trades: $($result.TotalTrades)" -ForegroundColor Gray
    Write-Host "      Profit: $($result.NetProfit)" -ForegroundColor Gray
    if ($result.ReportPath -and (Test-Path $result.ReportPath)) {
        Write-Host "      Report: $($result.ReportPath)" -ForegroundColor Gray
    }
    Write-Host ""
}

# 最初のレポートをブラウザで開く
$firstReport = $results | Where-Object { $_.ReportPath -and (Test-Path $_.ReportPath) } | Select-Object -First 1
if ($firstReport) {
    Write-Host "Opening report in browser..." -ForegroundColor Yellow
    Start-Process $firstReport.ReportPath
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan

# 失敗があれば終了コード1
if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Some tests failed (0 trades)" -ForegroundColor Yellow
    Write-Host "Check the reports for details." -ForegroundColor Yellow
    exit 1
}

exit 0
