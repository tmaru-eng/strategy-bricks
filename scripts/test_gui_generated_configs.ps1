# GUIで生成した設定ファイルをEAでテストするスクリプト

Write-Host "=== GUI Generated Configs Test ===" -ForegroundColor Cyan
Write-Host ""

# ステップ1: GUIのe2eテストを実行して設定ファイルを生成
Write-Host "[Step 1/4] Running GUI e2e test..." -ForegroundColor Yellow
Push-Location gui
npm run e2e
$e2eResult = $LASTEXITCODE
Pop-Location

if ($e2eResult -ne 0) {
    Write-Host "Error: GUI e2e test failed" -ForegroundColor Red
    exit 1
}
Write-Host "  GUI e2e test completed" -ForegroundColor Green
Write-Host ""

# ステップ2: 生成されたファイルを確認
Write-Host "[Step 2/4] Checking generated files..." -ForegroundColor Yellow
$guiOutputDir = "$env:TEMP\strategy-bricks-e2e"

if (-not (Test-Path $guiOutputDir)) {
    Write-Host "Error: Output directory not found: $guiOutputDir" -ForegroundColor Red
    exit 1
}

$generatedFiles = Get-ChildItem $guiOutputDir -Filter "*.json" | Where-Object { $_.Name -ne "active.json" }
Write-Host "  Found $($generatedFiles.Count) test config(s)" -ForegroundColor Green

foreach ($file in $generatedFiles) {
    Write-Host "    - $($file.Name)" -ForegroundColor Cyan
}
Write-Host ""

# ステップ3: MT5にファイルをコピー
Write-Host "[Step 3/4] Copying files to MT5..." -ForegroundColor Yellow

$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' }

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

$terminalDir = $terminals[0].FullName
$mt5FilesDir = Join-Path $terminalDir "MQL5\Files\strategy"
New-Item -ItemType Directory -Path $mt5FilesDir -Force | Out-Null

# 生成されたファイルをコピー
foreach ($file in $generatedFiles) {
    $dest = Join-Path $mt5FilesDir $file.Name
    Copy-Item $file.FullName $dest -Force
    Write-Host "  Copied: $($file.Name)" -ForegroundColor Green
}

# EAソースとインクルードもコピー（初回のみ必要）
$eaSource = "ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"

if (-not (Test-Path $eaDest)) {
    Write-Host "  Copying EA source..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
    Copy-Item $eaSource $eaDest -Force
    
    $includeSource = "ea\include"
    $includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
    Copy-Item $includeSource $includeDest -Recurse -Force
    Write-Host "  EA source copied" -ForegroundColor Green
}
Write-Host ""

# ステップ4: コンパイル
Write-Host "[Step 4/4] Compiling EA..." -ForegroundColor Yellow

$mt5Path = "C:\Program Files\MetaTrader 5\terminal64.exe"
if (-not (Test-Path $mt5Path)) {
    $mt5Path = "C:\Program Files (x86)\MetaTrader 5\terminal64.exe"
}

$metaeditorPath = Join-Path (Split-Path $mt5Path) "metaeditor64.exe"

if (Test-Path $metaeditorPath) {
    $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList "/compile:`"$eaDest`"","/log" -Wait -PassThru -WindowStyle Hidden
    
    $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "  Compilation successful" -ForegroundColor Green
    } else {
        Write-Host "  Error: Compilation failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  Warning: MetaEditor not found, skipping compilation" -ForegroundColor Yellow
}
Write-Host ""

# MT5を起動
Write-Host "Starting MT5..." -ForegroundColor Yellow
Start-Process $mt5Path
Write-Host ""

# テスト手順を表示
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "MT5 Strategy Tester で以下のファイルをテストしてください:" -ForegroundColor Yellow
Write-Host ""

foreach ($file in $generatedFiles) {
    Write-Host "  [$($file.BaseName)]" -ForegroundColor Cyan
    Write-Host "    InpConfigPath = strategy/$($file.Name)" -ForegroundColor White
    Write-Host ""
}

Write-Host "共通設定:" -ForegroundColor Yellow
Write-Host "  - EA: Experts\StrategyBricks\StrategyBricks" -ForegroundColor White
Write-Host "  - Symbol: USDJPYm" -ForegroundColor White
Write-Host "  - Period: M1" -ForegroundColor White
Write-Host "  - Date: 2025.10.01 - 2025.12.31" -ForegroundColor White
Write-Host "  - Deposit: 1,000,000 JPY" -ForegroundColor White
Write-Host "  - Leverage: 1:100" -ForegroundColor White
Write-Host ""
Write-Host "各テストで取引回数を確認してください。" -ForegroundColor Yellow
Write-Host "取引が0回の場合は、ログを確認して原因を調査してください。" -ForegroundColor Yellow
Write-Host ""
