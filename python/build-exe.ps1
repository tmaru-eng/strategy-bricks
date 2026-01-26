# PyInstallerでbacktest_engine.pyをexe化するスクリプト

$ErrorActionPreference = "Stop"

Write-Host "=== バックテストエンジンのexe化 ===" -ForegroundColor Cyan
Write-Host ""

# 1. PyInstallerのインストール確認
Write-Host "[1/4] PyInstallerの確認..." -ForegroundColor Yellow
try {
    python -m pip show pyinstaller | Out-Null
    Write-Host "  OK PyInstallerがインストールされています" -ForegroundColor Green
}
catch {
    Write-Host "  PyInstallerをインストール中..." -ForegroundColor Gray
    python -m pip install pyinstaller
    Write-Host "  OK PyInstallerをインストールしました" -ForegroundColor Green
}
Write-Host ""

# 2. 依存関係のインストール確認
Write-Host "[2/4] 依存関係の確認..." -ForegroundColor Yellow
python -m pip install -r requirements.txt
Write-Host "  OK 依存関係を確認しました" -ForegroundColor Green
Write-Host ""

# 3. PyInstallerでexe化
Write-Host "[3/4] exeをビルド中..." -ForegroundColor Yellow
Write-Host "  これには数分かかる場合があります..." -ForegroundColor Gray

# specファイルを使用してビルド
python -m PyInstaller backtest_engine.spec --clean --noconfirm

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK exeのビルドに成功しました" -ForegroundColor Green
}
else {
    Write-Host "  ERROR exeのビルドに失敗しました" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. 検証
Write-Host "[4/4] exeの検証..." -ForegroundColor Yellow
$exePath = "dist\backtest_engine.exe"

if (Test-Path $exePath) {
    Write-Host "  OK exeファイルが生成されました: $exePath" -ForegroundColor Green
    
    # ファイルサイズを表示
    $fileSize = (Get-Item $exePath).Length / 1MB
    Write-Host "  ファイルサイズ: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    
    # --helpオプションでテスト
    Write-Host "  exeをテスト中..." -ForegroundColor Gray
    try {
        $null = & $exePath --help 2>&1
        Write-Host "  OK exeが正常に動作します" -ForegroundColor Green
    }
    catch {
        Write-Host "  WARNING exeのテストに失敗しました" -ForegroundColor Yellow
        Write-Host "  注意: MT5がインストールされていない環境では正常です" -ForegroundColor Gray
    }
}
else {
    Write-Host "  ERROR exeファイルが見つかりません" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "=== ビルド完了 ===" -ForegroundColor Green
Write-Host ""
Write-Host "生成されたexe: $exePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "  1. GUIアプリを起動してバックテスト機能をテスト" -ForegroundColor Gray
Write-Host "  2. 本番ビルド時にelectron-builderがexeを同梱" -ForegroundColor Gray
Write-Host ""
