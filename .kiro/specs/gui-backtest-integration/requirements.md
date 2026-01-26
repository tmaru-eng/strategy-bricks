# 要件定義書

## はじめに

本書は、Strategy Bricks GUIビルダーにバックテスト機能を統合するための要件を定義します。この機能により、ユーザーはGUIで生成したストラテジー設定に対して、PythonのMetaTrader5ライブラリを使用してバックテストを実行でき、手動でのMQL5コンパイルやMetaTraderターミナル操作なしに、ストラテジーのパフォーマンスを即座に確認できます。

## 用語集

- **GUI_Builder**: ビジュアルストラテジー作成のためのElectronベースのStrategy Bricks GUIアプリケーション
- **Backtest_Engine**: MetaTrader5ライブラリを使用してバックテストシミュレーションを実行するPythonベースのコンポーネント
- **Strategy_Config**: GUI_Builderが生成するストラテジーロジックとパラメータを含むJSONファイル
- **IPC_Handler**: GUIとPythonプロセスを橋渡しするElectronプロセス間通信ハンドラー
- **MT5_Library**: 過去の市場データにアクセスするためのMetaTrader5 Pythonライブラリ
- **Backtest_Results**: トレード履歴、パフォーマンス指標、統計情報を含むJSON出力
- **Backtest_Parameters**: シンボル、時間軸、日付範囲を含むユーザー指定の設定

## 要件

### 要件1: バックテスト設定インターフェース

**ユーザーストーリー:** ストラテジー開発者として、GUIでバックテストパラメータを設定したい。そうすることで、特定の市場条件に対してストラテジーをテストできる。

#### 受入基準

1. WHEN ユーザーが「バックテスト実行」ボタンをクリックした時、THE GUI_Builder SHALL バックテスト設定ダイアログを表示する
2. THE GUI_Builder SHALL シンボル（デフォルト: USDJPY）、時間軸（デフォルト: M1）、日付範囲（デフォルト: 過去3ヶ月）の入力フィールドを提供する
3. WHEN ユーザーが有効なバックテストパラメータを送信した時、THE GUI_Builder SHALL 設定をIPC_Handlerに渡す
4. WHEN ユーザーが無効なパラメータを送信した時、THE GUI_Builder SHALL 検証エラーを表示し、バックテスト実行を防止する
5. THE GUI_Builder SHALL 次回セッションのために最後に使用したバックテストパラメータを保持する

### 要件2: ストラテジー設定のエクスポート

**ユーザーストーリー:** ストラテジー開発者として、バックテスト前にGUIで作成したストラテジーが自動保存されることを望む。そうすることで、バックテストが現在のストラテジー設定を使用する。

#### 受入基準

1. WHEN バックテストが開始された時、THE GUI_Builder SHALL 現在のストラテジー設定をStrategy_Config JSONファイルにシリアライズする
2. THE GUI_Builder SHALL Strategy_Configを一意のファイル名でea/tests/ディレクトリに保存する
3. THE GUI_Builder SHALL Strategy_ConfigファイルパスをIPC_Handlerに渡す
4. WHEN ストラテジー設定が無効または不完全な時、THE GUI_Builder SHALL バックテスト実行を防止し、エラーメッセージを表示する

### 要件3: Pythonプロセス管理

**ユーザーストーリー:** システムコンポーネントとして、Pythonバックテストプロセスを起動・管理したい。そうすることで、GUIをブロックせずにバックテストを確実に実行できる。

#### 受入基準

1. WHEN IPC_Handlerがバックテストリクエストを受信した時、THE IPC_Handler SHALL Backtest_Engineスクリプトを使用してPythonプロセスを起動する
2. THE IPC_Handler SHALL Strategy_ConfigファイルパスとBacktest_Parametersをコマンドライン引数としてPythonプロセスに渡す
3. WHEN Pythonプロセスが正常終了した時、THE IPC_Handler SHALL 出力ファイルからBacktest_Resultsを読み取る
4. WHEN Pythonプロセスが失敗またはタイムアウトした時、THE IPC_Handler SHALL エラー出力をキャプチャし、GUI_Builderに失敗を報告する
5. THE IPC_Handler SHALL 設定可能なタイムアウト期間（デフォルト: 5分）後に長時間実行中のPythonプロセスを終了する

### 要件4: 過去データの取得

**ユーザーストーリー:** バックテストエンジンとして、MetaTrader5から過去の市場データを取得したい。そうすることで、実際の市場条件でストラテジー実行をシミュレートできる。

#### 受入基準

1. WHEN Backtest_Engineが起動した時、THE Backtest_Engine SHALL MT5_Libraryへの接続を初期化する
2. WHEN MT5_Libraryへの接続が失敗した時、THE Backtest_Engine SHALL 説明的なエラーメッセージで終了する
3. THE Backtest_Engine SHALL 指定されたシンボル、時間軸、日付範囲の過去のティックまたはバーデータをMT5_Libraryにリクエストする
4. WHEN 過去データが利用不可または不完全な時、THE Backtest_Engine SHALL 説明的なエラーメッセージで終了する
5. THE Backtest_Engine SHALL シミュレーションを進める前に、取得したデータが要求された日付範囲をカバーしていることを検証する

### 要件5: ストラテジー実行シミュレーション

**ユーザーストーリー:** バックテストエンジンとして、過去データに対してストラテジーロジックを実行したい。そうすることで、現実的なトレード結果を生成できる。

