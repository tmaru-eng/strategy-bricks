# EA Tests

このディレクトリには、Strategy Bricks EAのテスト設定ファイルが含まれています。

> NOTE: Windows / Wine（macOS）両方で運用します。  
> 詳細は `docs/04_operations/70_strategy_tester_windows.md` を参照してください。

## テストファイル一覧

### 1. `active.json` (2.7KB)
**目的**: 基本動作確認
- **戦略数**: 1
- **ブロック数**: 6
- **期待取引回数**: 10-50回（3ヶ月）
- **用途**: 基本的な戦略の動作確認

### 2. `test_single_blocks.json` (25KB) ⭐ 最重要
**目的**: 単体ブロックテスト（問題の切り分け）
- **戦略数**: 32
- **ブロック数**: 32
- **期待取引回数**: 50-200回（3ヶ月）
- **用途**: 各ブロックが単体で正しく動作するか確認
- **特徴**: 
  - 1ブロック = 1戦略
  - 最もシンプルな条件設定
  - 取引発生の可能性を最大化

**カバーするブロック**:
- Filter: spreadMax, atrRange, stddevRange, daysOfWeek, timeWindow
- Trend: maRelation, maCross, adxThreshold, ichimokuCloud, sarDirection
- Trigger: bbReentry, bbBreakout, macdCross, stochCross, rsiLevel, cciLevel, sarFlip, wprLevel, mfiLevel, rviCross
- Osc: momentum, osma, forceIndex
- Volume: obvTrend
- Bill: fractals, alligator

### 3. `test_single_blocks_extra.json` (2KB)
**Purpose**: Extra single-block tests beyond MAX_STRATEGIES.
- **Strategies**: 2
- **Blocks**: 2
- **Notes**: Covers exit.weekendClose, nanpin.fixed (not in `test_single_blocks.json`).

### 4. `test_strategy_advanced.json` (8KB)
**目的**: 高度な戦略の統合テスト
- **戦略数**: 3
- **ブロック数**: 19
- **期待取引回数**: 5-30回（3ヶ月）
- **用途**: 複数ブロック組み合わせの動作確認
- **特徴**:
  - 複数フィルタ・トリガーの組み合わせ
  - 新ブロック（lot.riskPercent, risk.atrBased, exit.trail等）の使用
  - 実際の戦略に近い複雑な条件

### 5. `test_strategy_all_blocks.json` (11KB)
**目的**: 全ブロック網羅テスト
- **戦略数**: 4
- **ブロック数**: 30
- **期待取引回数**: 3-20回（3ヶ月）
- **用途**: 全36ブロックタイプの動作確認
- **特徴**:
  - Bill Williams戦略
  - マルチオシレーター戦略
  - SAR + RVI戦略
  - ボリンジャーバンド複合戦略

## テスト実行手順

### クイックスタート（推奨）

**手動テスト実行**:

1. MT5を起動  
2. ストラテジーテスターで各テストを実行  
   - 詳細手順: `docs/04_operations/MT5_MANUAL_TEST_GUIDE.md`
3. 結果を記録: `python3 scripts/record_test_results.py`

**推奨実行順**:
1. `test_single_blocks.json` - 単体ブロックの動作確認
2. `test_single_blocks_extra.json` - 追加2ブロックの確認
3. `active.json` - 基本動作
4. `test_strategy_advanced.json` - 複合条件
5. `test_strategy_all_blocks.json` - 全ブロック網羅

2. **自動テストスクリプト実行**:

```bash
python3 scripts/automated_tester.py
```

### MT5ストラテジーテスター設定

1. MT5を起動
2. ツール > ストラテジーテスター を開く
3. 以下を設定:
   - **EA**: `Experts\StrategyBricks\StrategyBricks.ex5`
   - **シンボル**: `USDJPYm`
   - **期間**: `M1`
   - **日付**: `2025.10.01 - 2025.12.31` (3ヶ月)
   - **初期証拠金**: 1,000,000 JPY
   - **レバレッジ**: 1:100
4. **入力パラメータ**: `InpConfigPath=strategy/<test_file>.json`
5. テスト開始

### 推奨テスト順序

```
1. test_single_blocks.json    ← 最優先（問題の切り分け）
   ↓
2. test_single_blocks_extra.json ← 追加2ブロックの確認
   ↓
3. active.json                ← 基本動作確認
   ↓
4. test_strategy_advanced.json ← 複雑な条件確認
   ↓
5. test_strategy_all_blocks.json ← 全機能網羅確認
```

## テスト結果の評価

### ✅ PASS（合格）
- 初期化成功
- エラーなし
- 取引回数 > 0

### ⚠️ WARNING（警告）
- 初期化成功
- エラーなし
- 取引回数 = 0（条件が厳しすぎる可能性）

### ❌ FAIL（不合格）
- 初期化失敗
- エラーあり

## 問題の診断

### 取引が発生しない場合

```
取引回数 = 0
  ↓
単体ブロックテストで確認
  ↓
├─ 単体でも0回 → ブロック実装の問題
│   ├─ ログ確認: ブロック評価結果
│   ├─ パラメータ確認: 条件が厳しすぎないか
│   └─ コード確認: Evaluate()ロジック
│
└─ 単体では発生 → 組み合わせの問題
    ├─ 条件が厳しすぎる（AND条件多数）
    ├─ 方向性の不一致（directionPolicy）
    └─ グローバルガード（spread, session等）
```

### 初期化失敗の場合

- "File not found" → 設定ファイルパス確認
- "Unknown block typeId" → BlockRegistry登録確認
- "Invalid JSON" → JSON構文エラー確認
- "Parameter error" → パラメータ型・範囲確認

## テスト結果

テスト結果は `results/` ディレクトリに保存されます：

- `test_report_YYYYMMDD_HHMMSS.txt` - 人間が読みやすい形式
- `test_report_YYYYMMDD_HHMMSS.json` - 機械処理用

## 新ブロック追加時の更新

新しいブロックを追加した場合、以下を更新してください：

1. **`test_single_blocks.json`**:
   - 新ブロック用の戦略追加
   - ブロック定義追加

2. **`test_single_blocks_extra.json`**:
   - Add strategies for blocks beyond MAX_STRATEGIES
   - Add corresponding block definitions

3. **`test_strategy_all_blocks.json`**:
   - 新ブロックを使用する戦略追加

4. **BlockRegistry**:
   - `ea/include/Core/BlockRegistry.mqh`
   - CreateBlock()に新ブロック追加

## 詳細ドキュメント

詳細なテスト戦略については、以下を参照してください：
- `docs/04_operations/80_testing.md` - テスト計画・戦略
