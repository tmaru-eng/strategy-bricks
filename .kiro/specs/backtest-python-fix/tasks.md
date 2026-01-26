# タスクリスト: バックテストPython環境修正

## タスク概要

このタスクリストは、PyInstallerでPythonスクリプトをexe化し、Electronからexeを実行する方式に変更するための実装タスクを定義します。

## タスク

### 1. PyInstallerビルドスクリプト作成

#### 1.1 build-exe.ps1スクリプトの作成

- [ ] 1.1.1 `python/build-exe.ps1` を作成
  - 詳細: PyInstallerのインストール確認、依存関係の確認、exe化、検証を実行
  - ファイル: `python/build-exe.ps1`
  - 検証: スクリプトが正常に実行され、`python/dist/backtest_engine.exe`が生成されることを確認

- [ ] 1.1.2 `python/backtest_engine.spec` を作成
  - 詳細: PyInstaller設定ファイル（hiddenimports, excludes, upx設定）
  - ファイル: `python/backtest_engine.spec`
  - 検証: specファイルが正しく構成されていることを確認

- [ ] 1.1.3 `python/requirements.txt` にpyinstallerを追加
  - 詳細: `pyinstaller>=6.0.0` を追加
  - ファイル: `python/requirements.txt`
  - 検証: requirements.txtにpyinstallerが含まれることを確認

#### 1.2 exeのビルドとテスト

- [ ] 1.2.1 build-exe.ps1を実行してexeをビルド
  - 詳細: `cd python && powershell -ExecutionPolicy Bypass -File build-exe.ps1`
  - 検証: `python/dist/backtest_engine.exe`が生成され、ファイルサイズが妥当であることを確認

- [ ] 1.2.2 exeの動作確認
  - 詳細: `.\python\dist\backtest_engine.exe --help` を実行
  - 検証: ヘルプメッセージが表示されることを確認

- [ ] 1.2.3 exeでバックテストを実行
  - 詳細: テスト用の設定ファイルでバックテストを実行
  - 検証: 結果JSONファイルが正しく生成されることを確認

### 2. EnvironmentChecker修正

#### 2.1 exeパス解決の実装

- [ ] 2.1.1 `getBacktestEngineExePath()` メソッドを実装
  - 詳細: 開発モード（`python/dist/backtest_engine.exe`）と本番モード（`resources/python/backtest_engine.exe`）のパス解決
  - ファイル: `gui/electron/main.ts`
  - 検証: 両モードでパスが正しく解決されることを確認

- [ ] 2.1.2 `testBacktestEngine()` メソッドを実装
  - 詳細: `--help` オプションでexeをテスト実行
  - ファイル: `gui/electron/main.ts`
  - 検証: exeが正常に動作することを確認

- [ ] 2.1.3 デバッグログの追加
  - 詳細: チェックしたパス、ファイルの存在確認結果をログ出力
  - ファイル: `gui/electron/main.ts`
  - 検証: ログに必要な情報が含まれることを確認

#### 2.2 Python環境チェックの削除

- [ ] 2.2.1 `checkPython()` メソッドを削除
  - 詳細: Python環境チェックのロジックを削除
  - ファイル: `gui/electron/main.ts`
  - 検証: コンパイルエラーがないことを確認

- [ ] 2.2.2 `checkMT5Library()` メソッドを削除
  - 詳細: MT5ライブラリチェックのロジックを削除
  - ファイル: `gui/electron/main.ts`
  - 検証: コンパイルエラーがないことを確認

- [ ] 2.2.3 `checkEnvironment()` メソッドを簡素化
  - 詳細: OS検出とexe存在確認のみに簡素化
  - ファイル: `gui/electron/main.ts`
  - 検証: 環境チェックが高速化されることを確認

#### 2.3 エラーメッセージの改善

- [ ] 2.3.1 exe不在時のエラーメッセージを改善
  - 詳細: 期待されるパスとビルド手順を含むメッセージを生成
  - ファイル: `gui/electron/main.ts`
  - 検証: エラーメッセージが明確で実用的であることを確認

