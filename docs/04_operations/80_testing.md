# テスト計画・戦略

## 概要

Strategy Bricks EAの品質保証のための包括的なテスト戦略を定義します。

## テスト方針

### 基本原則

1. **段階的テスト**: 単体 → 統合 → システム の順でテスト
2. **問題の切り分け**: 各レイヤーで問題を特定できる構造
3. **自動化と手動の組み合わせ**: 効率と信頼性のバランス
4. **継続的な改善**: 新機能追加時にテストも拡張

### テストレイヤー

```
┌─────────────────────────────────────┐
│  システムテスト (MT5 Strategy Tester) │  ← 実際の取引動作確認
├─────────────────────────────────────┤
│  統合テスト (GUI Integration Tests)  │  ← コンポーネント連携確認
├─────────────────────────────────────┤
│  単体テスト (EA Block Unit Tests)    │  ← 個別ブロック動作確認
└─────────────────────────────────────┘
```

## テストタイプ

### 1. GUI統合テスト

**目的**: フロントエンドの動作確認とコンポーネント連携テスト

**場所**: `gui/src/__tests__/`

**実行方法**:
```bash
cd gui
npm test
```

**テスト内容**:
- パレット表示確認
- 全ブロックカテゴリの表示確認
- 複数ブロック組み合わせの設定生成
- バリデーション機能

**テストファイル**:
- `app.integration.test.tsx` - アプリケーション統合テスト
- `validator.test.ts` - バリデーションロジックテスト

**カバレッジ目標**: 80%以上

### 2. EA単体ブロックテスト

**目的**: 各ブロックが単体で正しく動作するか確認

**場所**: `ea/tests/test_single_blocks.json`

**テスト戦略**:
- 1ブロック = 1戦略
- 最もシンプルな条件設定
- 取引発生の可能性を最大化

**テスト設定**:
```json
{
  "strategies": [
    {
      "id": "test_<blockType>_<variant>",
      "conditions": [
        { "blockId": "<single_block>" }  // 単一ブロックのみ
      ],
      "lotModel": { "type": "lot.fixed", "params": { "lots": 0.01 } },
      "riskModel": { "type": "risk.fixedSLTP", "params": { "slPips": 20, "tpPips": 40 } }
    }
  ]
}
```

**カバレッジ**: 全36ブロックタイプ × 27戦略

**期待結果**:
- 初期化成功
- 3ヶ月で50-200回の取引発生
- エラーなし

**問題の切り分け**:
- 取引0回 → そのブロックに問題あり
- エラー発生 → ブロック実装の不具合
- 初期化失敗 → 設定パラメータの問題

### 3. EA統合テスト（複数ブロック組み合わせ）

**目的**: 複数ブロックの組み合わせ動作確認

**場所**: 
- `ea/tests/test_strategy_advanced.json` - 高度な戦略
- `ea/tests/test_strategy_all_blocks.json` - 全ブロック網羅

**テスト戦略**:
- 実際の戦略に近い複雑な条件
- 複数フィルタ・トリガーの組み合わせ
- 各種モデル（Lot/Risk/Exit/Nanpin）の動作確認

**カバレッジ**:
- `test_strategy_advanced.json`: 19ブロック、3戦略
- `test_strategy_all_blocks.json`: 30ブロック、4戦略

**期待結果**:
- 初期化成功
- 3ヶ月で3-30回の取引発生（条件が厳しいため）
- エラーなし

### 4. EA基本動作テスト

**目的**: 基本的な戦略の動作確認

**場所**: `ea/tests/active.json`

**テスト内容**:
- シンプルな戦略（6ブロック）
- 基本的なフィルタ・トリガー・モデル

**期待結果**:
- 初期化成功
- 3ヶ月で10-50回の取引発生
- エラーなし

## テスト実行手順

### 自動テストスクリプト

**場所**: `scripts/automated_tester.py`

**実行方法**:
```bash
python3 scripts/automated_tester.py
```

**機能**:
- 設定ファイルの存在確認
- 手動テスト手順の表示
- テストレポートテンプレート生成

### MT5ストラテジーテスター実行手順

1. MT5を起動
2. ツール > ストラテジーテスター を開く
3. 以下を設定:
   - EA: `Experts\StrategyBricks\StrategyBricks.ex5`
   - シンボル: `USDJPYm`
   - 期間: `M1`
   - 日付: `2025.10.01 - 2025.12.31` (3ヶ月)
   - 初期証拠金: 1,000,000 JPY
   - レバレッジ: 1:100
4. 入力パラメータ: `InpConfigPath=strategy/<test_file>.json`
5. テスト開始
6. 結果を記録:
   - 初期化: 成功/失敗
   - ブロック読み込み数
   - 戦略読み込み数
   - 取引回数
   - エラー有無

