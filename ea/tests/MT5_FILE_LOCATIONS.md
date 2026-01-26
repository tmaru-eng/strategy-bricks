# MT5 ファイル配置ガイド

## 概要

MT5でEAをテストする際、設定ファイルの配置場所は使用するフラグによって異なります。

## Strategy Tester用の設定ファイル配置

### FILE_COMMONフラグを使用する場合（現在の実装）

**配置場所:**
```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\Common\Files\
```

**特徴:**
- ✅ すべてのMT5インスタンスで共有される
- ✅ Strategy Testerで使用される
- ✅ 複数のターミナルIDがあっても1箇所で管理

**ディレクトリ構造:**
```
Terminal\
  └── Common\
      └── Files\
          └── strategy\
              ├── block-test-spread-only.json
              ├── block-test-ma-trend.json
              ├── block-test-bb-trigger.json
              ├── basic-strategy.json
              ├── trend-only.json
              └── multi-trigger.json
```

**コピーコマンド:**
```powershell
# PowerShellで実行
$commonFiles = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\strategy"
if (-not (Test-Path $commonFiles)) { 
    New-Item -ItemType Directory -Path $commonFiles -Force 
}
Copy-Item ea\tests\*.json $commonFiles\
```

---

## 使用されないディレクトリ（参考）

### Tester Agent ディレクトリ（使用されない）

```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\{TERMINAL_ID}\Tester\Agent-127.0.0.1-3000\Files\
```

**理由:** `FILE_COMMON` フラグを使用しているため、このディレクトリは参照されません。

---

### MQL5/Files ディレクトリ（使用されない）

```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\{TERMINAL_ID}\MQL5\Files\
```

**理由:** `FILE_COMMON` フラグを使用しているため、このディレクトリは参照されません。

---

## ConfigLoaderの実装

**ファイル:** `ea/include/Config/ConfigLoader.mqh`

**関連コード:**
```mql5
// ファイル存在チェック（FILE_COMMONフラグを使用）
if (!FileIsExist(path, FILE_COMMON)) {
    if (m_logger != NULL) {
        m_logger.LogError("CONFIG_ERROR", "File not found: " + path);
    }
    Print("ERROR: Config file not found: ", path);
    return false;
}

// ファイル読込（FILE_COMMONフラグを追加してテスター対応）
int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
```

**FILE_COMMONフラグの効果:**
- `Terminal\Common\Files\` ディレクトリを基準にファイルを探す
- Strategy Testerで動作する
- すべてのMT5インスタンスで共有される

---

## トラブルシューティング

### ファイルが見つからないエラー

**エラーメッセージ:**
```
{"ts":"2026.01.01 00:00:00","event":"CONFIG_ERROR","level":"ERROR","message":"File not found: strategy/block-test-spread-only.json"}
```

**原因:**
- ファイルが `Terminal\Common\Files\strategy\` に配置されていない

**解決方法:**
1. ファイルが正しい場所にあるか確認:
   ```powershell
   Test-Path "$env:APPDATA\MetaQuotes\Terminal\Common\Files\strategy\block-test-spread-only.json"
   ```

2. ファイルが存在しない場合はコピー:
   ```powershell
   $commonFiles = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\strategy"
   if (-not (Test-Path $commonFiles)) { 
       New-Item -ItemType Directory -Path $commonFiles -Force 
   }
   Copy-Item ea\tests\block-test-*.json $commonFiles\
   ```

3. MT5を再起動してStrategy Testerを再実行

---

## 参考: FILE_COMMONフラグなしの場合

もし将来的に `FILE_COMMON` フラグを削除する場合、以下のディレクトリが使用されます:

```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\{TERMINAL_ID}\MQL5\Files\
```

**変更が必要な箇所:**
- `ea/include/Config/ConfigLoader.mqh` の `FileIsExist()` と `FileOpen()` から `FILE_COMMON` フラグを削除

**メリット:**
- ターミナルごとに異なる設定を使用できる

**デメリット:**
- Strategy Testerで動作しない可能性がある
- ターミナルIDが変わるたびにファイルをコピーする必要がある

---

## まとめ

| 項目 | 値 |
|------|-----|
| **現在の実装** | `FILE_COMMON` フラグを使用 |
| **ファイル配置場所** | `Terminal\Common\Files\strategy\` |
| **Strategy Tester対応** | ✅ 対応 |
| **複数ターミナル対応** | ✅ 共有される |
| **推奨** | ✅ 現在の実装を維持 |

