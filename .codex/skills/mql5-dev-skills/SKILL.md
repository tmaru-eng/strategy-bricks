---
name: mql5-dev-skills
description: >-
  MQL5開発時のコマンドラインツール関連スキル。CLIコンパイルやTester実行の
  コマンドと、Windows/macOSでのFiles配置先を汎用的に整理する。
allowed-tools: Bash, Read, Shell
---

# MQL5 開発：コマンドラインツール手順（Windows / macOS）

このスキルは **MQL5 開発時のコマンドライン操作**（コンパイル/Tester 実行）
と **ファイル配置** を、Windows / macOS の両環境で汎用的にまとめたものです。

## 使うタイミング（必須）

- `.mq5` / `.mqh` の編集後
- ユーザーが「コンパイル」「ビルド」「動作確認」「テスト実行」と言った時
- Strategy Tester 実行や MT5 操作の確認が必要な時

## Files の配置先（重要）

EA 実行時と Strategy Tester 実行時で **読み込みパスが異なる場合がある**ため、
**両方にコピー**する運用を推奨します。  
また、EA が `Common` を参照する実装の場合は **Common 側にも配置**します。

> 例: `active.json` などの設定ファイルを  
> **Files / Common / Tester (Agent) 配下に同時配置**する。

### Windows（実運用: Terminal の Files / Common）
```
%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Files\<任意のサブフォルダ>\*.json
%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Files\Common\<任意のサブフォルダ>\*.json
```

### Windows（Strategy Tester: Tester/Agent の Files / Common）
```
%APPDATA%\MetaQuotes\Tester\<TERMINAL_ID>\Agent-<AGENT_ID>\MQL5\Files\<任意のサブフォルダ>\*.json
%APPDATA%\MetaQuotes\Tester\<TERMINAL_ID>\Agent-<AGENT_ID>\MQL5\Files\Common\<任意のサブフォルダ>\*.json
```

### macOS（実運用: Terminal の Files / Common）
```
~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/<任意のサブフォルダ>/*.json
~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/Common/<任意のサブフォルダ>/*.json
```

### macOS（Strategy Tester: Tester/Agent の Files / Common）
```
~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-<AGENT_ID>/MQL5/Files/<任意のサブフォルダ>/*.json
~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-<AGENT_ID>/MQL5/Files/Common/<任意のサブフォルダ>/*.json
```

※ `<TERMINAL_ID>` / `<AGENT_ID>` は環境依存です。  
※ EA が `Common` を読む場合は **Common 側も必須**です。

---

## コンパイル手順（コマンドのみ）

### Windows（コマンドライン）
```powershell
$metaeditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$sourcePath = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Experts\<EA名>\<EA名>.mq5"
& $metaeditor /compile:"$sourcePath" /log
```

### macOS（X: ドライブを使った CLI コンパイル）
macOS では `Program Files` のパスにスペースが含まれるため、**X: ドライブマッピング**を使ってコンパイルします。

#### 1) X: ドライブ作成（初回のみ）
```bash
BOTTLE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
cd "$BOTTLE/dosdevices"
ln -s "../drive_c/Program Files/MetaTrader 5/MQL5" "x:"
```

マッピング確認:
```bash
ls -la "$BOTTLE/dosdevices/" | grep "x:"
```

#### 2) X: ドライブパスの作成ルール
- 標準: `C:\Program Files\MetaTrader 5\MQL5\Indicators\Custom\MyIndicator.mq5`
- X:     `X:\Indicators\Custom\MyIndicator.mq5`

**ルール**: `Program Files\MetaTrader 5\MQL5\` を削り、先頭を `X:\` に置換。

#### 3) コンパイル実行
```bash
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
ME="C:/Program Files/MetaTrader 5/MetaEditor64.exe"

WINEPREFIX="$WINEPREFIX" "$WINE" "$ME" \
  /log \
  /compile:"X:\\Experts\\<EA名>\\<EA名>.mq5" \
  /inc:"X:"
```

**重要フラグ**:
- `/log`: コンパイルログを出力
- `/compile:"X:\\..."`: ソースファイル（X: パス）
- `/inc:"X:"`: include ルート（MQL5）

#### 4) 出力確認
```bash
BOTTLE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
EX5_FILE="$BOTTLE/drive_c/Program Files/MetaTrader 5/MQL5/Experts/<EA名>/<EA名>.ex5"
LOG_FILE="$BOTTLE/drive_c/Program Files/MetaTrader 5/MQL5/Experts/<EA名>/<EA名>.log"

if [ -f "$EX5_FILE" ]; then
  ls -lh "$EX5_FILE"
  echo "✅ Compilation successful"
else
  echo "❌ Compilation failed"
fi

cat "$LOG_FILE" | grep -i "error\|warning\|Result"
```

**個別ログの場所**: `.log` は `.mq5` と同じディレクトリに生成。

---

## Strategy Tester 実行（コマンド例）

### Windows（コマンドラインで起動）
```powershell
$terminal = "C:\Program Files\MetaTrader 5\terminal64.exe"
& $terminal /config:"<INIパス>" /portable
```

※ `.ini` に `Expert` / `Symbol` / `Period` / `From` / `To` / `Deposit` /
`Leverage` / `ExecutionMode` / `Optimization` / `Report` / `ShutdownTerminal`
等を設定します。

### macOS（Wine 経由）
```bash
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
TERMINAL="C:/Program Files/MetaTrader 5/terminal64.exe"

