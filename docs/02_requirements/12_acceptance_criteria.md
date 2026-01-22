# 02_requirements/12_acceptance_criteria.md
# 受入基準（Acceptance Criteria）— Strategy Bricks（仮称）

## 0. ドキュメント情報
- ファイル名：`docs/02_requirements/12_acceptance_criteria.md`
- 版：v0.1
- 対象：テスト担当、品質保証担当
- 目的：要件とユーザーストーリーをテスト可能な条件として定義

---

## 1. 受入基準とは

受入基準（Acceptance Criteria）は、要件やユーザーストーリーが満たすべきテスト可能な条件です。

**重要な特性:**
- **テスト可能（Testable）**: 明確な検証方法がある
- **測定可能（Measurable）**: 成功/失敗を判定できる
- **明確（Unambiguous）**: 解釈の余地がない

**検証方法:**
- ログベース検証（推奨）
- バックテスト結果検証
- 単体テスト
- 統合テスト

---

## 2. 受入基準カテゴリ

### 2.1 コア機能
- エントリー評価タイミング
- 同一足再エントリー禁止
- OR/AND短絡評価
- ブロック評価

### 2.2 リスク管理
- ポジション制限
- ロット制限
- スプレッド停止
- ナンピン安全装置

### 2.3 設定・バリデーション
- GUI側バリデーション
- EA側バリデーション
- formatVersion互換性

### 2.4 観測性
- ログ出力
- 判定理由の記録
- エラーメッセージ

---

## 3. 受入基準詳細

### AC-01: エントリー評価タイミング（M1新バーのみ）

**条件:**
エントリー評価はM1の新バー発生時のみ実行される。

**検証方法:**
1. バックテストを1時間（60分）実行
2. ログファイルで`BAR_EVAL_START`イベントを検索
3. `BAR_EVAL_START`が60回出現する
4. 各イベントのbarTimeM1が1分刻みで異なる

**成功基準:**
- BAR_EVAL_START回数 = 60
- barTimeM1が連続して1分間隔

**失敗例:**
- BAR_EVAL_STARTが61回以上（同一バーで複数回評価）
- barTimeM1が同じイベントが複数ある

**ログ例（成功）:**
```json
{"ts":"2024-01-10 10:00:00","event":"BAR_EVAL_START","barTimeM1":"2024-01-10 10:00:00"}
{"ts":"2024-01-10 10:01:00","event":"BAR_EVAL_START","barTimeM1":"2024-01-10 10:01:00"}
{"ts":"2024-01-10 10:02:00","event":"BAR_EVAL_START","barTimeM1":"2024-01-10 10:02:00"}
```

---

### AC-02: 同一足再エントリー禁止

**条件:**
同一M1バー内で複数回エントリーが発生しない。

**検証方法:**
1. バックテストで複数のRuleGroupを持つ戦略を実行
2. ログファイルで同一barTimeM1の`ORDER_RESULT`または`ORDER_REJECT`を検索
3. 各barTimeM1でORDER_RESULTは最大1回
4. 2回目以降はORDER_REJECTで"SAME_BAR_REENTRY"

**成功基準:**
- 同一barTimeM1でORDER_RESULTが1回のみ
- 2回目以降はORDER_REJECTログあり

**失敗例:**
- 同一barTimeM1でORDER_RESULTが2回以上

**ログ例（成功）:**
```json
{"ts":"2024-01-10 10:00:30","event":"ORDER_RESULT","success":true,"ticket":123,"barTimeM1":"2024-01-10 10:00:00"}
{"ts":"2024-01-10 10:00:45","event":"ORDER_REJECT","rejectType":"SAME_BAR_REENTRY","reason":"Same bar re-entry is prohibited","barTimeM1":"2024-01-10 10:00:00"}
```

---

### AC-03: OR/AND短絡評価の動作確認

**条件:**
- OR評価: いずれかのRuleGroupがPASSで即座に終了
- AND評価: いずれかのConditionがFAILで即座に終了

