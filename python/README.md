# Strategy Bricks Backtest Engine

このディレクトリには、Strategy Bricks GUIビルダーで作成されたストラテジー設定を
MetaTrader5の過去データに対してバックテストするためのPythonエンジンが含まれています。

## セットアップ

### 前提条件

- Python 3.8以上
- MetaTrader5ターミナル（Windowsのみ）
- pip（Pythonパッケージマネージャー）

### インストール

```bash
# 依存関係をインストール
pip install -r requirements.txt
```

### 依存関係

- **MetaTrader5**: MT5ターミナルとの通信、過去データの取得
- **hypothesis**: プロパティベーステスト用ライブラリ
- **pytest**: テストフレームワーク
- **mypy**: 型チェック用ツール

## 使用方法

### 基本的な使用方法

```bash
python backtest_engine.py \
  --config ../ea/tests/active.json \
  --symbol USDJPY \
  --timeframe M1 \
  --start 2024-01-01T00:00:00Z \
  --end 2024-03-31T23:59:59Z \
  --output ../tmp/backtest/results_123.json
```

### パラメータ

- `--config`: ストラテジー設定JSONファイルのパス（必須）
- `--symbol`: 取引シンボル（例: USDJPY）（必須）
- `--timeframe`: 時間軸（M1, M5, M15, M30, H1, H4, D1）（必須）
- `--start`: バックテスト開始日時（ISO形式）（必須）
- `--end`: バックテスト終了日時（ISO形式）（必須）
- `--output`: 結果出力JSONファイルのパス（必須）

### 例

#### 3ヶ月間のバックテスト

```bash
python backtest_engine.py \
  --config ../ea/tests/my_strategy.json \
  --symbol USDJPY \
  --timeframe M1 \
  --start 2024-01-01T00:00:00Z \
  --end 2024-03-31T23:59:59Z \
  --output ../tmp/backtest/results_my_strategy.json
```

出力先は `tmp/` 配下など git 管理外のディレクトリを推奨します。

## 入力ファイル形式

### ストラテジー設定JSON

バックテストエンジンは、統一設定ファイルフォーマット（`ea/tests/CONFIG_SCHEMA.md`参照）に準拠した
JSON設定ファイルを読み込みます。

必須フィールド:
- `meta`: メタデータ（formatVersion, name, generatedBy, generatedAt）
- `strategies`: ストラテジー定義の配列
- `blocks`: ブロック定義の配列

詳細は `ea/tests/CONFIG_SCHEMA.md` を参照してください。

## 出力ファイル形式

### バックテスト結果JSON

バックテストエンジンは、以下の構造のJSON結果ファイルを出力します：

```json
{
  "metadata": {
    "strategyName": "My Strategy",
    "symbol": "USDJPY",
    "timeframe": "M1",
    "startDate": "2024-01-01T00:00:00Z",
    "endDate": "2024-03-31T23:59:59Z",
    "executionTimestamp": "2024-04-01T10:30:00Z"
  },
  "summary": {
    "totalTrades": 150,
    "winningTrades": 90,
    "losingTrades": 60,
    "winRate": 60.0,
    "totalProfitLoss": 125.50,
    "maxDrawdown": 45.20,
    "avgTradeProfitLoss": 0.84
  },
  "trades": [
    {
      "entryTime": "2024-01-01T10:00:00Z",
      "entryPrice": 145.123,
      "exitTime": "2024-01-01T10:15:00Z",
      "exitPrice": 145.156,
      "positionSize": 1.0,
      "profitLoss": 0.033,
      "type": "BUY"
    }
  ]
}
```

## アーキテクチャ

### BacktestEngineクラス

メインのバックテストエンジンクラスで、以下の責務を持ちます：

1. **MT5初期化**: MetaTrader5ライブラリの初期化と接続
2. **設定読み込み**: ストラテジー設定JSONの読み込みと検証
3. **データ取得**: MT5から過去データを取得
4. **シミュレーション**: ストラテジーロジックのシミュレーション
5. **結果生成**: バックテスト結果の計算とJSON出力

### 主要メソッド

- `run()`: バックテスト実行のメインフロー
- `initialize_mt5()`: MT5ライブラリの初期化
- `load_strategy_config()`: ストラテジー設定の読み込み
- `fetch_historical_data()`: 過去データの取得
- `simulate_strategy()`: ストラテジーシミュレーション
- `generate_results()`: 結果生成とJSON出力
- `calculate_max_drawdown()`: 最大ドローダウンの計算

## 制限事項

### MVP段階の制限

現在の実装は簡易的なシミュレーションロジックを使用しています：

1. **ブロック評価**: すべてのブロックタイプが完全にサポートされているわけではありません
2. **簡易シグナル**: エントリー/エグジットシグナルは簡易的なロジック（移動平均クロスオーバー）を使用
3. **固定ロット**: ポジションサイズは固定（1.0）

将来のタスクで、完全なブロックベースの評価ロジックが実装される予定です。

### プラットフォーム制限

- **Windows専用**: MetaTrader5ライブラリはWindowsでのみ動作します
- **MT5必須**: MetaTrader5ターミナルがインストールされている必要があります

## テスト

### 単体テスト

```bash
# すべてのテストを実行
pytest

# 特定のテストファイルを実行
pytest tests/test_backtest_engine.py

# カバレッジレポート付きで実行
pytest --cov=backtest_engine
```

### プロパティベーステスト

プロパティベーステストは、Hypothesisライブラリを使用して実装されます。
詳細は `.kiro/specs/gui-backtest-integration/design.md` を参照してください。

```bash
# プロパティテストを実行
pytest tests/test_properties.py
```

## トラブルシューティング

### MT5初期化失敗

**エラー**: `MT5初期化失敗`

**原因**:
- MetaTrader5ターミナルが起動していない
- MetaTrader5ライブラリがインストールされていない

**解決方法**:
1. MetaTrader5ターミナルを起動
2. `pip install MetaTrader5` を実行

### データ取得失敗

**エラー**: `データ取得失敗`

**原因**:
- 指定されたシンボルが存在しない
- 指定された日付範囲のデータが利用できない
- MT5ターミナルがログインしていない

**解決方法**:
1. MT5ターミナルでシンボルを確認
2. 日付範囲を調整
3. MT5ターミナルにログイン

### 設定ファイルエラー

**エラー**: `無効なJSON形式` または `必須フィールドが見つかりません`

**原因**:
- 設定ファイルのJSON形式が不正
- 必須フィールドが欠落している

**解決方法**:
1. JSON形式を検証（JSONリンターを使用）
2. `ea/tests/CONFIG_SCHEMA.md` を参照して必須フィールドを確認

## 開発

### コードスタイル

- PEP 8に準拠
- 型ヒントを使用
- Docstringを記述

### 型チェック

```bash
# mypyで型チェック
mypy backtest_engine.py
```

## 関連ドキュメント

- [統一設定ファイルスキーマ](../ea/tests/CONFIG_SCHEMA.md)
- [バックテスト統合要件](.kiro/specs/gui-backtest-integration/requirements.md)
- [バックテスト統合設計](.kiro/specs/gui-backtest-integration/design.md)
- [バックテスト統合タスク](.kiro/specs/gui-backtest-integration/tasks.md)

## ライセンス

MIT License

## 作成者

Strategy Bricks Development Team
