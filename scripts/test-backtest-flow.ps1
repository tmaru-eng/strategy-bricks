# バックテスト機能の統合テストスクリプト
# このスクリプトは、設定ファイルの出力からバックテスト実行までの完全なフローをテストします

Write-Host "=== Strategy Bricks バックテスト統合テスト ===" -ForegroundColor Cyan
Write-Host ""

# 1. テスト用ストラテジー設定を作成
Write-Host "[1/4] テスト用ストラテジー設定を作成中..." -ForegroundColor Yellow

$testConfig = @{
    meta = @{
        formatVersion = "1.0"
        name = "Backtest Test Strategy"
        generatedBy = "Test Script"
        generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        description = "バックテスト機能のテスト用設定"
    }
    globalGuards = @{
        timeframe = "M1"
        useClosedBarOnly = $true
        noReentrySameBar = $true
        maxPositionsTotal = 1
        maxPositionsPerSymbol = 1
        maxSpreadPips = 30.0
        session = @{
            enabled = $true
            windows = @(
                @{ start = "00:00"; end = "23:59" }
            )
            weekDays = @{
                sun = $false
                mon = $true
                tue = $true
                wed = $true
                thu = $true
                fri = $true
                sat = $false
            }
        }
    }
    strategies = @(
        @{
            id = "S1"
            name = "Test Strategy"
            enabled = $true
            priority = 10
            conflictPolicy = "firstOnly"
            directionPolicy = "both"
            entryRequirement = @{
                type = "OR"
                ruleGroups = @(
                    @{
                        id = "rulegroup-1"
                        type = "AND"
                        conditions = @(
                            @{ blockId = "filter.spreadMax#1" }
                            @{ blockId = "trend.maRelation#1" }
                        )
                    }
                )
            }
            lotModel = @{
                type = "lot.fixed"
                params = @{ lots = 0.1 }
            }
            riskModel = @{
                type = "risk.fixedSLTP"
                params = @{ slPips = 30; tpPips = 30 }
            }
            exitModel = @{
                type = "exit.none"
                params = @{}
            }
            nanpinModel = @{
                type = "nanpin.off"
                params = @{}
            }
        }
    )
    blocks = @(
        @{
            id = "filter.spreadMax#1"
            typeId = "filter.spreadMax"
            params = @{ maxSpreadPips = 30 }
        }
        @{
            id = "trend.maRelation#1"
            typeId = "trend.maRelation"
            params = @{
                period = 20
                maMethod = "SMA"
                appliedPrice = "CLOSE"
                relation = "above"
            }
        }
    )
}

$timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$configPath = "ea\tests\test_backtest_$timestamp.json"
$configJson = $testConfig | ConvertTo-Json -Depth 10

# ディレクトリが存在しない場合は作成
if (-not (Test-Path "ea\tests")) {
    New-Item -ItemType Directory -Path "ea\tests" -Force | Out-Null
}

$configJson | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "  ✓ 設定ファイルを作成しました: $configPath" -ForegroundColor Green
Write-Host ""

# 2. 設定ファイルの検証
Write-Host "[2/4] 設定ファイルを検証中..." -ForegroundColor Yellow
$config = Get-Content $configPath | ConvertFrom-Json

if ($config.meta.formatVersion -eq "1.0") {
    Write-Host "  ✓ フォーマットバージョン: $($config.meta.formatVersion)" -ForegroundColor Green
} else {
    Write-Host "  ✗ 無効なフォーマットバージョン" -ForegroundColor Red
    exit 1
}

if ($config.strategies.Count -gt 0) {
    Write-Host "  ✓ ストラテジー数: $($config.strategies.Count)" -ForegroundColor Green
} else {
    Write-Host "  ✗ ストラテジーが見つかりません" -ForegroundColor Red
    exit 1
}

if ($config.blocks.Count -gt 0) {
    Write-Host "  ✓ ブロック数: $($config.blocks.Count)" -ForegroundColor Green
} else {
    Write-Host "  ✗ ブロックが見つかりません" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Pythonバックテストエンジンの実行
Write-Host "[3/4] バックテストを実行中..." -ForegroundColor Yellow
Write-Host "  注意: MT5ターミナルが起動していることを確認してください" -ForegroundColor Cyan

$resultsPath = "ea\tests\test_backtest_results_$timestamp.json"

# バックテストパラメータ
$symbol = "USDJPY"
$timeframe = "M1"
$startDate = "2024-01-01T00:00:00Z"
$endDate = "2024-01-31T23:59:59Z"

Write-Host "  シンボル: $symbol" -ForegroundColor Gray
Write-Host "  時間軸: $timeframe" -ForegroundColor Gray
Write-Host "  期間: $startDate - $endDate" -ForegroundColor Gray
Write-Host ""

# Pythonスクリプトを実行
$pythonArgs = @(
    "python\backtest_engine.py"
    "--config", $configPath
    "--symbol", $symbol
    "--timeframe", $timeframe
    "--start", $startDate
    "--end", $endDate
    "--output", $resultsPath
)

try {
    $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "  ✓ バックテストが正常に完了しました" -ForegroundColor Green
    } else {
        Write-Host "  ✗ バックテストが失敗しました (終了コード: $($process.ExitCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ バックテストの実行中にエラーが発生しました: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. 結果ファイルの検証
Write-Host "[4/4] 結果ファイルを検証中..." -ForegroundColor Yellow

if (Test-Path $resultsPath) {
    Write-Host "  ✓ 結果ファイルが生成されました: $resultsPath" -ForegroundColor Green
    
    $results = Get-Content $resultsPath | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "  === バックテスト結果サマリー ===" -ForegroundColor Cyan
    Write-Host "  ストラテジー名: $($results.metadata.strategyName)" -ForegroundColor White
    Write-Host "  シンボル: $($results.metadata.symbol)" -ForegroundColor White
    Write-Host "  時間軸: $($results.metadata.timeframe)" -ForegroundColor White
    Write-Host "  期間: $($results.metadata.startDate) - $($results.metadata.endDate)" -ForegroundColor White
    Write-Host ""
    Write-Host "  総トレード数: $($results.summary.totalTrades)" -ForegroundColor White
    Write-Host "  勝ちトレード: $($results.summary.winningTrades)" -ForegroundColor Green
    Write-Host "  負けトレード: $($results.summary.losingTrades)" -ForegroundColor Red
    Write-Host "  勝率: $($results.summary.winRate)%" -ForegroundColor White
    Write-Host "  総損益: $($results.summary.totalProfitLoss)" -ForegroundColor $(if ($results.summary.totalProfitLoss -gt 0) { "Green" } else { "Red" })
    Write-Host "  最大ドローダウン: $($results.summary.maxDrawdown)" -ForegroundColor Yellow
    Write-Host "  平均トレード損益: $($results.summary.avgTradeProfitLoss)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  ✗ 結果ファイルが見つかりません" -ForegroundColor Red
    exit 1
}

Write-Host "=== テスト完了 ===" -ForegroundColor Green
Write-Host ""
Write-Host "生成されたファイル:" -ForegroundColor Cyan
Write-Host "  - 設定ファイル: $configPath" -ForegroundColor Gray
Write-Host "  - 結果ファイル: $resultsPath" -ForegroundColor Gray
Write-Host ""