**検証方法（OR短絡）:**
1. 3つのRuleGroupを持つ戦略でバックテスト
2. 1番目のRuleGroupが成立するケースのログ確認
3. RULEGROUP_EVALが1番目のみ
4. 2番目・3番目のRULEGROUP_EVALがない

**検証方法（AND短絡）:**
1. 4つのConditionを持つRuleGroupでバックテスト
2. 1番目のConditionがFAILするケースのログ確認
3. BLOCK_EVALが1番目のみ
4. 2番目以降のBLOCK_EVALがない

**成功基準（OR）:**
- 最初に成立したRuleGroupのみ評価される
- 以降のRuleGroupは評価されない

**成功基準（AND）:**
- 最初にFAILしたConditionまでしか評価されない
- 以降のConditionは評価されない

**ログ例（AND短絡）:**
```json
{"ts":"...","event":"BLOCK_EVAL","blockId":"filter.spreadMax#1","status":"PASS"}
{"ts":"...","event":"BLOCK_EVAL","blockId":"trend.maRelation#1","status":"FAIL"}
// trigger.bbReentry#1のBLOCK_EVALなし（短絡）
{"ts":"...","event":"RULEGROUP_EVAL","ruleGroupId":"RG1","matched":false}
```

---

### AC-04: ポジション制限超過時の挙動

**条件:**
ポジション制限超過時、新規エントリーは停止し、ポジション管理のみ実施される。

**検証方法:**
1. globalGuards.maxPositionsTotal = 2 に設定
2. バックテスト実行
3. 2ポジション保有後、3回目のエントリー条件成立時のログ確認
4. LIMIT_EXCEEDEDログあり
5. ORDER_ATTEMPTなし
6. MANAGEMENT_ACTIONあり（ポジション管理は継続）

**成功基準:**
- ポジション数 >= maxPositionsTotal の時
- LIMIT_EXCEEDEDログあり
- ORDER_ATTEMPTなし
- MANAGEMENT_ACTIONあり

**失敗例:**
- 制限超過時にORDER_ATTEMPTがある
- MANAGEMENT_ACTIONがない（管理停止）

**ログ例（成功）:**
```json
{"ts":"...","event":"BAR_EVAL_START","barTimeM1":"..."}
{"ts":"...","event":"LIMIT_EXCEEDED","message":"Total positions limit exceeded: 2/2"}
// ORDER_ATTEMPTなし
{"ts":"...","event":"MANAGEMENT_ACTION","action":"trailing","ticket":123}
```

---

### AC-05: スプレッド超過時の停止

**条件:**
スプレッドが設定値を超えた時、エントリーが停止される。

**検証方法:**
1. filter.spreadMax（maxSpreadPips=2.0）を設定
2. スプレッド3.0pipsの時刻を含むバックテスト
3. ログ確認:
   - BLOCK_EVAL: filter.spreadMax FAIL
   - STRATEGY_EVAL: not matched
   - ORDER_ATTEMPTなし

**成功基準:**
- スプレッド > maxSpreadPips の時
- filter.spreadMaxがFAIL
- エントリーされない

**失敗例:**
- スプレッド超過時にエントリーされる

**ログ例（成功）:**
```json
{"ts":"...","event":"BLOCK_EVAL","blockId":"filter.spreadMax#1","status":"FAIL","reason":"Spread=3.0 pips (max=2.0)"}
{"ts":"...","event":"STRATEGY_EVAL","strategyId":"S1","adopted":false,"reason":"not matched"}
```

---

### AC-06: GUI側バリデーション（必須パラメータ）

**条件:**
必須パラメータが未設定の場合、Exportが抑止される。

**検証方法:**
1. Builderでブロック配置
2. 必須パラメータ（例: maxSpreadPips）を未入力
3. Validateボタン押下
4. ValidationPanelにエラー表示
5. Export実行 → 抑止される

**成功基準:**
- ValidationErrorが検出される
- エラーメッセージに不足パラメータ名が含まれる
- Exportが実行されない

**失敗例:**
- エラー検出されない
- Exportが実行される

**UI表示例（成功）:**
```
❌ Required parameter 'maxSpreadPips' is missing (filter.spreadMax#1)
```

---