#### 受入基準

1. THE Backtest_Engine SHALL Strategy_Config JSONファイルを解析してストラテジーロジックとパラメータを抽出する
2. WHEN Strategy_Configが不正または無効な時、THE Backtest_Engine SHALL 説明的なエラーメッセージで終了する
3. THE Backtest_Engine SHALL 過去データを時系列順に反復処理し、ストラテジーのエントリー/エグジット条件を評価する
4. WHEN ストラテジー条件が満たされた時、THE Backtest_Engine SHALL タイムスタンプと価格を含むシミュレートされたトレードのエントリーとエグジットを記録する
5. THE Backtest_Engine SHALL エントリー価格、エグジット価格、ポジションサイズに基づいてポジションの損益を計算する

### 要件6: 結果生成

**ユーザーストーリー:** バックテストエンジンとして、包括的なバックテスト結果を生成したい。そうすることで、ユーザーがストラテジーのパフォーマンスを評価できる。

#### 受入基準

1. WHEN バックテストシミュレーションが完了した時、THE Backtest_Engine SHALL 総トレード数、勝ちトレード数、負けトレード数、勝率を計算する
2. THE Backtest_Engine SHALL 総損益、最大ドローダウン、平均トレード損益を計算する
3. THE Backtest_Engine SHALL すべてのトレード記録とパフォーマンス指標をBacktest_Results JSONファイルにシリアライズする
4. THE Backtest_Engine SHALL IPC_Handlerがアクセス可能な予測可能な出力パスにBacktest_Resultsを保存する
5. THE Backtest_Results SHALL メタデータを含む: ストラテジー名、シンボル、時間軸、日付範囲、実行タイムスタンプ

### 要件7: 結果表示

**ユーザーストーリー:** ストラテジー開発者として、GUIでバックテスト結果を表示したい。そうすることで、ストラテジーのパフォーマンスを迅速に評価できる。

#### 受入基準

1. WHEN バックテスト実行が正常に完了した時、THE GUI_Builder SHALL Backtest_Results JSONファイルを解析する
2. THE GUI_Builder SHALL 主要なパフォーマンス指標を表示する: 総トレード数、勝率、総損益、最大ドローダウン
3. THE GUI_Builder SHALL エントリー/エグジットのタイムスタンプ、価格、損益を含む個別トレードのスクロール可能なリストを表示する
4. WHEN バックテスト実行が失敗した時、THE GUI_Builder SHALL Backtest_EngineまたはIPC_Handlerからのエラーメッセージを表示する
5. THE GUI_Builder SHALL Backtest_Resultsをユーザー指定のファイル場所にエクスポートするオプションを提供する

### 要件8: 進捗フィードバック

**ユーザーストーリー:** ストラテジー開発者として、バックテストの進捗更新を確認したい。そうすることで、システムが動作していることを知り、完了時間を推定できる。

#### 受入基準

1. WHEN バックテストが開始された時、THE GUI_Builder SHALL 「バックテスト実行中」を示す進捗インジケーターを表示する
2. WHILE バックテストが実行中の時、THE GUI_Builder SHALL レスポンシブな状態を維持し、ユーザーが操作をキャンセルできるようにする
3. WHEN ユーザーが実行中のバックテストをキャンセルした時、THE IPC_Handler SHALL Pythonプロセスを終了し、一時ファイルをクリーンアップする
4. WHEN バックテストが完了または失敗した時、THE GUI_Builder SHALL 進捗インジケーターを非表示にし、結果またはエラーを表示する
5. THE GUI_Builder SHALL バックテスト実行中の経過時間を表示する

### 要件9: プラットフォーム互換性

**ユーザーストーリー:** システム管理者として、明確なプラットフォーム要件を望む。そうすることで、ユーザーがバックテスト機能が利用可能な場所を理解できる。

#### 受入基準

1. THE GUI_Builder SHALL 起動時にオペレーティングシステムを検出する
2. WHEN MT5_Libraryが利用可能なWindowsで実行している時、THE GUI_Builder SHALL バックテスト機能を有効にする
3. WHEN Windows以外のプラットフォームで実行している時、THE GUI_Builder SHALL バックテスト機能を無効にし、プラットフォーム互換性メッセージを表示する
4. WHEN WindowsでMT5_Libraryがインストールされていない時、THE GUI_Builder SHALL バックテスト試行時にインストール手順を表示する
5. THE GUI_Builder SHALL バックテスト機能を有効にする前に、Python環境とMT5_Libraryの可用性を検証する

### 要件10: エラーハンドリングとリカバリー

**ユーザーストーリー:** ストラテジー開発者として、バックテストが失敗した時に明確なエラーメッセージを望む。そうすることで、問題を診断し修正できる。

#### 受入基準

1. WHEN いずれかのコンポーネントがエラーに遭遇した時、THE システム SHALL デバッグ用の詳細なエラー情報をログに記録する
2. THE GUI_Builder SHALL 失敗を説明し、是正措置を提案するユーザーフレンドリーなエラーメッセージを表示する
3. WHEN バックテストが失敗した時、THE システム SHALL 一時ファイルをクリーンアップし、準備完了状態にリセットする
4. THE システム SHALL ネットワーク中断、MT5接続失敗、ファイルシステムエラーを適切に処理する
5. WHEN 複数のバックテストリクエストが送信された時、THE IPC_Handler SHALL リクエストをキューに入れ、順次実行する
