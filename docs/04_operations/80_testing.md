# テスト計画・戦略

## 概要

Strategy Bricks EAの品質保証のための包括的なテスト戦略を定義します。

## テスト入口（Windows / Wine）

Strategy Tester は **Windows / Wine（macOS）** の両方で運用します。  
バックテスト（GUI）は **Windows のみ対応**です。  
実行手順は以下を参照してください。

- Backtest（GUI/Windowsのみ）: `docs/04_operations/60_backtest_windows.md`
- Strategy Tester（Windows/手動）: `docs/04_operations/70_strategy_tester_windows.md`
- GUI-EA統合テスト: `docs/04_operations/75_gui_ea_integration_test.md`
- Wine（macOS）での Strategy Tester: `scripts/run_mt5_tests.sh` / `scripts/run_mt5_tester.sh`
- ログ/観測: `docs/04_operations/90_observability_and_testing.md`
## GUI結合テスト（ビルダー → GUIバックテスト → Strategy Tester）

GUIビルダーで作成した設定が **GUIバックテスター** と **MT5 Strategy Tester** の両方で
正しく動作することを確認します。  
同一コンフィグ名で成果物を揃え、どの結果がどれかを必ず追跡できるようにします。

### 前提

- Windows + MT5ログイン済み・オンライン
- 期間はデータが存在する範囲（推奨: 直近7日）
- Strategy Tester を CLI で起動する場合、**MT5が起動中なら終了してから実行**

### 手順

1) **GUIビルダーでユニット構成を作成**  
   - 1条件ブロック + 最小構成で作成  
   - 保存先: `ea/tests/strategy_<timestamp>.json`

2) **GUIバックテストを実行**  
   - 出力: `ea/tests/strategy_<timestamp>_results.json`  
   - `metadata.symbol` を確認（接尾辞付きシンボルが入る）

3) **Strategy Tester で同一コンフィグを実行**  
   - シンボルは **結果JSONの `metadata.symbol`** を使用  
   - 例:
   ```powershell
   $config = "ea/tests/strategy_<timestamp>.json"
   $results = "ea/tests/strategy_<timestamp>_results.json"
   $symbol = (Get-Content $results -Raw | ConvertFrom-Json).metadata.symbol

   .\scripts\run_mt5_strategy_test.ps1 -Portable:$false `
     -ConfigPath $config `
     -Symbol $symbol
   ```

### 補助スクリプト（推奨）

GUIで作成したコンフィグを渡すだけで、GUIバックテストとStrategy Testerを連続実行できます。

```powershell
# 直近7日シナリオ（default）
.\scripts\run_gui_integration_flow.ps1 -ConfigPath "ea\tests\strategy_<timestamp>.json" -StopMt5

# ディレクトリ内の設定を一括で結合テスト
.\scripts\run_gui_integration_suite.ps1 -ConfigDir "ea\tests" -Pattern "strategy_*.json" -StopMt5

# Playwrightシナリオ → 結合テスト一括実行
.\scripts\run_gui_e2e_suite.ps1 -StopMt5

# シナリオ指定（scripts/scenarios/gui_integration_scenarios.json）
.\scripts\run_gui_integration_flow.ps1 `
  -ConfigPath "ea\tests\strategy_<timestamp>.json" `
  -Scenario "recent-30d" `
  -StopMt5
```

シナリオは `scripts/scenarios/gui_integration_scenarios.json` に追加できます。  
`symbol` は 6桁（例: `USDJPY`）で指定して問題ありません。

### 出力ファイルの対応

- 設定: `ea/tests/strategy_<timestamp>.json`
- GUIバックテスト: `ea/tests/strategy_<timestamp>_results.json`
- Strategy Tester レポート: `ea/tests/results/strategy_<timestamp>.htm`
- ブロック評価サマリー:  
  `ea/tests/results/strategy_<timestamp>_block_summary.txt/json`

### 判定

- **GUIバックテスト**: 結果JSONが生成され、`summary.totalTrades` が存在
- **Strategy Tester**: レポートが生成され、初期証拠金が0でない  
  かつ `block_summary` の `Blocks missing = 0`

### シンボル指定の注意

MT5はブローカー接尾辞が付くため、**入力は6桁（例: USDJPY）でOK**ですが、  
**Strategy Tester では結果JSONの `metadata.symbol` を使う**のが確実です。

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

## テスト環境（Windows）

ファイル配置・パスの正は `docs/04_operations/70_strategy_tester_windows.md` を参照。

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
   - `ea/tests/test_single_blocks_extra.json` (extra blocks beyond MAX_STRATEGIES)
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