### AC-07: EA側バリデーション（formatVersion非互換）

**条件:**
formatVersionが非互換の場合、EA起動時にINIT_FAILEDを返す。

**検証方法:**
1. active.jsonのmeta.formatVersionを"2.0"（非互換）に変更
2. EA起動
3. ExpertログまたはログファイルでCONFIG_ERRORイベント確認
4. OnInitがINIT_FAILEDを返す
5. 取引処理が実行されない

**成功基準:**
- CONFIG_ERRORログあり
- エラーメッセージに"Unsupported formatVersion"
- INIT_FAILED
- BAR_EVAL_STARTなし（取引処理停止）

**失敗例:**
- エラー検出されない
- 取引処理が実行される

**ログ例（成功）:**
```json
{"ts":"...","event":"CONFIG_ERROR","level":"ERROR","message":"Unsupported formatVersion: 2.0 (Supported: 1.0)"}
```

---

### AC-08: ブロック参照切れの検出（EA側）

**条件:**
存在しないblockIdを参照している場合、EA起動時にINIT_FAILEDを返す。

**検証方法:**
1. active.jsonのconditions[]で存在しないblockId（例: "nonexistent#1"）を参照
2. EA起動
3. ログでCONFIG_ERRORイベント確認
4. エラーメッセージに"Block reference not found"
5. INIT_FAILED

**成功基準:**
- CONFIG_ERRORログあり
- 参照切れブロックIDが記録される
- INIT_FAILED

**ログ例（成功）:**
```json
{"ts":"...","event":"CONFIG_ERROR","message":"Block reference not found: nonexistent#1"}
```

---

### AC-09: インジケータ取得失敗時の安全側停止

**条件:**
インジケータハンドル生成またはCopyBuffer失敗時、ブロック評価はFAILを返す。

**検証方法:**
1. 不正なインジケータパラメータ（例: 負の期間）を設定
2. バックテスト実行
3. ログでINDICATOR_ERRORイベント確認
4. BLOCK_EVAL: FAIL
5. エントリーされない

**成功基準:**
- INDICATOR_ERRORログあり
- BLOCK_EVAL: FAIL
- reason: "Indicator unavailable"等

**失敗例:**
- エラー検出されない
- 不正な状態でエントリーされる

**ログ例（成功）:**
```json
{"ts":"...","event":"INDICATOR_ERROR","message":"iMA failed: MA_-10_EMA"}
{"ts":"...","event":"BLOCK_EVAL","blockId":"trend.maRelation#1","status":"FAIL","reason":"Indicator unavailable"}
```

---

### AC-10: ブロック判定理由がログに残る

**条件:**
すべてのブロック評価でreason文字列がログに記録される。

**検証方法:**
1. バックテスト実行
2. BLOCK_EVALイベントを全て確認
3. 各イベントにreasonフィールドあり
4. reasonで判定理由が追跡可能

**成功基準:**
- すべてのBLOCK_EVALにreason
- reasonから判定根拠が分かる（例: "Close[1]=1.10000 vs MA[1]=1.09900"）

**失敗例:**
- reasonがない
- reasonが空文字列
- reasonが無意味（例: "OK"のみ）

**ログ例（成功）:**
```json
{"ts":"...","event":"BLOCK_EVAL","blockId":"trend.maRelation#1","status":"PASS","reason":"Close[1]=1.10500 vs MA[1]=1.10000 (closeAbove)"}
```

---

### AC-11: 発注失敗理由がログに残る

**条件:**
発注失敗時、失敗理由がログに記録される。

**検証方法:**
1. 不正なSL/TP（ストップレベル違反）を設定
2. バックテスト実行
3. ORDER_REJECTまたはORDER_RESULTイベント確認
4. reasonに失敗理由が記録される

**成功基準:**
- ORDER_REJECTまたはORDER_RESULT（success=false）あり
- reasonに具体的な失敗理由（例: "INVALID_SL: SL too close"）

**失敗例:**
- 失敗時にログなし
- reasonがない
- reasonが無意味