WINEPREFIX="$WINEPREFIX" "$WINE" "$TERMINAL" /config:"C:\\path\\to\\tester.ini" /portable
```

---

## よくある Issue / 注意点（汎用）

- **Wine でのコンパイルは exit code が 1 でも成功する場合がある**  
  → `.ex5` / `.log` の更新で必ず確認する。  
- **パスに空白が含まれると CLI コンパイルが失敗しやすい**  
  → macOS では X: ドライブ経由を使う。  
- **Tester の実行パスは Terminal と異なる**  
  → Files 配置先は **Terminal / Tester / Common** の 3 系統を意識する。  
- **EA が `Common` を読む実装の場合**  
  → `Common` 配下にも必ず同じ設定ファイルを置く。  

---

## トラブルシューティング

### Issue: exit code が 1 だがコンパイル成功

**原因**: Wine は成功時でも exit code 1 を返すことがある  
**対応**: **exit code は無視**し、必ず以下で確認する:
1. `.ex5` が更新されているか確認: `ls -la YourFile.ex5`
2. 個別ログで "0 errors, 0 warnings" を確認: `cat YourFile.log`

### Issue: 42 errors / include file not found

**原因**: X: を使わずに短いパス（例: `C:/file.mq5`）でコンパイル  
**対応**: X: パスで `/inc:"X:"` を指定

### Issue: exit code 0 だが .ex5 が生成されない

**原因**: パスにスペースや記号が含まれている  
**対応**: X: パスのみを使用（スペース回避）

### Issue: X: ドライブが見つからない

**原因**: シンボリックリンク未作成  
**対応**: `dosdevices` に `x:` を作成する

### Issue: MetaTrader のアプリパスが違う

**原因**: MetaTrader 5.app の場所が異なる  
**対応**: `ls /Applications/MetaTrader\ 5.app` で確認

### Issue: metaeditor.log が見つからない

**原因**: 参照先が違う  
**対応**: 個別ログを参照（`.mq5` と同じ場所に生成される）

---

## よく使うパターン

### 例 1: CCI Neutrality Indicator をコンパイル
```bash
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
WINEPREFIX="$WINEPREFIX" "$WINE" "C:/Program Files/MetaTrader 5/MetaEditor64.exe" \
  /log \
  /compile:"X:\\Indicators\\Custom\\Development\\CCINeutrality\\CCI_Neutrality_RoC_DEBUG.mq5" \
  /inc:"X:"

# 結果: CCI_Neutrality_RoC_DEBUG.ex5 が生成（23KB）
```

### 例 2: スクリプトをコンパイル
```bash
WINEPREFIX="$WINEPREFIX" "$WINE" "C:/Program Files/MetaTrader 5/MetaEditor64.exe" \
  /log \
  /compile:"X:\\Scripts\\DataExport\\ExportAligned.mq5" \
  /inc:"X:"
```

### 例 3: X: ドライブの確認
```bash
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
WINEPREFIX="$WINEPREFIX" "$WINE" cmd /c "dir X:\" | head -10
# 期待: Indicators / Scripts / Include / Experts などが表示される
```

---

## X: ドライブ方式の利点

✅ **スペース回避**: "Program Files" を含まない  
✅ **高速**: 約1秒でコンパイル  
✅ **安定**: 直接パスより安定動作  
✅ **include 解決**: `/inc:"X:"` で MQL5 を解決  
✅ **短いパス**: `X:\Indicators\...`

## 比較: X: ドライブ vs 手動 GUI

| Method | Speed | Automation | Reliability |
| --- | --- | --- | --- |
| X: drive CLI | ~1s | ✅ Yes | ✅ High |
| Manual MetaEditor | ~3s | ❌ No | ✅ High |
| Direct CLI path | N/A | ⚠️ Unreliable | ❌ Fails silently |

## Git ワークフローとの関係

X: ドライブのマッピングは永続的で git に影響しない:
- `dosdevices/` にシンボリックリンクを作成
- MQL5 のソースに影響なし
- ブランチ切替でも影響なし
- 追加の設定ファイルをコミット不要

## セキュリティ注意（X: ドライブ）

- X: ドライブはコンパイル用途として READ-ONLY 想定
- コンパイル中に生成物を実行しない
- MetaEditor は Wine のサンドボックス環境で動作
- コンパイル中のネットワークアクセスなし

---

## セキュリティ注意（共通）

- **外部から取得した設定ファイルは内容を確認してから使用する**  
- **EA から読み込むファイルは、想定パス以外を読ませない設計にする**  
- **GUI やスクリプト経由のファイルパス入力はサニタイズする**  

---

## クイックリファレンス

**コンパイルコマンドのテンプレ**:
```bash
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5" \
  /Applications/MetaTrader\ 5.app/Contents/SharedSupport/wine/bin/wine64 \
  "C:/Program Files/MetaTrader 5/MetaEditor64.exe" \
  /log /compile:"X:\\Path\\To\\File.mq5" /inc:"X:"
```

**Bottle の場所**: `~/Library/Application Support/net.metaquotes.wine.metatrader5/`  
**X: の参照先**: bottle 内の `MQL5/`  
**確認方法**: `.ex5` と個別 `.log` を確認（exit code は無視）

---

## まとめ（チェックリスト）

- 設定ファイルは **Terminal の Files** と **Tester Agent の Files** にコピー済み  
- `Common` を参照する EA なら **Common 側にもコピー済み**  
- `.mq5/.mqh` 変更後にコンパイル済み  
- Strategy Tester の `config.ini` で **読み込みパスが一致**している
