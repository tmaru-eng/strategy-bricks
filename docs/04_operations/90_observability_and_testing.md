# 04_operations/90_observability_and_testing.md
# 観測性（ログ）と検証（テスト）— 運用契約

## 0. 目的
- “なぜ入った／入らなかった” を追跡できること。
- バックテスト／フォワードでの差異を最小化し、検討を継続可能にすること。

## 1. ログ設計（最低限のログイベント）
### 1.1 推奨ログ出力先
- `MQL5/Files/strategy/logs/` 配下に日次ファイル（CSVまたはJSON Lines）

### 1.2 ログイベント種別（必須）
- `CONFIG_LOADED`：formatVersion、strategy数、block数、読み込み結果
- `BAR_EVAL_START`：時刻、シンボル、バー時刻（M1）
- `STRATEGY_EVAL`：strategyId、priority、採用可否、理由（要約）
- `RULEGROUP_EVAL`：ruleGroupId、成立/不成立
- `BLOCK_EVAL`：blockId、typeId、PASS/FAIL/NEUTRAL、reason
- `ORDER_ATTEMPT`：方向、価格、SL/TP、lot、拒否理由
- `ORDER_RESULT`：成功/失敗、ticket、エラーコード
- `MANAGEMENT_ACTION`：トレール、建値、平均利益、平均建値決済、週末決済 等
- `NANPIN_ACTION`：追加エントリー、段数、平均建値、シリーズ損切り 等

### 1.3 ログに含める推奨フィールド
- `ts`：イベント時刻
- `symbol`
- `barTimeM1`：評価対象バー時刻（同一足禁止の追跡に重要）
- `strategyId` / `ruleGroupId` / `blockId`
- `status`、`reason`
- `positionsTotal`、`positionsBySide`（運用デバッグに有効）

## 2. 受入基準をテスト項目に落とす（要件→検証）
### 2.1 必須テスト（MVP）
- 新バーのみエントリー評価される（BAR_EVAL_STARTが1分に1回）
- 同一足再エントリー禁止（同一barTimeM1でORDER_RESULTが複数出ない）
- OR×AND短絡評価（FAILでANDが打ち切られ、成立でORが打ち切られる）
- 制限超過時は管理のみ（ORDER_ATTEMPTが出ずMANAGEMENT_ACTIONのみ）
- 設定参照切れ検出
  - GUI：Exportを抑止
  - EA：ロード停止＋理由ログ（CONFIG_LOADEDで失敗）

### 2.2 推奨テスト（拡張）
- Spreadフィルタ（閾値超過で必ずFAIL）
- Sessionフィルタ（時間外で必ずFAIL）
- インジケータ取得失敗時の安全側停止（FAILで見送り＋ログ）

## 3. 再現性ルール（バックテスト差異を減らすための運用）
- 判定は shift=1（確定足）に固定
- エントリー評価は M1新バーのみ
- 同一足再エントリー禁止（二重ガード）
- IndicatorCacheで同一バー内の値は同じものを参照

## 4. トラブルシュート（最低限）
- 発注失敗：エラーコードと拒否理由を ORDER_RESULT に必ず残す
- CopyBuffer失敗：BLOCK_EVALをFAILにし reason に “IndicatorUnavailable” を残す
- 設定不整合：CONFIG_LOADEDをFAILにして停止（取引処理を走らせない）

## 5. 未決事項（連携先で検討継続）
- ログ形式：CSV vs JSONL（推奨：JSONL）
- GUI側での検証レポート（Strategyごとの静的解析）
- テスト自動化範囲（MQL5は制約があるため、純ロジック部分のテスト分離が有効）