**ログ例（成功）:**
```json
{"ts":"...","event":"ORDER_REJECT","rejectType":"INVALID_SL","reason":"SL too close: 1.10000 (min distance=40 points)"}
```

---

### AC-12: ナンピン最大段数制限

**条件:**
ナンピン段数が最大値に達したら追加エントリーされない。

**検証方法:**
1. nanpinModel.maxCount = 3 に設定
2. バックテスト実行
3. 3ポジション保有後、4回目のナンピン条件成立時のログ確認
4. NANPIN_LIMITログあり
5. ORDER_ATTEMPTなし

**成功基準:**
- ポジション数 >= maxCount の時
- NANPIN_LIMITログあり
- 追加エントリーされない

**失敗例:**
- maxCountを超えてエントリーされる

**ログ例（成功）:**
```json
{"ts":"...","event":"NANPIN_LIMIT","message":"Nanpin max count reached: 3/3"}
```

---

### AC-13: ナンピンシリーズ損切り

**条件:**
ナンピンシリーズの累積損失が設定値を超えたら全決済される。

**検証方法:**
1. nanpinModel.seriesStopLoss.amount = 100.0 に設定
2. バックテスト実行
3. 累積損失が-100.0に達した時のログ確認
4. NANPIN_SERIES_CUTログあり
5. POSITION_CLOSEDログあり（全ポジション）

**成功基準:**
- 累積損失 <= -amount の時
- NANPIN_SERIES_CUTログあり
- 全ポジション決済される

**失敗例:**
- シリーズ損切りが発動しない
- 一部のポジションのみ決済

**ログ例（成功）:**
```json
{"ts":"...","event":"NANPIN_SERIES_CUT","message":"Series stop loss triggered: -100.0 <= -100.0"}
{"ts":"...","event":"POSITION_CLOSED","ticket":123,"reason":"Series Stop Loss"}
{"ts":"...","event":"POSITION_CLOSED","ticket":124,"reason":"Series Stop Loss"}
{"ts":"...","event":"POSITION_CLOSED","ticket":125,"reason":"Series Stop Loss"}
```

---

### AC-14: ナンピン最大時BE決済

**条件:**
ナンピン最大段数到達後、平均建値近辺で全決済される。

**検証方法:**
1. nanpinModel.maxCount = 3, breakEvenAtMax = true, breakEvenPips = 0.5 に設定
2. バックテスト実行
3. 3ポジション保有後、平均建値+0.5pips到達時のログ確認
4. NANPIN_BE_AT_MAXログあり
5. POSITION_CLOSEDログあり（全ポジション）

**成功基準:**
- ポジション数 == maxCount かつ 価格 >= 平均建値+閾値 の時
- NANPIN_BE_AT_MAXログあり
- 全ポジション決済される

**失敗例:**
- BE決済が発動しない
- 一部のポジションのみ決済

**ログ例（成功）:**
```json
{"ts":"...","event":"NANPIN_BE_AT_MAX","message":"Break-even at max triggered: avgPrice=1.10000, currentPrice=1.10005"}
{"ts":"...","event":"POSITION_CLOSED","ticket":123,"reason":"Break-Even at Max"}
```

---

### AC-15: ブローカー制約チェック（最小ロット）

**条件:**
ロットがブローカーの最小ロット未満の場合、発注が拒否される。

**検証方法:**
1. lot.fixedで0.001（最小ロット0.01未満）を設定
2. バックテスト実行
3. ORDER_REJECTログ確認
4. rejectType: "INVALID_LOT"
5. reason: "Lot out of range"

**成功基準:**
- lot < SYMBOL_VOLUME_MIN の時
- ORDER_REJECTログあり
- エントリーされない

**ログ例（成功）:**
```json
{"ts":"...","event":"ORDER_REJECT","rejectType":"INVALID_LOT","reason":"Lot out of range: 0.001 (min=0.01, max=100)"}
```

---

### AC-16: ブローカー制約チェック（ストップレベル）

**条件:**
SL/TPがストップレベル未満の場合、発注が拒否される。

