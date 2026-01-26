# MT5 ストラテジーテスター - 手動テスト実行ガイド

## 概要

Strategy Bricks EAのテストを手動で実行するための詳細ガイドです。
コマンドラインでの自動実行は困難なため、MT5のGUIを使用して体系的にテストを実行します。

## テスト準備

### 1. ファイル配置確認

以下のファイルが正しく配置されていることを確認：

```bash
# EA本体
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/StrategyBricks/StrategyBricks.ex5

# テスト設定ファイル
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/active.json
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/test_single_blocks.json
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/test_strategy_advanced.json
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/test_strategy_all_blocks.json
```

### 2. MT5起動

```bash
open "/Applications/MetaTrader 5.app"
```

## テスト実行手順

### 共通設定

すべてのテストで以下の設定を使用：

| 項目 | 設定値 |
|------|--------|
| **シンボル** | USDJPYm |
| **期間** | M1 (1分足) |
| **開始日** | 2025.10.01 |
| **終了日** | 2025.12.31 |
| **モデル** | 全ティック (最も正確) |
| **証拠金** | 1,000,000 JPY |
| **レバレッジ** | 1:100 |

### テスト1: test_single_blocks.json (単体ブロックテスト)

**目的**: 各ブロックを個別にテストして問題を特定

**手順**:

1. MT5で「ツール」→「ストラテジーテスター」を開く
2. 以下を設定：
   - **EA**: `Experts\StrategyBricks\StrategyBricks.ex5`
   - **シンボル**: `USDJPYm`
   - **期間**: `M1`
   - **日付**: `2025.10.01` - `2025.12.31`
3. 「エキスパート設定」をクリック
4. 「入力」タブで：
   - `InpConfigPath` = `strategy/test_single_blocks.json`
5. 「OK」をクリック
6. 「スタート」をクリック
7. テスト完了を待つ（3-5分程度）

**期待結果**:
- 27戦略が実行される
- 各戦略で50-200回の取引が発生
- エラーなし

**確認項目**:
- [ ] EA初期化成功
- [ ] 27ブロックがロードされた
- [ ] 27戦略がロードされた
- [ ] 取引が発生した（各戦略）
- [ ] エラーログなし

**結果記録**:
```
テスト日時: _______________
初期化: 成功 / 失敗
ブロック数: _____
戦略数: _____
総取引回数: _____
エラー: あり / なし
```

### テスト2: active.json (基本戦略テスト)

**目的**: 基本的な戦略が動作することを確認

**手順**:

1. ストラテジーテスターで設定変更
2. 「エキスパート設定」→「入力」タブ：
   - `InpConfigPath` = `strategy/active.json`
3. 「スタート」をクリック

**期待結果**:
- 1戦略が実行される
- 10-50回の取引が発生
- エラーなし

**確認項目**:
- [ ] EA初期化成功
- [ ] 1戦略がロードされた
- [ ] 取引が発生した
- [ ] エラーログなし

**結果記録**:
```
テスト日時: _______________
初期化: 成功 / 失敗
戦略数: _____
取引回数: _____
損益: _____
エラー: あり / なし
```

### テスト3: test_strategy_advanced.json (高度な戦略テスト)

**目的**: 複数ブロックを組み合わせた戦略をテスト

**手順**:

1. ストラテジーテスターで設定変更
2. 「エキスパート設定」→「入力」タブ：
   - `InpConfigPath` = `strategy/test_strategy_advanced.json`
3. 「スタート」をクリック

**期待結果**:
- 3戦略が実行される
- 各戦略で5-30回の取引が発生
- エラーなし

**確認項目**:
- [ ] EA初期化成功
- [ ] 3戦略がロードされた
- [ ] 各戦略で取引が発生した
- [ ] エラーログなし

**結果記録**:
```
テスト日時: _______________
初期化: 成功 / 失敗
戦略数: _____
戦略1取引回数: _____
戦略2取引回数: _____
戦略3取引回数: _____
エラー: あり / なし
```

### テスト4: test_strategy_all_blocks.json (全ブロック網羅テスト)

