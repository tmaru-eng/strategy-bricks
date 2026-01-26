# Strategy Bricks EA テスト実行スクリプト
# Usage: .\test-ea.ps1 [ConfigFile]
# Example: .\test-ea.ps1 active.json

param(
    [string]$ConfigFile = "active.json"
)

Write-Host "=== Strategy Bricks EA Test ===" -ForegroundColor Cyan
Write-Host ""

# GUIで生成した設定ファイルを使用する場合
if ($ConfigFile -eq "gui-generated") {
    Write-Host "Using GUI-generated config..." -ForegroundColor Yellow
    
    # e2eテストを実行して設定ファイルを生成
    Push-Location gui
    npm run e2e
    Pop-Location
    
    # 生成されたファイルをea/testsにコピー
    $guiConfig = "$env:TEMP\strategy-bricks-e2e\active.json"
    if (Test-Path $guiConfig) {
        Copy-Item $guiConfig "ea\tests\gui-generated.json" -Force
        $ConfigFile = "gui-generated.json"
        Write-Host "GUI config copied to: ea\tests\$ConfigFile" -ForegroundColor Green
    } else {
        Write-Host "Error: GUI config not found" -ForegroundColor Red
        exit 1
    }
}

# MT5テスト準備を実行
& ".\scripts\prepare_mt5_test.ps1" -ConfigFile $ConfigFile