**検証方法:**
1. risk.fixedSLTP（slPips=10）を設定
2. ブローカーのストップレベルが40pipsの時にバックテスト
3. ORDER_REJECTログ確認
4. rejectType: "INVALID_SL"
5. reason: "SL too close"

**成功基準:**
- |price - sl| < stopsLevel の時
- ORDER_REJECTログあり
- エントリーされない

**ログ例（成功）:**
```json
{"ts":"...","event":"ORDER_REJECT","rejectType":"INVALID_SL","reason":"SL too close: 1.10000 (min distance=40 points)"}
```

---

### AC-17: セッションフィルタの動作

**条件:**
設定時間外でenv.session.timeWindowがFAILを返す。

**検証方法:**
1. env.session.timeWindow（windows: 07:00-14:59）を設定
2. 15:00の時刻を含むバックテスト
3. BLOCK_EVALログ確認
4. env.session: FAIL
5. reason: "Outside session window"

**成功基準:**
- 現在時刻が設定範囲外の時
- env.sessionがFAIL
- エントリーされない

**ログ例（成功）:**
```json
{"ts":"2024-01-10 15:00:00","event":"BLOCK_EVAL","blockId":"env.session#1","status":"FAIL","reason":"Outside session window"}
```

---

### AC-18: Strategy優先度順評価

**条件:**
複数Strategyがpriority降順で評価される。

**検証方法:**
1. 3つのStrategy（priority: 10, 5, 3）を設定
2. 全てのStrategyがエントリー条件を満たす時のバックテスト
3. STRATEGY_EVALログ確認
4. 評価順序: priority 10 → 5 → 3
5. firstOnlyなら最初のStrategyのみ採用

**成功基準:**
- STRATEGY_EVALがpriority降順で記録される
- firstOnlyの場合、最初のStrategyでエントリー後、残りは評価されない

**ログ例（成功）:**
```json
{"ts":"...","event":"STRATEGY_EVAL","strategyId":"S1","priority":10,"adopted":true}
// S2, S3は評価されない（firstOnly）
```

---

### AC-19: ロット制限超過時の停止

**条件:**
合計ロット数が制限を超える場合、エントリーが拒否される。

**検証方法:**
1. globalGuards.maxLotTotal = 1.0 に設定
2. 既に0.5lot保有中
3. 0.6lotの新規エントリー条件成立
4. ORDER_REJECTログ確認
5. rejectType: "LOT_EXCEEDED"
6. reason: "Total lot would exceed maxLotTotal"

**成功基準:**
- currentTotalLot + newLot > maxLotTotal の時
- ORDER_REJECTログあり
- エントリーされない

**ログ例（成功）:**
```json
{"ts":"...","event":"ORDER_REJECT","rejectType":"LOT_EXCEEDED","reason":"Total lot would exceed maxLotTotal: 1.1 > 1.0"}
```

---

### AC-20: 週末決済の動作

**条件:**
金曜日の指定時刻に全ポジションが決済される。

**検証方法:**
1. exit.weekend（closeTime: "23:50", dayOfWeek: "Friday"）を設定
2. 金曜23:50を含むバックテスト
3. 金曜23:50にポジション保有中
4. MANAGEMENT_ACTIONログ確認
5. POSITION_CLOSEDログあり（全ポジション）

**成功基準:**
- 金曜23:50の時
- MANAGEMENT_ACTION: "Weekend close"
- 全ポジション決済される

**ログ例（成功）:**
```json
{"ts":"2024-01-12 23:50:00","event":"MANAGEMENT_ACTION","action":"weekend_close","message":"Weekend close: Friday 23:50"}
{"ts":"...","event":"POSITION_CLOSED","ticket":123,"reason":"Weekend Close"}
```

---

### AC-21: トレーリングストップの動作

**条件:**
利益が出たらSLが建値に移動し、さらにトレールする。

**検証方法:**
1. exit.trailing（breakEvenPips: 10.0, trailStartPips: 20.0, trailStepPips: 5.0）を設定
2. エントリー後+10pips, +20pips, +25pips到達するバックテスト
3. MANAGEMENT_ACTIONログ確認:
   - +10pips: "BreakEven: SL moved to entry price"
   - +20pips: "Trailing start: +20 pips"
   - +25pips: "Trailing: SL moved to +20 pips"

