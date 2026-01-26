# Strategy Bricks - 完全自動テストスクリプト
# GUIテスト → ファイルコピー → コンパイル → MT5テスト実行

param(
    [switch]$SkipGUITest = $false,
    [switch]$SkipCompile = $false
)

Write-Host "=== Strategy Bricks - Full Automated Test ===" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

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

# MT5のデータディレクトリを取得
$mt5DataDir = "$env:APPDATA\MetaQuotes\Terminal"
$terminals = Get-ChildItem $mt5DataDir -Directory | Where-Object { $_.Name -match '^[A-F0-9]{32}$' } | Sort-Object LastWriteTime -Descending

if ($terminals.Count -eq 0) {
    Write-Host "Error: MT5 terminal directory not found" -ForegroundColor Red
    exit 1
}

# 最新のターミナルを使用
$terminalDir = $terminals[0].FullName
Write-Host "Terminal: $terminalDir" -ForegroundColor Green
Write-Host "  (Using most recently modified terminal)" -ForegroundColor Gray
Write-Host ""

# ステップ1: GUIのe2eテストを実行
if (-not $SkipGUITest) {
    Write-Host "[Step 1/5] Running GUI e2e test..." -ForegroundColor Yellow
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
} else {
    Write-Host "[Step 1/5] Skipping GUI test..." -ForegroundColor Gray
    Write-Host ""
}

# ステップ2: 生成されたファイルを確認
Write-Host "[Step 2/5] Checking generated files..." -ForegroundColor Yellow
$guiOutputDir = "$env:TEMP\strategy-bricks-e2e"

if (-not (Test-Path $guiOutputDir)) {
    Write-Host "Error: Output directory not found: $guiOutputDir" -ForegroundColor Red
    exit 1
}

$generatedFiles = Get-ChildItem $guiOutputDir -Filter "*.json" | Where-Object { $_.Name -ne "active.json" }
Write-Host "  Found $($generatedFiles.Count) test config(s)" -ForegroundColor Green

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

# 生成されたファイルをコピー
foreach ($file in $generatedFiles) {
    $dest = Join-Path $mt5FilesDir $file.Name
    Copy-Item $file.FullName $dest -Force
    Write-Host "  Copied: $($file.Name)" -ForegroundColor Green
}

# EAソースをコピー
$eaSource = "ea\src\StrategyBricks.mq5"
$eaDest = Join-Path $terminalDir "MQL5\Experts\StrategyBricks\StrategyBricks.mq5"
New-Item -ItemType Directory -Path (Split-Path $eaDest) -Force | Out-Null
Copy-Item $eaSource $eaDest -Force
Write-Host "  Copied: EA source" -ForegroundColor Green

# インクルードファイルをコピー
$includeSource = "ea\include"
$includeDest = Join-Path $terminalDir "MQL5\Include\StrategyBricks"
Copy-Item $includeSource $includeDest -Recurse -Force
Write-Host "  Copied: Include files" -ForegroundColor Green
Write-Host ""

# ステップ4: コンパイル
if (-not $SkipCompile) {
    Write-Host "[Step 4/5] Compiling EA..." -ForegroundColor Yellow

    if (Test-Path $metaeditorPath) {
        # コンパイル実行
        $compileArgs = @(
            "/compile:`"$eaDest`"",
            "/log"
        )
        
        Write-Host "  Command: $metaeditorPath $($compileArgs -join ' ')" -ForegroundColor Gray
        $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList $compileArgs -Wait -PassThru -WindowStyle Hidden
        
        # コンパイル結果を確認
        $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
        if (Test-Path $ex5Path) {
            $ex5Info = Get-Item $ex5Path
            Write-Host "  Compilation successful: $($ex5Info.Name)" -ForegroundColor Green
            Write-Host "  Size: $($ex5Info.Length) bytes" -ForegroundColor Gray
            Write-Host "  Modified: $($ex5Info.LastWriteTime)" -ForegroundColor Gray
        } else {
            Write-Host "  Error: Compilation failed - .ex5 file not found" -ForegroundColor Red
            Write-Host "  Expected: $ex5Path" -ForegroundColor Yellow
            
            # ログファイルを探す
            $logFiles = Get-ChildItem (Join-Path $terminalDir "MQL5\Logs") -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($logFiles) {
                Write-Host "  Check log: $($logFiles.FullName)" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  Last 20 lines of log:" -ForegroundColor Yellow
                Get-Content $logFiles.FullName -Tail 20 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
            }
            
            exit 1
        }
    } else {
        Write-Host "  Error: MetaEditor not found at $metaeditorPath" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
} else {
    Write-Host "[Step 4/5] Skipping compilation..." -ForegroundColor Gray
    Write-Host ""
}

# ステップ5: テスト実行の準備
Write-Host "[Step 5/5] Test execution summary:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Ready to test $($testConfigs.Count) configuration(s):" -ForegroundColor Green
Write-Host ""

foreach ($config in $testConfigs) {
    Write-Host "  [$($config.Name)]" -ForegroundColor Cyan
    Write-Host "    File: strategy/$($config.FileName)" -ForegroundColor White
    Write-Host ""
}

Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option A: Manual Testing (Recommended)" -ForegroundColor Yellow
Write-Host "  1. Open MT5 (press Enter to launch)" -ForegroundColor White
Write-Host "  2. Press Ctrl+R to open Strategy Tester" -ForegroundColor White
Write-Host "  3. Configure:" -ForegroundColor White
Write-Host "     - EA: Experts\StrategyBricks\StrategyBricks" -ForegroundColor Cyan
Write-Host "     - Symbol: USDJPYm" -ForegroundColor Cyan
Write-Host "     - Period: M1" -ForegroundColor Cyan
Write-Host "     - Date: 2025.10.01 - 2025.12.31" -ForegroundColor Cyan
Write-Host "     - Deposit: 1,000,000 JPY" -ForegroundColor Cyan
Write-Host "     - Leverage: 1:100" -ForegroundColor Cyan
Write-Host "  4. For each test, change InpConfigPath:" -ForegroundColor White
foreach ($config in $testConfigs) {
    Write-Host "     - strategy/$($config.FileName)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Option B: Automated Testing (Experimental)" -ForegroundColor Yellow
Write-Host "  Run: .\scripts\run_mt5_tester_batch.ps1" -ForegroundColor White
Write-Host ""

# MT5を起動するか確認
Write-Host "Press Enter to launch MT5, or Ctrl+C to exit..." -ForegroundColor Yellow
$null = Read-Host

Write-Host "Launching MT5..." -ForegroundColor Green
Start-Process $mt5Path

Write-Host ""
Write-Host "=== Test Ready ===" -ForegroundColor Cyan
Write-Host "MT5 has been launched. Follow the manual testing steps above." -ForegroundColor Green
Write-Host ""