- [ ] 2.3.2 EnvironmentCheckResultインターフェースを更新
  - 詳細: `pythonAvailable`, `mt5Available` フィールドを削除し、`debug` フィールドを追加
  - ファイル: `gui/electron/main.ts`
  - 検証: 型エラーがないことを確認

### 3. BacktestProcessManager修正

#### 3.1 exeの実行に変更

- [ ] 3.1.1 `startBacktest()` メソッドを修正
  - 詳細: Pythonコマンドの代わりに`EnvironmentChecker.getBacktestEnginePath()`を使用
  - ファイル: `gui/electron/main.ts`
  - 検証: exeが正しく実行されることを確認

- [ ] 3.1.2 コマンドライン引数の構築を確認
  - 詳細: exeに渡す引数が正しいことを確認
  - ファイル: `gui/electron/main.ts`
  - 検証: 引数が正しく渡されることを確認

### 4. BacktestConfigDialog改善

#### 4.1 デフォルト設定の初期化改善

- [ ] 4.1.1 `getInitialConfig()` 関数を実装
  - 詳細: lastConfig → ローカルストレージ → デフォルト値の優先順位で設定を取得
  - ファイル: `gui/src/components/Backtest/BacktestConfigDialog.tsx`
  - 検証: 優先順位が正しく機能することを確認

- [ ] 4.1.2 ダイアログ表示時の初期化ロジックを追加
  - 詳細: `useEffect` で `isOpen` が true になったときに設定を再初期化
  - ファイル: `gui/src/components/Backtest/BacktestConfigDialog.tsx`
  - 検証: ダイアログを開くたびにデフォルト値が表示されることを確認

- [ ] 4.1.3 ログ出力の追加
  - 詳細: 設定の初期化、ローカルストレージの読み書きをログ出力
  - ファイル: `gui/src/components/Backtest/BacktestConfigDialog.tsx`
  - 検証: ログに必要な情報が含まれることを確認

#### 4.2 ローカルストレージの改善

- [ ] 4.2.1 `loadConfigFromStorage()` のエラーハンドリング改善
  - 詳細: try-catch でエラーをキャッチし、詳細なログを出力
  - ファイル: `gui/src/components/Backtest/BacktestConfigDialog.tsx`
  - 検証: 無効なデータがある場合でもクラッシュしないことを確認

- [ ] 4.2.2 `saveConfigToStorage()` のエラーハンドリング改善
  - 詳細: try-catch でエラーをキャッチし、詳細なログを出力
  - ファイル: `gui/src/components/Backtest/BacktestConfigDialog.tsx`
  - 検証: 保存に失敗してもアプリが継続することを確認

### 5. BacktestPanel初期化改善

#### 5.1 環境チェック結果の表示改善

- [ ] 5.1.1 環境チェック中の表示を追加
  - 詳細: ローディングスピナーと「環境をチェック中...」メッセージを表示
  - ファイル: `gui/src/components/Backtest/BacktestPanel.tsx`
  - 検証: チェック中に適切な表示がされることを確認

- [ ] 5.1.2 環境チェック失敗時の表示を改善
  - 詳細: エラーメッセージと詳細情報（デバッグ情報）を表示
  - ファイル: `gui/src/components/Backtest/BacktestPanel.tsx`
  - 検証: エラーメッセージが明確で、デバッグ情報が表示されることを確認

- [ ] 5.1.3 環境チェック成功時の表示を確認
  - 詳細: 「バックテスト実行」ボタンが有効になることを確認
  - ファイル: `gui/src/components/Backtest/BacktestPanel.tsx`
  - 検証: ボタンがクリック可能であることを確認

### 6. electron-builder設定

#### 6.1 electron-builder.config.jsの作成

- [ ] 6.1.1 `gui/electron-builder.config.js` を作成
  - 詳細: バックテストエンジンexeを同梱する設定
  - ファイル: `gui/electron-builder.config.js`
  - 検証: 設定ファイルが正しく構成されていることを確認