**成功基準:**
- 指定pipsで建値移動
- 指定pipsでトレール開始
- トレールステップでSL追従

**ログ例（成功）:**
```json
{"ts":"...","event":"MANAGEMENT_ACTION","action":"breakeven","message":"BreakEven: SL moved to entry price"}
{"ts":"...","event":"MANAGEMENT_ACTION","action":"trailing_start","message":"Trailing start: +20 pips"}
{"ts":"...","event":"MANAGEMENT_ACTION","action":"trailing","message":"Trailing: SL moved to +20 pips"}
```

---

### AC-22: 緊急停止の発動

**条件:**
異常検知時に取引が停止される。

**検証方法:**
1. 何らかの異常（例: ポジション数が設定値10を大幅に超える）を発生させる
2. ANOMALY_DETECTEDログ確認
3. EMERGENCY_STOPログ確認
4. 以降のBAR_EVAL_STARTなし

**成功基準:**
- 異常検知時
- ANOMALY_DETECTEDログあり
- EMERGENCY_STOPログあり
- 取引処理停止

**ログ例（成功）:**
```json
{"ts":"...","event":"ANOMALY_DETECTED","level":"ERROR","message":"Too many positions: 11"}
{"ts":"...","event":"EMERGENCY_STOP","level":"ERROR","message":"Anomaly detected, trading halted"}
// 以降、BAR_EVAL_STARTなし
```

---

### AC-23: 設定参照切れの検出（GUI側）

**条件:**
存在しないblockIdを参照している場合、Exportが抑止される。

**検証方法:**
1. Canvasでブロックを削除
2. 別のRuleGroupがそのブロックを参照中
3. Validateボタン押下
4. ValidationPanelにエラー表示
5. Export実行 → 抑止される

**成功基準:**
- ValidationErrorが検出される
- エラーメッセージに参照切れブロックIDが含まれる
- Exportが実行されない

**UI表示例（成功）:**
```
❌ Block reference not found: trend.maRelation#1
```

---

### AC-24: 型不整合の検出（GUI側）

**条件:**
パラメータの型が不正な場合、Exportが抑止される。

**検証方法:**
1. 手動でJSONファイルを編集してmaxSpreadPipsに文字列"abc"を設定
2. BuilderでOpen
3. Validateボタン押下
4. ValidationPanelにエラー表示
5. Export実行 → 抑止される

**成功基準:**
- ValidationErrorが検出される
- エラーメッセージに型不整合が含まれる
- Exportが実行されない

**UI表示例（成功）:**
```
❌ Parameter 'maxSpreadPips' has invalid type (expected: number)
```

---

### AC-25: 範囲外パラメータの検出（GUI側）

**条件:**
パラメータが範囲外の場合、Exportが抑止される。

**検証方法:**
1. maxSpreadPipsに-1.0（minimum: 0.0未満）を入力
2. Validateボタン押下
3. ValidationPanelにエラー表示
4. Export実行 → 抑止される

**成功基準:**
- ValidationErrorが検出される
- エラーメッセージに範囲外が含まれる
- Exportが実行されない

**UI表示例（成功）:**
```
❌ Parameter 'maxSpreadPips' is below minimum (0.0)
```

---

### AC-26: 絶対条件の検証（EA側）

**条件:**
M1固定、useClosedBarOnly=true、noReentrySameBar=true が守られていない場合、INIT_FAILEDを返す。

**検証方法:**
1. active.jsonでglobalGuards.timeframe = "M5"（M1以外）に変更
2. EA起動
3. CONFIG_ERRORログ確認
4. エラーメッセージ: "globalGuards.timeframe must be M1"
5. INIT_FAILED

**成功基準:**
- 絶対条件違反時
- CONFIG_ERRORログあり
- INIT_FAILED

**ログ例（成功）:**
```json
{"ts":"...","event":"CONFIG_ERROR","message":"globalGuards.timeframe must be M1, got: M5"}
```

---

### AC-27: ログローテーションの動作