### テスト順序（推奨）

```
1. test_single_blocks.json    ← 最優先（問題の切り分け）
   ↓
2. active.json                ← 基本動作確認
   ↓
3. test_strategy_advanced.json ← 複雑な条件確認
   ↓
4. test_strategy_all_blocks.json ← 全機能網羅確認
```

## テスト結果の評価基準

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

## 問題の診断フロー

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

```
初期化失敗
  ↓
エラーログ確認
  ↓
├─ "File not found" → 設定ファイルパス確認
├─ "Unknown block typeId" → BlockRegistry登録確認
├─ "Invalid JSON" → JSON構文エラー確認
└─ "Parameter error" → パラメータ型・範囲確認
```

### エラー発生の場合

```
エラーあり
  ↓
エラーメッセージ確認
  ↓
├─ ブロック評価エラー → 該当ブロックのコード確認
├─ インジケータエラー → IndicatorCache確認
├─ 注文エラー → OrderExecutor確認
└─ その他 → ログ詳細確認
```

## テスト環境

### 必要なファイル配置

**通常実行用**:
```
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/
  drive_c/Program Files/MetaTrader 5/
    MQL5/
      Files/
        strategy/
          ├── active.json
          ├── test_single_blocks.json
          ├── test_strategy_advanced.json
          └── test_strategy_all_blocks.json
```

**ストラテジーテスター用**:
```
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/
  drive_c/Program Files/MetaTrader 5/
    Tester/
      Agent-127.0.0.1-3000/
        Files/
          strategy/
            ├── active.json
            ├── test_single_blocks.json
            ├── test_strategy_advanced.json
            └── test_strategy_all_blocks.json
      Agent-127.0.0.1-3001/
        Files/
          strategy/
            └── (同上)
```

### ファイルコピーコマンド

```bash
# 通常実行用
cp ea/tests/*.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/strategy/"

# テスター用（Agent-3000）
cp ea/tests/*.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"

# テスター用（Agent-3001）
cp ea/tests/*.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3001/Files/strategy/"
```

## テスト結果の記録

### レポートファイル

**場所**: `ea/tests/results/`

**ファイル形式**:
- `test_report_YYYYMMDD_HHMMSS.txt` - 人間が読みやすい形式
- `test_report_YYYYMMDD_HHMMSS.json` - 機械処理用

**記録内容**:
```
- テスト日時
- テスト期間
- 各設定ファイルの結果:
  - 初期化成功/失敗
  - ブロック読み込み数
  - 戦略読み込み数
  - 取引回数
  - エラー数
  - 警告数
```

## 新機能追加時のテスト拡張

### 新ブロック追加時

1. **GUI統合テスト更新**:
   - `gui/src/__tests__/app.integration.test.tsx`
   - 新ブロックの表示確認テスト追加

2. **EA単体テスト更新**:
   - `ea/tests/test_single_blocks.json`
   - 新ブロック用の戦略追加
   - ブロック定義追加

3. **BlockRegistry更新**:
   - `ea/include/Core/BlockRegistry.mqh`
   - CreateBlock()に新ブロック追加

4. **カタログ更新**:
   - `gui/src/resources/block_catalog.default.json`
   - 新ブロックの定義追加

### 新モデル追加時（Lot/Risk/Exit/Nanpin）

1. **統合テスト更新**:
   - `ea/tests/test_strategy_advanced.json`
   - 新モデルを使用する戦略追加

2. **BlockRegistry更新**:
   - 新モデルの登録

3. **カタログ更新**:
   - 新モデルの定義追加

## 継続的インテグレーション（将来）

### 自動化の方向性

1. **GUIテスト**: GitHub Actions等で自動実行
2. **EAコンパイル**: CI/CDパイプラインで自動コンパイル
3. **EAテスト**: MT5 API経由での自動テスト（検討中）

### 現状の制約

- MT5ストラテジーテスターは完全自動化が困難
- 手動実行 + 結果記録の半自動化で運用

## まとめ

### テスト戦略の要点

1. **単体テスト優先**: 問題の早期発見・切り分け
2. **段階的テスト**: シンプル → 複雑 の順で実行
3. **実データ使用**: 3ヶ月の実際の市場データでテスト
4. **継続的改善**: 新機能追加時にテストも拡張

### 成功の指標

- 全単体ブロックテストで取引発生
- 統合テストで期待通りの動作
- エラーなしで初期化成功
- 実運用に近い条件での動作確認

### 次のステップ

1. 4つのテスト設定でMT5テスト実行
2. 結果を記録・分析
3. 問題があれば診断フローに従って修正
4. 全テストPASSまで繰り返し