- [ ] 6.1.2 package.jsonにビルドスクリプトを追加
  - 詳細: `build:python`, `build:win`, `build:dir` スクリプトを追加
  - ファイル: `gui/package.json`
  - 検証: スクリプトが正しく定義されていることを確認

- [ ] 6.1.3 package.jsonにelectron-builderを追加
  - 詳細: devDependenciesに `electron-builder` を追加
  - ファイル: `gui/package.json`
  - 検証: `npm install` が成功することを確認

### 7. テスト実行

#### 7.1 開発モードテスト

- [ ] 7.1.1 exeをビルド
  - 詳細: `cd python && powershell -ExecutionPolicy Bypass -File build-exe.ps1`
  - 検証: exeが生成されることを確認

- [ ] 7.1.2 GUIアプリを起動
  - 詳細: `cd gui && npm run dev`
  - 検証: アプリが起動し、バックテスト機能が有効になることを確認

- [ ] 7.1.3 バックテストを実行
  - 詳細: GUIからバックテストを実行
  - 検証: バックテストが成功し、結果が表示されることを確認

#### 7.2 パッケージ化テスト

- [ ] 7.2.1 アプリをビルド
  - 詳細: `cd gui && npm run build:dir`
  - 検証: ビルドが成功し、`gui/release`にアプリが生成されることを確認

- [ ] 7.2.2 パッケージ化されたアプリを起動
  - 詳細: `gui/release`からアプリを起動
  - 検証: アプリが起動し、バックテスト機能が有効になることを確認

- [ ] 7.2.3 パッケージ化されたアプリでバックテストを実行
  - 詳細: GUIからバックテストを実行
  - 検証: バックテストが成功し、結果が表示されることを確認

#### 7.3 単体テスト

- [ ] 7.3.1 EnvironmentChecker.getBacktestEngineExePath() のテスト
  - 詳細: 開発モード、本番モード、ファイル不在のケースをテスト
  - ファイル: `gui/electron/__tests__/environment-checker.test.ts`
  - 検証: すべてのケースが正しく処理されることを確認

- [ ] 7.3.2 BacktestConfigDialog デフォルト値のテスト
  - 詳細: デフォルト設定生成、ローカルストレージ読み込み、フォールバックをテスト
  - ファイル: `gui/src/components/Backtest/__tests__/BacktestConfigDialog.test.tsx`
  - 検証: すべてのケースが正しく処理されることを確認

### 8. ドキュメント更新

#### 8.1 README更新

- [ ] 8.1.1 exeビルド手順を追加
  - 詳細: `python/build-exe.ps1` の使用方法
  - ファイル: `python/README.md`
  - 検証: ドキュメントが明確で実用的であることを確認

- [ ] 8.1.2 アプリビルド手順を追加
  - 詳細: `npm run build:win` の使用方法
  - ファイル: `gui/README.md`
  - 検証: ドキュメントが明確で実用的であることを確認

- [ ] 8.1.3 トラブルシューティングセクションを追加
  - 詳細: exeが見つからない場合の解決方法
  - ファイル: `gui/README.md`
  - 検証: ドキュメントが明確で実用的であることを確認

#### 8.2 PYTHON_EMBEDDING.md更新

- [ ] 8.2.1 PyInstallerの使用方法を追加
  - 詳細: PyInstallerでexe化する理由と方法
  - ファイル: `gui/PYTHON_EMBEDDING.md`
  - 検証: ドキュメントが明確で実用的であることを確認

## タスクの依存関係

```
1.1 → 1.2 → 2.1
2.1 → 2.2 → 2.3 → 3.1
4.1 → 4.2 → 5.1
6.1 → 7.2
1.2 → 7.1 → 7.2 → 7.3
7.3 → 8.1 → 8.2
```

## 完了基準

- [ ] すべてのタスクが完了している
- [ ] Pythonスクリプトがexe化されている
- [ ] 開発モードでバックテストが動作する
- [ ] パッケージ化されたアプリでバックテストが動作する
- [ ] すべてのテストが合格している
- [ ] ドキュメントが更新されている
- [ ] Python環境エラーが解決されている
- [ ] GUIでデフォルト設定が表示される

