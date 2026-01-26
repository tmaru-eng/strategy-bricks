# 実装計画: GUI-EA Config Integration Fix

## 概要

本実装計画は、GUI BuilderとEA Runtime間のblockId参照不一致問題を修正するためのタスクを定義します。実装は以下のアプローチで進めます:

1. GUI側でノードベースのblockId割り当てを実装
2. Exporterを修正してblockId再生成を削除
3. 検証ロジックを強化（GUI側とEA側）
4. 統合テストで動作確認

## タスク

- [x] 1. GUI側: NodeManagerの実装
  - NodeManagerクラスを作成し、conditionノードへのblockId割り当てロジックを実装
  - typeId毎のカウンター管理を実装
  - ノードIDとblockIdのマッピングを保持
  - _要件: 1.1, 4.2_

- [ ] 2. GUI側: Exporterの修正
  - [x] 2.1 buildBlocks関数を修正
    - グローバルインデックスによるblockId生成を削除
    - node.data.blockIdを使用するように変更
    - _要件: 1.2, 4.3_
  
  - [x] 2.2 buildStrategies関数を修正
    - ローカルインデックスによるblockId再生成を削除
    - condition.data.blockIdを使用するように変更
    - _要件: 1.2, 4.3_
  
  - [ ]* 2.3 Exporterのプロパティテストを作成
    - **Property 9: blockId割り当てと保持の一貫性**
    - **Validates: 要件 4.2, 4.3**

- [ ] 3. GUI側: Validatorの拡張
  - [x] 3.1 BlockIdReferenceRuleを実装
    - すべてのcondition.blockIdがblocks[]に存在することを検証
    - エラーメッセージに詳細な位置情報を含める
    - _要件: 2.1_
  
  - [x] 3.2 DuplicateBlockIdRuleを実装
    - blocks[]配列内の重複blockIdを検出
    - 重複回数をエラーメッセージに含める
    - _要件: 2.4_
  
  - [x] 3.3 BlockIdFormatRuleを実装
    - blockIdが`{typeId}#{index}`形式に従うことを検証
    - 正規表現パターンマッチングを使用
    - _要件: 4.1_
  
  - [ ]* 3.4 Validatorのプロパティテストを作成
    - **Property 4: Validator参照検証**
    - **Property 5: 重複blockId検出**
    - **Validates: 要件 2.1, 2.4**

- [ ] 4. GUI側: UIの更新
  - [x] 4.1 ValidationErrorDisplayコンポーネントを作成
    - 検証エラーを視覚的に表示
    - エラータイプ、メッセージ、位置情報を表示
    - _要件: 2.3_
  
  - [x] 4.2 エクスポートボタンに検証を統合
    - エクスポート前に検証を実行
    - 検証失敗時はエクスポートを防止
    - エラーをUIに表示
    - _要件: 2.3_

- [x] 5. チェックポイント - GUI側の動作確認
  - すべてのGUI側テストが成功することを確認
  - ユーザーに質問があれば確認


- [ ] 6. EA側: ConfigLoaderの拡張
  - [x] 6.1 ValidateBlockReferences関数を実装
    - すべてのcondition.blockIdがblocks[]に存在することを検証
    - 欠落参照を詳細にログ出力
    - 検証失敗時はfalseを返す
    - _要件: 3.1_
  
  - [x] 6.2 ValidateDuplicateBlockIds関数を実装
    - blocks[]配列内の重複blockIdを検出
    - 重複を詳細にログ出力
    - 検証失敗時はfalseを返す
    - _要件: 3.1_
  
  - [x] 6.3 ValidateBlockIdFormat関数を実装
    - blockIdが`{typeId}#{index}`形式に従うことを検証
    - `#`セパレータの存在を確認
    - インデックス部分が数値であることを確認
    - _要件: 3.1_
  
  - [x] 6.4 LoadConfig関数を修正
    - JSON読み込み後に検証関数を呼び出す
    - 検証失敗時はINIT_FAILEDを返す
    - 成功時はログに記録
    - _要件: 3.1, 3.2_
  
  - [ ]* 6.5 ConfigLoaderのユニットテストを作成
    - 有効な設定の検証成功をテスト
    - 無効な設定の検証失敗をテスト
    - 重複blockIdの検出をテスト
    - _要件: 3.1_

- [ ] 7. EA側: Loggerの拡張
  - [x] 7.1 新しいログイベントを追加
    - CONFIG_VALIDATION_FAILED
    - UNRESOLVED_BLOCK_REFERENCE
    - DUPLICATE_BLOCK_ID
    - INVALID_BLOCK_ID_FORMAT
    - _要件: 3.2_
  
  - [x] 7.2 エラーログに詳細情報を含める
    - blockId、strategy ID、ruleGroup IDを含める
    - JSONL形式で出力
    - _要件: 3.2_

- [x] 8. チェックポイント - EA側の動作確認
  - すべてのEA側テストが成功することを確認
  - ユーザーに質問があれば確認

- [x] 9. 統合テストの実装
  - [x] 9.1 GUI生成設定のテストスクリプトを作成
    - GUIで複数の戦略設定をエクスポート
    - 共有ブロックと固有ブロックを含む
    - _要件: 5.1_
  
  - [x] 9.2 EA読み込みテストスクリプトを作成
    - GUI生成設定をEAで読み込み
    - 初期化成功を確認
    - ログにエラーがないことを確認
    - _要件: 5.2_
  
  - [x] 9.3 戦略評価テストスクリプトを作成
    - EAで戦略評価を実行
    - すべてのブロックが解決されることを確認
    - ログに評価結果が記録されることを確認
    - _要件: 5.3_
  
  - [ ]* 9.4 統合テストのプロパティテストを作成
    - **Property 2: condition参照の解決可能性**
    - **Property 6: ConfigLoader参照検証**
    - **Property 7: BlockRegistry参照解決**
    - **Validates: 要件 1.2, 3.1, 3.4**

- [x] 10. ドキュメントの更新
  - [x] 10.1 interface_contracts.mdを更新
    - blockId割り当てルールを追加
    - 検証ルールを追加
    - _要件: 4.1_
  
  - [x] 10.2 config_spec.mdを更新
    - blockId形式の仕様を明確化
    - 検証要件を追加
    - _要件: 4.1_
  
  - [x] 10.3 TESTING_GUIDE.mdを更新
    - 統合テストの実行方法を追加
    - トラブルシューティングガイドを追加
    - _要件: 5.4_

- [x] 11. 最終チェックポイント
  - すべてのテストが成功することを確認
  - ドキュメントが最新であることを確認
  - ユーザーに質問があれば確認

## 注意事項

- `*`マークのタスクはオプションです（より速いMVPのためにスキップ可能）
- 各タスクは特定の要件を参照しており、トレーサビリティを確保しています
- チェックポイントは段階的な検証を保証します
- プロパティテストは普遍的な正確性プロパティを検証します
- ユニットテストは特定の例とエッジケースを検証します
