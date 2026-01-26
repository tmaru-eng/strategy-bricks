# Strategy Bricks EA - コンパイルと全テスト実行スクリプト

Write-Host "=== Strategy Bricks EA - Compile and Test All ===" -ForegroundColor Cyan
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

$metaeditorPath = Join-Path (Split-Path $mt5Path) "metaeditor64.exe"

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

# ステップ1: ファイルをコピー
Write-Host "[Step 1/4] Copying files..." -ForegroundColor Yellow

# 設定ファイルをコピー
$testFiles = @("active.json", "test_single_blocks.json", "test_strategy_advanced.json", "test_strategy_all_blocks.json")
foreach ($file in $testFiles) {
    $source = "ea\tests\$file"
    $dest = Join-Path $terminalDir "MQL5\Files\strategy\$file"
    
    if (Test-Path $source) {
        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        Copy-Item $source $dest -Force
        Write-Host "  Copied: $file" -ForegroundColor Green
    } else {
        Write-Host "  Warning: $file not found" -ForegroundColor Yellow
    }
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

# ステップ2: コンパイル
Write-Host "[Step 2/4] Compiling EA..." -ForegroundColor Yellow

if (Test-Path $metaeditorPath) {
    $compileProcess = Start-Process -FilePath $metaeditorPath -ArgumentList "/compile:`"$eaDest`"","/log" -Wait -PassThru -WindowStyle Hidden
    
    $ex5Path = $eaDest -replace '\.mq5$', '.ex5'
    if (Test-Path $ex5Path) {
        Write-Host "  Compilation successful: $ex5Path" -ForegroundColor Green
    } else {
        Write-Host "  Error: Compilation failed" -ForegroundColor Red
        Write-Host "  Check MetaEditor logs for details" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  Error: MetaEditor not found at $metaeditorPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ステップ3: テスト実行の準備
Write-Host "[Step 3/4] Test configurations:" -ForegroundColor Yellow
Write-Host ""

$testConfigs = @(
    @{
        Name = "active.json"
        Description = "基本動作確認"
        ExpectedTrades = "10-50"
    },
    @{
        Name = "test_single_blocks.json"
        Description = "単体ブロックテスト（最重要）"
        ExpectedTrades = "50-200"
    },
    @{
        Name = "test_strategy_advanced.json"
        Description = "高度な戦略の統合テスト"
        ExpectedTrades = "5-30"
    },
    @{
        Name = "test_strategy_all_blocks.json"
        Description = "全ブロック網羅テスト"
        ExpectedTrades = "3-20"
    }
)

for ($i = 0; $i -lt $testConfigs.Count; $i++) {
    $config = $testConfigs[$i]
    Write-Host "  [$($i+1)] $($config.Name)" -ForegroundColor Cyan
    Write-Host "      $($config.Description)" -ForegroundColor White
    Write-Host "      Expected trades: $($config.ExpectedTrades)" -ForegroundColor Gray
    Write-Host ""
}

# ステップ4: MT5を起動して手動テスト
Write-Host "[Step 4/4] Starting MT5 for manual testing..." -ForegroundColor Yellow
Start-Process $mt5Path
Write-Host "  MT5 started" -ForegroundColor Green
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "MT5 Strategy Tester で以下の手順でテストを実行してください:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Ctrl+R でStrategy Testerを開く" -ForegroundColor White
Write-Host "2. 設定:" -ForegroundColor White
Write-Host "   - EA: Experts\StrategyBricks\StrategyBricks" -ForegroundColor Cyan
Write-Host "   - Symbol: USDJPYm" -ForegroundColor Cyan
Write-Host "   - Period: M1" -ForegroundColor Cyan
Write-Host "   - Date: 2025.10.01 - 2025.12.31" -ForegroundColor Cyan
Write-Host "   - Deposit: 1,000,000 JPY" -ForegroundColor Cyan
Write-Host "   - Leverage: 1:100" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Input Parameters タブ:" -ForegroundColor White
Write-Host "   - InpConfigPath = strategy/[テストファイル名]" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. 各テストファイルで実行:" -ForegroundColor White
foreach ($config in $testConfigs) {
    Write-Host "   - $($config.Name)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "5. 結果を確認:" -ForegroundColor White
Write-Host "   - 取引回数が期待範囲内か" -ForegroundColor Gray
Write-Host "   - 取引が0回の場合はログを確認" -ForegroundColor Gray
Write-Host ""
Write-Host "推奨テスト順序: test_single_blocks.json → active.json → advanced → all_blocks" -ForegroundColor Yellow
Write-Host ""
