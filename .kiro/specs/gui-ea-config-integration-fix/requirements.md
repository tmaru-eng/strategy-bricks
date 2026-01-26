# 要件定義書

## はじめに

本仕様書は、GUI BuilderとEA Runtime間の重大な統合問題に対処します。blockId参照の不一致により、EAがGUI生成の戦略設定を正しく実行できない問題が発生しています。GUI Exporterは全conditionノードに対してグローバルインデックスでblockIdを生成しますが、strategy参照を構築する際にruleGroup内のローカルインデックスでblockIdを再生成するため、参照の不一致が発生し、EAがブロックを解決できなくなります。

## 用語集

- **GUI_Builder**: Electronベースのグラフィカル戦略構築アプリケーション
- **EA_Runtime**: 戦略を実行するMT5エキスパートアドバイザー
- **blockId**: `{typeId}#{index}` 形式のブロックインスタンスの一意識別子
- **typeId**: ブロックのタイプ識別子（例: "filter.spreadMax", "trend.maRelation"）
- **Condition**: ruleGroupのAND句内のブロック参照
- **RuleGroup**: ANDロジックで結合された条件の集合
- **EntryRequirement**: ORロジックで結合されたruleGroupの集合
- **ConfigLoader**: strategy_config.jsonを読み込み検証するEAコンポーネント
- **BlockRegistry**: blockId参照をブロック実装に解決するEAコンポーネント

## 要件

### 要件1: 一貫したblockId生成

**ユーザーストーリー:** 戦略開発者として、GUIが一貫したblockIdを生成することで、EAがすべてのブロック参照を正しく解決できるようにしたい。

#### 受入基準

1. GUIが戦略設定をエクスポートする時、THE GUI_Builder SHALL すべてのブロックに対して一意のblockIdを生成する
2. GUIがcondition参照を構築する時、THE GUI_Builder SHALL blocks配列で割り当てられたものと同じblockIdを使用する
3. 複数のconditionが同じブロックインスタンスを参照する時、THE GUI_Builder SHALL すべての参照に対して同じblockIdを使用する
4. THE GUI_Builder SHALL strategies[].entryRequirement.ruleGroups[].conditions[].blockIdで参照されるすべてのblockIdがblocks[]配列に存在することを保証する

### 要件2: blockId参照の検証

**ユーザーストーリー:** 戦略開発者として、GUIがエクスポート前にblockId参照を検証することで、設定エラーを早期に発見したい。

#### 受入基準

1. GUIが設定を検証する時、THE Validator SHALL すべてのblockId参照が解決可能であることを確認する
2. blockId参照が解決できない時、THE Validator SHALL 説明的なエラーメッセージを報告する
3. 検証が失敗した時、THE GUI_Builder SHALL エクスポートを防止し、検証エラーを表示する
4. THE Validator SHALL blocks[]配列内の重複blockIdを確認する

### 要件3: EA設定読み込み

**ユーザーストーリー:** EAオペレーターとして、EAがGUI生成の設定を正常に読み込むことで、GUIで設計した戦略を実行できるようにしたい。

#### 受入基準

1. EAが設定を読み込む時、THE ConfigLoader SHALL すべてのblockId参照がblocks[]配列に存在することを検証する
2. blockId参照が欠落している時、THE ConfigLoader SHALL 説明的なエラーをログに記録し、初期化を拒否する
3. すべてのblockId参照が有効な時、THE ConfigLoader SHALL 戦略エンジンを正常に初期化する
4. THE BlockRegistry SHALL 戦略評価中にすべてのblockId参照を正常に解決する

### 要件4: blockId形式の仕様

**ユーザーストーリー:** システムアーキテクトとして、blockId形式の明確な仕様により、GUIとEAの実装が一貫するようにしたい。

#### 受入基準

1. THE System SHALL blockId形式を `{typeId}#{uniqueIndex}` と定義する（uniqueIndexは正の整数）
2. ノードがキャンバスに追加される時、THE GUI_Builder SHALL ノードIDに基づいて一意のblockIdを割り当てる
3. 設定をエクスポートする時、THE GUI_Builder SHALL 再生成せずに割り当てられたblockIdを保持する
4. THE EA_Runtime SHALL blockIdを解析してブロック作成用のtypeIdを抽出する

### 要件5: 統合テスト

**ユーザーストーリー:** 品質保証エンジニアとして、GUI-EA統合を検証する自動テストにより、blockId問題がデプロイ前に発見されるようにしたい。

#### 受入基準

1. テストがGUI設定をエクスポートする時、THE Test SHALL すべてのblockId参照が解決可能であることを検証する
2. テストがEAで設定を読み込む時、THE Test SHALL 初期化が成功することを検証する
3. テストが戦略評価を実行する時、THE Test SHALL すべてのブロックが正しく解決されることを検証する
4. THE Test SHALL 共有ブロックと固有ブロックを持つ複数の戦略をカバーする