**目的**: すべてのブロックタイプを使用した戦略をテスト

**手順**:

1. ストラテジーテスターで設定変更
2. 「エキスパート設定」→「入力」タブ：
   - `InpConfigPath` = `strategy/test_strategy_all_blocks.json`
3. 「スタート」をクリック

**期待結果**:
- 4戦略が実行される
- 各戦略で3-20回の取引が発生
- エラーなし

**確認項目**:
- [ ] EA初期化成功
- [ ] 4戦略がロードされた
- [ ] 各戦略で取引が発生した
- [ ] エラーログなし

**結果記録**:
```
テスト日時: _______________
初期化: 成功 / 失敗
戦略数: _____
戦略1取引回数: _____
戦略2取引回数: _____
戦略3取引回数: _____
戦略4取引回数: _____
エラー: あり / なし
```

## ログ確認方法

### エキスパートログ

テスト実行中・実行後に確認：

1. ストラテジーテスター下部の「ジャーナル」タブを確認
2. 以下の情報を探す：
   - `Strategy Bricks EA initialized successfully` - 初期化成功
   - `Preloaded XX blocks` - ブロック読み込み数
   - `Strategies: XX` - 戦略数
   - `ERROR` または `error` - エラーメッセージ

### ログファイル

詳細なログは以下に保存されます：

```
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/logs/YYYYMMDD.log
```

## 問題診断フローチャート

### 取引回数が0の場合

```
取引回数 = 0
    ↓
初期化は成功？
    ├─ NO → EA初期化の問題
    │        - 設定ファイルパスを確認
    │        - JSONフォーマットを確認
    │        - ブロックtypeIdを確認
    │
    └─ YES → エラーログあり？
             ├─ YES → エラー内容を確認
             │         - ブロック実装の問題
             │         - パラメータの問題
             │
             └─ NO → 戦略条件が厳しすぎる
                      - 単体ブロックテストで確認
                      - 条件を緩和
```

### 単体ブロックテストで特定ブロックが失敗

```
特定ブロックで取引0
    ↓
そのブロックのログを確認
    ↓
エラーメッセージあり？
    ├─ YES → ブロック実装を修正
    │
    └─ NO → ブロックの条件が厳しすぎる
             - パラメータを調整
             - 別の期間でテスト
```

## テスト結果レポート作成

すべてのテスト完了後、以下のコマンドで結果をまとめる：

```bash
python3 scripts/generate_test_report.py
```

または手動で `ea/tests/results/` に結果を記録：

```
テスト実行日: YYYY-MM-DD
実行者: _______________

【テスト1: test_single_blocks.json】
状態: PASS / WARNING / FAIL
初期化: 成功 / 失敗
ブロック数: _____
戦略数: _____
取引回数: _____
エラー: _____

【テスト2: active.json】
状態: PASS / WARNING / FAIL
初期化: 成功 / 失敗
戦略数: _____
取引回数: _____
エラー: _____

【テスト3: test_strategy_advanced.json】
状態: PASS / WARNING / FAIL
初期化: 成功 / 失敗
戦略数: _____
取引回数: _____
エラー: _____

【テスト4: test_strategy_all_blocks.json】
状態: PASS / WARNING / FAIL
初期化: 成功 / 失敗
戦略数: _____
取引回数: _____
エラー: _____

【総合評価】
PASS: ___ / 4
WARNING: ___ / 4
FAIL: ___ / 4

【次のアクション】
- [ ] 失敗したテストの原因調査
- [ ] ブロック実装の修正
- [ ] 再テスト実行
```

## 注意事項

1. **テスト期間**: 3ヶ月（2025.10-12）で取引が0回の場合は問題あり
2. **単体テスト優先**: 問題がある場合は単体ブロックテストから実行
3. **ログ保存**: 各テストのログを保存して比較
4. **段階的実行**: 1つずつテストを実行して結果を確認

## 次のステップ

テスト完了後：

1. 結果を `ea/tests/results/` に保存
2. 失敗したテストを特定
3. 該当ブロックの実装を確認・修正
4. 再テスト実行
5. すべてPASSになるまで繰り返し
