# ブロック個別テスト用設定ファイル

## 概要

GUI統合とは切り離して、各ブロックの動作を個別に確認するための設定ファイルです。

## テストファイル一覧

### 1. block-test-spread-only.json
**テスト対象:** `filter.spreadMax` ブロック

**条件:**
- スプレッドが50pips以下

**期待動作:**
- ほぼすべてのバーで条件を満たす
- 多数の取引が発生するはず

**使用方法:**
```
InpConfigPath = strategy/block-test-spread-only.json
```

---

### 2. block-test-ma-trend.json
**テスト対象:** `trend.maRelation` ブロック

**条件:**
- 価格がMA(20)より上

**期待動作:**
- 上昇トレンド時に条件を満たす
- 取引回数は市場状況による

**使用方法:**
```
InpConfigPath = strategy/block-test-ma-trend.json
```

---

### 3. block-test-bb-trigger.json
**テスト対象:** `trigger.bbReentry` ブロック

**条件:**
- ボリンジャーバンド下限から内側への回帰

**期待動作:**
- 価格が下限を超えて戻ってきた時に条件を満たす
- 取引回数は少なめ

**使用方法:**
```
InpConfigPath = strategy/block-test-bb-trigger.json
```

---

## テスト手順

### 1. ファイルをMT5にコピー

**重要:** MT5 Strategy Testerは `FILE_COMMON` フラグでファイルを読み込むため、以下のディレクトリにファイルを配置する必要があります:

```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\Common\Files\strategy\
```

```powershell
# Common/Filesディレクトリにコピー（正しい場所）
$commonFiles = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\strategy"
if (-not (Test-Path $commonFiles)) { New-Item -ItemType Directory -Path $commonFiles -Force }
Copy-Item ea\tests\block-test-*.json $commonFiles\
```

**注意:** 以下のディレクトリは使用されません:
- ❌ `Terminal\{TERMINAL_ID}\Tester\Agent-127.0.0.1-3000\Files\strategy\`
- ❌ `Terminal\{TERMINAL_ID}\MQL5\Files\strategy\`

### 2. MT5 Strategy Testerで実行

1. MT5を開く
2. Strategy Tester (Ctrl+R)
3. 設定:
   - EA: `StrategyBricks`
   - Symbol: `USDJPYm`
   - Period: `M1`
   - Date: `2026.01.01 - 2026.01.25`
   - InpConfigPath: `strategy/block-test-spread-only.json` (または他のテストファイル)
4. テスト実行

### 3. 結果確認

**Expertsタブで確認:**
- `BLOCK_EVAL` イベントでブロックの評価結果を確認
- `PASS` / `FAIL` の理由を確認
- 取引回数を確認

**期待される結果:**
- `block-test-spread-only.json`: 多数の取引（スプレッド条件のみ）
- `block-test-ma-trend.json`: 中程度の取引（トレンド条件）
- `block-test-bb-trigger.json`: 少数の取引（厳しい条件）

---

## トラブルシューティング

### 取引が0回の場合

1. **Expertsタブを確認:**
   - `BLOCK_EVAL` イベントが出力されているか
   - `FAIL` の理由を確認

2. **設定を確認:**
   - `InpConfigPath` が正しいか
   - ファイルが正しい場所にコピーされているか

3. **条件を緩和:**
   - `maxSpreadPips` を増やす
   - `session.enabled` を `false` にする
   - テスト期間を延ばす

---

## GUI統合テストとの違い

| 項目 | ブロック個別テスト | GUI統合テスト |
|------|-------------------|--------------|
| 目的 | ブロックロジック検証 | GUI-EA連携検証 |
| 条件 | 単一ブロックのみ | 複数ブロックの組み合わせ |
| 取引回数 | 多い（条件が緩い） | 少ない（条件が厳しい） |
| 作成方法 | 手動作成 | GUIで生成 |
| blockId | 手動割り当て | GUI自動割り当て |

---

## 次のステップ

1. **各ブロックを個別にテスト**
   - `block-test-spread-only.json` → 取引が発生することを確認
   - `block-test-ma-trend.json` → MAロジックを確認
   - `block-test-bb-trigger.json` → BBロジックを確認

2. **問題があるブロックを特定**
   - 取引が0回のブロックを調査
   - ログで `FAIL` の理由を確認

3. **ブロックロジックを修正**
   - 必要に応じてブロックの実装を修正

4. **GUI統合テストに戻る**
   - すべてのブロックが正常に動作することを確認後
   - GUI生成の設定ファイルで再テスト
