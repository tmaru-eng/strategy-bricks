# 要件定義書: バックテストPython環境修正

## はじめに

本書は、バックテスト機能のPython環境検出エラーとGUIのデフォルト設定表示の問題を修正するための要件を定義します。現在、埋め込みPythonが正しく検出されず、GUIのバックテスト設定ダイアログでデフォルト値が表示されない問題が発生しています。

## 用語集

- **Embedded_Python**: `gui/python-embedded/`ディレクトリに配置された埋め込みPythonランタイム
- **Environment_Checker**: Python環境の可用性を検証するElectronメインプロセスのコンポーネント
- **Backtest_Config_Dialog**: バックテスト設定を入力するGUIダイアログコンポーネント
- **Default_Config**: デフォルトのバックテスト設定（USDJPY, M1, 過去3ヶ月）

## 要件

### 要件1: 埋め込みPython検出の修正

**ユーザーストーリー:** ユーザーとして、埋め込みPythonが正しく検出されることを望む。そうすることで、Pythonを別途インストールせずにバックテスト機能を使用できる。

#### 受入基準

1. WHEN アプリケーションが起動した時、THE Environment_Checker SHALL 開発モードでは`gui/python-embedded/python.exe`を検出する
2. WHEN アプリケーションが起動した時、THE Environment_Checker SHALL 本番モードでは`resources/python-embedded/python.exe`を検出する
3. WHEN 埋め込みPythonが見つかった時、THE Environment_Checker SHALL Pythonバージョンを検証する
4. WHEN 埋め込みPythonが有効な時、THE Environment_Checker SHALL システムPythonより優先して使用する
5. WHEN 埋め込みPythonが見つからない時、THE Environment_Checker SHALL システムPythonにフォールバックする

### 要件2: Python環境エラーメッセージの改善

**ユーザーストーリー:** ユーザーとして、Python環境が見つからない場合に明確なエラーメッセージを望む。そうすることで、問題を理解し解決できる。

#### 受入基準

1. WHEN 埋め込みPythonもシステムPythonも見つからない時、THE GUI SHALL 「Python環境が見つかりません」というエラーメッセージを表示する
2. WHEN Python環境チェックが失敗した時、THE システム SHALL チェックしたパスをログに記録する
3. WHEN エラーメッセージが表示される時、THE GUI SHALL 埋め込みPythonの場所を示す
4. THE エラーメッセージ SHALL ユーザーが問題を解決するための手順を含む

### 要件3: GUIデフォルト設定の表示

**ユーザーストーリー:** ユーザーとして、バックテスト設定ダイアログを開いた時にデフォルト値が表示されることを望む。そうすることで、すぐにバックテストを実行できる。

#### 受入基準

1. WHEN バックテスト設定ダイアログが開かれた時、THE GUI SHALL デフォルト値を表示する（シンボル: USDJPY, 時間軸: M1, 日付範囲: 過去3ヶ月）
2. WHEN ローカルストレージに保存された設定がある時、THE GUI SHALL 保存された設定をデフォルト値として使用する
3. WHEN ローカルストレージに設定がない時、THE GUI SHALL システムデフォルト値を使用する
4. THE デフォルト値 SHALL すべての入力フィールドに適用される
5. THE デフォルト値 SHALL ユーザーが変更可能である

### 要件4: バックテスト設定の永続化

**ユーザーストーリー:** ユーザーとして、最後に使用したバックテスト設定が保存されることを望む。そうすることで、次回同じ設定を再入力する必要がない。

#### 受入基準

1. WHEN ユーザーがバックテストを実行した時、THE GUI SHALL 設定をローカルストレージに保存する
2. WHEN アプリケーションが再起動された時、THE GUI SHALL 保存された設定を読み込む
3. WHEN 保存された設定が無効な時、THE GUI SHALL デフォルト値にフォールバックする
4. THE 保存された設定 SHALL JSON形式でローカルストレージに格納される
5. THE 保存された設定 SHALL 日付をISO形式で保存する

### 要件5: Python環境チェックの信頼性向上

**ユーザーストーリー:** システムコンポーネントとして、Python環境チェックが確実に動作することを望む。そうすることで、ユーザーに正確な環境状態を報告できる。

#### 受入基準

1. WHEN Python環境をチェックする時、THE Environment_Checker SHALL タイムアウト（5秒）を設定する
2. WHEN Pythonコマンドが失敗した時、THE Environment_Checker SHALL 次のコマンドを試行する（python, python3, py）
3. WHEN すべてのコマンドが失敗した時、THE Environment_Checker SHALL 埋め込みPythonの状態を報告する
4. THE Environment_Checker SHALL チェック結果をキャッシュする
5. THE Environment_Checker SHALL 詳細なログを出力する

### 要件6: バックテストパネルの初期状態

**ユーザーストーリー:** ユーザーとして、バックテストパネルが適切な初期状態で表示されることを望む。そうすることで、機能が利用可能かどうかを理解できる。

#### 受入基準

1. WHEN バックテストパネルが表示された時、THE GUI SHALL 環境チェック結果を表示する
2. WHEN Python環境が利用可能な時、THE GUI SHALL 「バックテスト実行」ボタンを有効にする
3. WHEN Python環境が利用不可な時、THE GUI SHALL 「バックテスト実行」ボタンを無効にし、理由を表示する
4. THE バックテストパネル SHALL 環境チェックの進行状況を表示する
5. THE バックテストパネル SHALL エラーメッセージを明確に表示する

### 要件7: 埋め込みPythonのセットアップ検証

**ユーザーストーリー:** 開発者として、埋め込みPythonが正しくセットアップされていることを検証したい。そうすることで、ユーザーに配布する前に問題を発見できる。

#### 受入基準

1. THE 埋め込みPython SHALL `gui/python-embedded/python.exe`に配置される
2. THE 埋め込みPython SHALL MetaTrader5ライブラリを含む
3. THE 埋め込みPython SHALL numpyライブラリを含む
4. WHEN 埋め込みPythonが実行された時、THE システム SHALL バージョン情報を出力する
5. WHEN 埋め込みPythonでMT5をインポートした時、THE システム SHALL エラーなく完了する