**条件:**
ログファイルが日次でローテーションされる。

**検証方法:**
1. バックテストを複数日（例: 2024-01-10〜2024-01-12）実行
2. MQL5/Files/strategy/logs/フォルダ確認
3. 各日のログファイルが生成される:
   - strategy_20240110.jsonl
   - strategy_20240111.jsonl
   - strategy_20240112.jsonl

**成功基準:**
- 日付ごとに別ファイルが生成される
- 各ファイルに対応日のログが含まれる

---

### AC-28: バックテストとフォワードの一貫性

**条件:**
同じ設定・同じ期間でバックテストを複数回実行した時、結果が同じになる。

**検証方法:**
1. 戦略Aでバックテスト実行（2024-01-01〜2024-01-31）
2. 結果（Total Trades, Profit等）を記録
3. 同じ設定で再度バックテスト実行
4. 結果比較 → 完全一致

**成功基準:**
- Total Trades一致
- Profit一致
- ログファイル内容一致（エントリー時刻、価格等）

**失敗例:**
- 結果が異なる（再現性なし）

---

### AC-29: 複数シンボル独立動作

**条件:**
複数シンボルで独立してエントリー評価が行われる。

**検証方法:**
1. EURUSDとGBPUSDのチャートにEAを適用
2. globalGuards.maxPositionsPerSymbol = 1 に設定
3. バックテスト実行
4. ログ確認:
   - EURUSDでエントリー → ポジション1
   - GBPUSDでエントリー → ポジション1
   - 各シンボルで独立してLIMIT_EXCEEDEDが発動

**成功基準:**
- 各シンボルで独立して動作
- シンボル別にポジション制限が機能

---

### AC-30: 設定Export後の即座反映

**条件:**
BuilderでExport後、EAを再起動すると新設定が反映される。

**検証方法:**
1. 戦略AでExport → active.json生成
2. EA起動 → 戦略Aで動作
3. 戦略BでExport → active.json更新
4. EA再起動
5. ログ確認: CONFIG_LOADEDで戦略Bの内容
6. 戦略Bで動作

**成功基準:**
- active.json更新後、EA再起動で新設定が読み込まれる
- ログで設定内容が確認できる

---

## 4. 受入基準の優先順位

**Critical（必須 - MVP）:**
- AC-01, AC-02, AC-03, AC-04, AC-05
- AC-06, AC-07, AC-08, AC-09, AC-10
- AC-11, AC-26, AC-28

**High（優先度高）:**
- AC-12, AC-13, AC-14, AC-15, AC-16
- AC-17, AC-18, AC-19, AC-23, AC-24
- AC-25, AC-30

**Medium（優先度中）:**
- AC-20, AC-21, AC-22, AC-27, AC-29

**Low（将来拡張）:**
- （追加の受入基準は実装時に定義）

---

## 5. 受入基準の検証方法まとめ

**ログベース検証（推奨）:**
- JSONL形式のログファイルを解析
- イベント種別・タイムスタンプ・理由で検証
- 自動化しやすい

**バックテスト結果検証:**
- Strategy Testerのレポート
- Total Trades, Profit, Drawdown等

**単体テスト:**
- ConfigValidator, CompositeEvaluator, Block等
- MQL5では制約があるため、純ロジック部分のみ

**統合テスト:**
- GUI → EA連携
- Export → 読込 → 実行

---

## 6. 参照ドキュメント

本受入基準は以下のドキュメントを基に作成されています:

- `docs/02_requirements/10_requirements.md` - 要件定義書（AC-01〜AC-06）
- `docs/02_requirements/11_user_stories.md` - ユーザーストーリー
- `docs/03_design/50_ea_runtime_design.md` - EA Runtime詳細設計
- `docs/03_design/60_gui_builder_design.md` - GUI Builder詳細設計
- `docs/03_design/70_security_safety.md` - セキュリティ・安全設計
- `docs/04_operations/90_observability_and_testing.md` - 観測性とテスト

次のステップ:
- `docs/04_operations/80_testing.md` - テスト計画（受入基準をテストケースに変換）

---
