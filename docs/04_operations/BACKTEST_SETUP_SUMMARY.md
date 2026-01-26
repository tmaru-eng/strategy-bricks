# バックテスト機能セットアップ完了

## 実装内容

### 1. Python埋め込み版の統合

✅ **完了**: GUIアプリケーションにPython 3.11.9を同梱
- 場所: `gui/python-embedded/`
- MetaTrader5ライブラリをプリインストール
- ユーザーは別途Pythonをインストール不要

### 2. 自動検出機能

✅ **完了**: 起動時に自動的にPython環境を検出
- 優先順位:
  1. 埋め込みPython（`gui/python-embedded/python.exe`）
  2. システムPython（`python`, `python3`, `py`）

### 3. 環境チェック

✅ **完了**: 以下の項目を自動チェック
- OS: Windows検出
- Python: バージョン確認
- MT5ライブラリ: インストール確認

### 4. エラーハンドリング

✅ **完了**: ユーザーフレンドリーなエラーメッセージ
- 環境エラー
- 設定エラー
- 実行時エラー
- 一時ファイルの自動クリーンアップ

## 使用方法

### 開発環境でのテスト

1. **GUIアプリケーションを起動**
   ```powershell
   cd gui
   npm run dev
   ```

2. **バックテストパネルを開く**
   - アプリケーション起動後、バックテストタブをクリック
   - 環境チェックが自動的に実行される

3. **バックテストを実行**
   - 「バックテスト実行」ボタンをクリック
   - シンボル、時間軸、期間を入力
   - MT5ターミナルが起動していることを確認
   - 実行ボタンをクリック

### トラブルシューティング

#### エラー: 「バックテストプロセスの起動に失敗しました」

**原因**: Pythonプロセスの起動に失敗

**解決策**:
1. Electronのコンソールログを確認
2. 埋め込みPythonが正しくインストールされているか確認
   ```powershell
   gui\python-embedded\python.exe --version
   ```
3. MT5ライブラリがインストールされているか確認
   ```powershell
   gui\python-embedded\python.exe -c "import MetaTrader5; print('OK')"
   ```

#### エラー: 「MT5初期化失敗」

**原因**: MT5ターミナルが起動していない

**解決策**:
1. MT5ターミナルを起動
2. デモ口座またはリアル口座にログイン
3. バックテストを再実行

#### エラー: 「データ取得失敗」

**原因**: 指定したシンボルが利用できない

**解決策**:
1. MT5で利用可能なシンボルを確認
2. 別のシンボルを試す（例: EURUSD, GBPUSD）
3. シンボルを気配値表示に追加

## ファイル構成

```
strategy-bricks/
├── gui/
│   ├── python-embedded/          # 埋め込みPython
│   │   ├── python.exe
│   │   ├── python311.dll
│   │   ├── Lib/
│   │   └── Scripts/
│   ├── electron/
│   │   └── main.ts              # 環境チェック・プロセス管理
│   └── src/
│       └── components/
│           └── Backtest/        # バックテストUI
├── python/
│   └── backtest_engine.py       # バックテストエンジン
└── ea/
    └── tests/                   # 設定・結果ファイル
```

## 次のステップ

### 本番環境へのパッケージ化

1. **electron-builder設定を更新**
   - `gui/package.json`に`python-embedded`を含める
   - ビルド時に埋め込みPythonをコピー

2. **インストーラーを作成**
   ```powershell
   cd gui
   npm run build
   ```

3. **配布**
   - 生成されたインストーラーを配布
   - ユーザーはPythonをインストール不要

### 機能拡張

- [ ] バックテスト結果のグラフ表示
- [ ] 複数シンボルの同時バックテスト
- [ ] バックテスト履歴の保存・比較
- [ ] 最適化機能（パラメータ最適化）

## テスト済み環境

- **OS**: Windows 10/11
- **Python**: 3.11.9（埋め込み版）
- **MT5**: Build 5541
- **Node.js**: v18+
- **Electron**: v28+

## 参考資料

- [Python埋め込み版ドキュメント](https://docs.python.org/3/using/windows.html#embedded-distribution)
- [MetaTrader5 Pythonライブラリ](https://www.mql5.com/ja/docs/python_metatrader5)
- [Electron プロセス管理](https://www.electronjs.org/docs/latest/api/child-process)
