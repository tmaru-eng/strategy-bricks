# Strategy Bricks EA テスト実行スクリプト
# Usage:
#   .\test-ea.ps1 -ConfigFile active.json
#   .\test-ea.ps1 -ConfigFile gui-generated
#   .\test-ea.ps1 -ConfigPath "C:\path\to\active.json"

param(
    [string]$ConfigFile = "active.json",
    [string]$ConfigPath
)

Write-Host "=== Strategy Bricks EA Test ===" -ForegroundColor Cyan
Write-Host ""

# GUIで生成した設定ファイルを使用する場合
if (-not $ConfigPath -and $ConfigFile -eq "gui-generated") {
    Write-Host "Using GUI-generated config..." -ForegroundColor Yellow
    
    # e2eテストを実行して設定ファイルを生成
    Push-Location gui
    npm run e2e
    Pop-Location
    
    $guiConfig = "$env:TEMP\strategy-bricks-e2e\active.json"
    if (Test-Path $guiConfig) {
        $ConfigPath = $guiConfig
        Write-Host "GUI config found: $ConfigPath" -ForegroundColor Green
    } else {
        Write-Host "Error: GUI config not found" -ForegroundColor Red
        exit 1
    }
}

if ($ConfigPath) {
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Error: Config path not found: $ConfigPath" -ForegroundColor Red
        exit 1
    }
    & (Join-Path $PSScriptRoot "prepare_mt5_test.ps1") -ConfigPath $ConfigPath
    exit $LASTEXITCODE
}

# MT5テスト準備を実行
& (Join-Path $PSScriptRoot "prepare_mt5_test.ps1") -ConfigFile $ConfigFile
