# Python Backtest Engine - Setup Guide

## インストール手順

### 1. Python環境の確認

```bash
# Pythonバージョンを確認（3.8以上が必要）
python --version
```

### 2. 依存関係のインストール

```bash
# pythonディレクトリに移動
cd python

# 依存関係をインストール
pip install -r requirements.txt
```

### 3. MetaTrader5の確認

- MetaTrader5ターミナルがインストールされていることを確認
- Windows環境でのみ動作します

## インストールされる依存関係

- **MetaTrader5** (>=5.0.0): MT5ターミナルとの通信、過去データの取得
- **hypothesis** (>=6.0.0): プロパティベーステスト用ライブラリ
- **pytest** (>=7.0.0): テストフレームワーク
- **mypy** (>=1.0.0): 型チェック用ツール

## 動作確認

### バックテストエンジンのヘルプを表示

```bash
python backtest_engine.py --help
```

### 簡単な動作確認

```bash
# MT5が起動していることを確認してから実行
python backtest_engine.py \
  --config ../ea/tests/CONFIG_SCHEMA.md \
  --symbol USDJPY \
  --timeframe M1 \
  --start 2024-01-01T00:00:00Z \
  --end 2024-01-31T23:59:59Z \
  --output test_results.json
```

注意: 上記は動作確認用です。実際の設定ファイルを使用する場合は、
`ea/tests/CONFIG_SCHEMA.md`に準拠したJSONファイルを指定してください。

## トラブルシューティング

### ImportError: No module named 'MetaTrader5'

**解決方法:**
```bash
pip install MetaTrader5
```

### MT5初期化失敗

**原因:**
- MetaTrader5ターミナルが起動していない
- Windows以外のOSで実行している

**解決方法:**
1. MetaTrader5ターミナルを起動
2. Windows環境で実行していることを確認

## 次のステップ

1. **設定ファイルの作成**: `ea/tests/CONFIG_SCHEMA.md`を参照して、ストラテジー設定ファイルを作成
2. **バックテストの実行**: 作成した設定ファイルを使用してバックテストを実行
3. **結果の確認**: 出力されたJSONファイルで結果を確認

詳細は `README.md` を参照してください。
