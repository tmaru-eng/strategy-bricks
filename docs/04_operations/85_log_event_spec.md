# 04_operations/85_log_event_spec.md
# ログイベント仕様書 — Strategy Bricks（仮称）

## 0. ドキュメント情報
- ファイル名：`docs/04_operations/85_log_event_spec.md`
- 版：v1.0
- 対象：EA実装担当・運用担当・検証スクリプト開発担当
- 目的：全ログイベント種別の完全な定義により、ログ出力の一致と追跡可能性を保証

---

## 1. 概要と目的

このドキュメントは、Strategy BricksのEA Runtimeが出力するすべてのログイベント種別を完全に定義します。

### 1.1 ログ設計の基本方針

**追跡可能性（Observability）:**
- すべての判定・発注・拒否理由をログに残す
- "なぜ入った／入らなかった"を追跡可能にする
- バックテスト／フォワードでの差異を最小化

**構造化ログ（JSONL形式）:**
- 1行1イベント（JSON Lines形式）
- 機械可読性を優先
- 検証スクリプトでの自動解析を容易に

**日次ローテーション:**
- ファイルパス：`MQL5/Files/strategy/logs/strategy_YYYYMMDD.jsonl`
- 日付が変わると新ファイルに切り替え

### 1.2 ログレベル

| レベル | 用途 | 例 |
|--------|------|-----|
| INFO | 通常動作の情報 | BAR_EVAL_START, BLOCK_EVAL, ORDER_RESULT |
| WARN | 警告（動作継続可能） | LIMIT_EXCEEDED, GUARD_TRIGGERED |
| ERROR | エラー（動作停止または機能制限） | CONFIG_ERROR, INDICATOR_ERROR |

---

## 2. 全イベント種別一覧

### 2.1 イベント種別サマリー

| イベント種別 | カテゴリ | レベル | 出力頻度 | 目的 |
|-------------|---------|--------|---------|------|
| CONFIG_LOADED | 初期化 | INFO/ERROR | 1回（OnInit） | 設定読込結果 |
| INIT_SUCCESS | 初期化 | INFO | 1回（OnInit） | 初期化成功 |
| INIT_FAILED | 初期化 | ERROR | 1回（OnInit） | 初期化失敗 |
| BAR_EVAL_START | 評価 | INFO | 毎M1新バー | 新バー評価開始 |
| STRATEGY_EVAL | 評価 | INFO | 戦略毎 | Strategy評価結果 |
| RULEGROUP_EVAL | 評価 | INFO | RuleGroup毎 | RuleGroup評価結果 |
| BLOCK_EVAL | 評価 | INFO | ブロック毎 | ブロック評価結果 |
| ORDER_ATTEMPT | 発注 | INFO | 発注試行毎 | 発注試行 |
| ORDER_RESULT | 発注 | INFO | 発注試行毎 | 発注結果 |
| ORDER_REJECT | 発注 | WARN | 発注拒否毎 | 発注拒否理由 |
| LIMIT_EXCEEDED | ガード | WARN | 制限超過時 | ポジション制限超過 |
| GUARD_TRIGGERED | ガード | WARN | ガード作動時 | その他ガード作動 |
| MANAGEMENT_ACTION | 管理 | INFO | 管理アクション毎 | ポジション管理アクション |
| POSITION_CLOSE | 管理 | INFO | 決済毎 | ポジション決済 |
| NANPIN_ACTION | ナンピン | INFO | ナンピン動作時 | ナンピンアクション |
| INDICATOR_ERROR | エラー | ERROR | エラー発生時 | インジケータエラー |
| CONFIG_ERROR | エラー | ERROR | エラー発生時 | 設定エラー |
| RUNTIME_ERROR | エラー | ERROR | エラー発生時 | 実行時エラー |

### 2.2 共通フィールド（全イベント）

| フィールド | 型 | 必須 | 説明 | 例 |
|-----------|-----|------|------|-----|
| ts | string | ✓ | イベント発生時刻（ISO8601形式） | "2026-01-22 10:01:00" |
| event | string | ✓ | イベント種別 | "BAR_EVAL_START" |
| level | string | △ | ログレベル（ERROR/WARNのみ） | "ERROR" |
| symbol | string | △ | シンボル名 | "USDJPY" |

---

## 3. イベント種別詳細定義

### 3.1 初期化系イベント

#### 3.1.1 CONFIG_LOADED

**目的**: 設定ファイル読込結果を記録

**出力タイミング**: OnInit時、設定ファイル読込完了後

**レベル**: INFO（成功）/ ERROR（失敗）

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:00:00",
  "event": "CONFIG_LOADED",
  "success": true,
  "version": "1.0",
  "strategyCount": 1,
  "blockCount": 4
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| success | boolean | ✓ | 読込成功/失敗 |
| version | string | ✓ | formatVersion |
| strategyCount | number | ✓ | Strategy数 |
| blockCount | number | ✓ | Block数 |
| reason | string | △ | 失敗理由（success=falseの場合） |

**使用例**:
```mql5
// 成功時
m_logger->LogConfigLoaded(true, "1.0", 1, 4);

// 失敗時
m_logger->LogConfigLoaded(false, "", 0, 0);
// + LogError("CONFIG_ERROR", "File not found");
```

#### 3.1.2 INIT_SUCCESS

**目的**: EA初期化成功を記録

**出力タイミング**: OnInit完了時

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:00:00",
  "event": "INIT_SUCCESS",
  "message": "EA initialized successfully"
}
```

#### 3.1.3 INIT_FAILED

**目的**: EA初期化失敗を記録

**出力タイミング**: OnInit失敗時

**レベル**: ERROR

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:00:00",
  "event": "INIT_FAILED",
  "level": "ERROR",
  "reason": "Unsupported formatVersion: 2.0"
}
```

---

### 3.2 評価系イベント

#### 3.2.1 BAR_EVAL_START

**目的**: M1新バー評価開始を記録

**出力タイミング**: M1新バー検知後、戦略評価開始前

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "BAR_EVAL_START",
  "symbol": "USDJPY",
  "barTimeM1": "2026-01-22 10:01:00"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| symbol | string | ✓ | シンボル名 |
| barTimeM1 | string | ✓ | 評価対象のM1バー時刻 |

**使用タイミング**:
- NewBarDetector::IsNewBar() == trueの直後
- 1分に1回のみ出力される（同一足再エントリー禁止の検証に重要）

**検証方法**:
```python
# 検証スクリプト例
events = load_jsonl("strategy_20260122.jsonl")
bar_starts = [e for e in events if e["event"] == "BAR_EVAL_START"]

# 1分間隔チェック
for i in range(len(bar_starts) - 1):
    delta = parse_time(bar_starts[i+1]["barTimeM1"]) - parse_time(bar_starts[i]["barTimeM1"])
    assert delta == timedelta(minutes=1), f"BAR_EVAL_START not at 1-min interval: {delta}"
```

#### 3.2.2 STRATEGY_EVAL

**目的**: Strategy評価結果を記録

**出力タイミング**: 各Strategy評価完了後

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "STRATEGY_EVAL",
  "strategyId": "S1",
  "priority": 10,
  "adopted": true,
  "reason": "matched"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| strategyId | string | ✓ | Strategy ID |
| priority | number | ✓ | 優先度 |
| adopted | boolean | ✓ | 採用/不採用 |
| reason | string | ✓ | 理由（"matched", "not matched", "disabled"等） |

**使用例**:
```mql5
// 採用時
m_logger->LogStrategyEval("S1", true, "matched");

// 不採用時
m_logger->LogStrategyEval("S1", false, "not matched");

// 無効時
m_logger->LogStrategyEval("S1", false, "disabled");
```

#### 3.2.3 RULEGROUP_EVAL

**目的**: RuleGroup評価結果を記録

**出力タイミング**: 各RuleGroup評価完了後

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "RULEGROUP_EVAL",
  "strategyId": "S1",
  "ruleGroupId": "RG1",
  "matched": true
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| strategyId | string | ✓ | 所属Strategy ID |
| ruleGroupId | string | ✓ | RuleGroup ID |
| matched | boolean | ✓ | 成立/不成立 |

#### 3.2.4 BLOCK_EVAL

**目的**: ブロック評価結果を記録（最重要イベント）

**出力タイミング**: 各ブロック評価完了後

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "BLOCK_EVAL",
  "blockId": "filter.spreadMax#1",
  "typeId": "filter.spreadMax",
  "status": "PASS",
  "reason": "Spread=1.5 pips (max=2.0)"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| blockId | string | ✓ | ブロックID（実体） |
| typeId | string | ✓ | ブロックタイプID |
| status | string | ✓ | "PASS" / "FAIL" / "NEUTRAL" |
| reason | string | ✓ | 判定理由（人間可読） |
| direction | string | △ | "LONG" / "SHORT" / "NEUTRAL"（方向性ブロックのみ） |
| score | number | △ | スコア（将来拡張用） |
| lotValue | number | △ | ロット値（lot系ブロックのみ） |
| slPips | number | △ | SLのpips（risk系ブロックのみ） |
| tpPips | number | △ | TPのpips（risk系ブロックのみ） |

**使用例**:
```mql5
// filter系ブロック
BlockResult result(PASS, NEUTRAL, "Spread=1.5 pips (max=2.0)");
m_logger->LogBlockEval("filter.spreadMax#1", result);
// 出力: {"blockId":"filter.spreadMax#1","status":"PASS","reason":"Spread=1.5 pips (max=2.0)"}

// trend系ブロック（方向あり）
BlockResult result(PASS, LONG, "Close[1]=1.2345 vs MA[1]=1.2340 (closeAbove)");
m_logger->LogBlockEval("trend.maRelation#1", result);
// 出力: {"blockId":"trend.maRelation#1","status":"PASS","direction":"LONG","reason":"..."}

// lot系ブロック（拡張フィールド）
BlockResult result(PASS, NEUTRAL, "Fixed lot: 0.10");
result.lotValue = 0.1;
m_logger->LogBlockEval("lot.fixed#1", result);
// 出力: {"blockId":"lot.fixed#1","status":"PASS","lotValue":0.1,"reason":"Fixed lot: 0.10"}
```

**検証方法**:
```python
# 検証スクリプト例：AND短絡評価の確認
rg_events = [e for e in events if e["event"] == "RULEGROUP_EVAL" and e["ruleGroupId"] == "RG1"]
block_events = [e for e in events if e["event"] == "BLOCK_EVAL" and e["ts"] == rg_events[0]["ts"]]

# 最初のFAILで打ち切られているか確認
for i, be in enumerate(block_events):
    if be["status"] == "FAIL":
        # この後にブロック評価がないことを確認
        assert i == len(block_events) - 1, "AND short-circuit not working"
        break
```

---

### 3.3 発注系イベント

#### 3.3.1 ORDER_ATTEMPT

**目的**: 発注試行を記録

**出力タイミング**: OrderExecutor::Execute()呼出時

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "ORDER_ATTEMPT",
  "symbol": "USDJPY",
  "direction": "LONG",
  "lot": 0.1,
  "slPips": 30,
  "tpPips": 30,
  "barTimeM1": "2026-01-22 10:01:00"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| symbol | string | ✓ | シンボル名 |
| direction | string | ✓ | "LONG" / "SHORT" |
| lot | number | ✓ | ロット数 |
| slPips | number | △ | SLのpips（pips指定時） |
| tpPips | number | △ | TPのpips（pips指定時） |
| slPrice | number | △ | SL価格（絶対値指定時） |
| tpPrice | number | △ | TP価格（絶対値指定時） |
| barTimeM1 | string | ✓ | 評価対象のバー時刻 |

#### 3.3.2 ORDER_RESULT

**目的**: 発注結果を記録

**出力タイミング**: OrderSend()完了後

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "ORDER_RESULT",
  "success": true,
  "ticket": 12345,
  "retcode": 10009,
  "comment": ""
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| success | boolean | ✓ | 成功/失敗 |
| ticket | number | △ | チケット番号（成功時のみ） |
| retcode | number | ✓ | リターンコード（TRADE_RETCODE_*） |
| comment | string | △ | ブローカーコメント |
| reason | string | △ | 失敗理由（失敗時のみ） |

**使用例**:
```mql5
// 成功時
m_logger->LogOrderResult(true, 12345, "");

// 失敗時
string reason = "RetCode: 10013, Comment: Invalid stops";
m_logger->LogOrderResult(false, 0, reason);
```

#### 3.3.3 ORDER_REJECT

**目的**: 発注拒否理由を記録

**出力タイミング**: 発注前の検証失敗時

**レベル**: WARN

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "ORDER_REJECT",
  "level": "WARN",
  "rejectType": "SAME_BAR_REENTRY",
  "reason": "Same bar re-entry is prohibited"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| rejectType | string | ✓ | 拒否理由種別 |
| reason | string | ✓ | 拒否理由詳細 |

**rejectType一覧**:

| rejectType | 意味 | 出力タイミング |
|------------|------|---------------|
| SAME_BAR_REENTRY | 同一足再エントリー | OrderExecutor::Execute()内、lastEntryBarTimeチェック |
| INVALID_LOT | ロット検証失敗 | ValidateLot()失敗時 |
| INVALID_SL | SL検証失敗 | ValidateSLTP()失敗時 |
| INVALID_TP | TP検証失敗 | ValidateSLTP()失敗時 |
| SPREAD_TOO_WIDE | スプレッド超過 | フィルタブロックでFAIL時 |
| OUTSIDE_SESSION | セッション外 | フィルタブロックでFAIL時 |

**検証方法**:
```python
# 検証スクリプト例：同一足再エントリー禁止の確認
order_rejects = [e for e in events if e["event"] == "ORDER_REJECT" and e["rejectType"] == "SAME_BAR_REENTRY"]
order_results = [e for e in events if e["event"] == "ORDER_RESULT" and e["success"] == True]

# 同一barTimeM1でORDER_RESULTが複数出ないことを確認
bar_times = {}
for e in order_results:
    bar_time = find_bar_time(e["ts"], events)  # BAR_EVAL_STARTから取得
    if bar_time in bar_times:
        assert False, f"Multiple ORDER_RESULT in same bar: {bar_time}"
    bar_times[bar_time] = e
```

---

### 3.4 ガード系イベント

#### 3.4.1 LIMIT_EXCEEDED

**目的**: ポジション制限超過を記録

**出力タイミング**: ポジション制限チェック時

**レベル**: WARN

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "LIMIT_EXCEEDED",
  "level": "WARN",
  "limitType": "maxPositionsTotal",
  "current": 2,
  "max": 1
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| limitType | string | ✓ | 制限種別 |
| current | number | ✓ | 現在値 |
| max | number | ✓ | 最大値 |

**limitType一覧**:
- `maxPositionsTotal`: 全体ポジション数制限
- `maxPositionsPerSymbol`: シンボル別ポジション数制限
- `maxLot`: 最大ロット制限

#### 3.4.2 GUARD_TRIGGERED

**目的**: その他ガード作動を記録

**出力タイミング**: ガード作動時

**レベル**: WARN

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "GUARD_TRIGGERED",
  "level": "WARN",
  "guardType": "spreadMax",
  "reason": "Spread=3.0 pips (max=2.0)"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| guardType | string | ✓ | ガード種別 |
| reason | string | ✓ | ガード作動理由 |

---

### 3.5 管理系イベント

#### 3.5.1 MANAGEMENT_ACTION

**目的**: ポジション管理アクションを記録

**出力タイミング**: トレール、建値移動等のアクション実行時

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:05:00",
  "event": "MANAGEMENT_ACTION",
  "actionType": "trailing",
  "ticket": 12345,
  "detail": "SL moved from 150.00 to 150.50"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| actionType | string | ✓ | アクション種別 |
| ticket | number | ✓ | チケット番号 |
| detail | string | ✓ | アクション詳細 |

**actionType一覧**:
- `trailing`: トレーリングストップ
- `breakeven`: 建値移動
- `avgProfit`: 平均利益決済
- `weekend`: 週末決済
- `partialClose`: 部分決済

#### 3.5.2 POSITION_CLOSE

**目的**: ポジション決済を記録

**出力タイミング**: ポジション決済時

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:30:00",
  "event": "POSITION_CLOSE",
  "ticket": 12345,
  "closeReason": "TP",
  "profit": 300.0
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| ticket | number | ✓ | チケット番号 |
| closeReason | string | ✓ | 決済理由 |
| profit | number | ✓ | 利益（円/ドル等） |

**closeReason一覧**:
- `TP`: TP到達
- `SL`: SL到達
- `MANUAL`: 手動決済
- `WEEKEND`: 週末決済
- `AVG_PROFIT`: 平均利益決済

---

### 3.6 ナンピン系イベント（Phase 4）

#### 3.6.1 NANPIN_ACTION

**目的**: ナンピンアクションを記録

**出力タイミング**: ナンピン追加エントリー、シリーズ損切り等

**レベル**: INFO

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:10:00",
  "event": "NANPIN_ACTION",
  "actionType": "add",
  "ticket": 12346,
  "count": 2,
  "avgPrice": 150.25,
  "detail": "Added 2nd position at 150.10"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| actionType | string | ✓ | アクション種別 |
| ticket | number | ✓ | チケット番号 |
| count | number | ✓ | 現在のナンピン段数 |
| avgPrice | number | △ | 平均建値 |
| detail | string | ✓ | アクション詳細 |

**actionType一覧**:
- `add`: 追加エントリー
- `avgBEClose`: 平均建値決済
- `seriesCut`: シリーズ損切り

---

### 3.7 エラー系イベント

#### 3.7.1 INDICATOR_ERROR

**目的**: インジケータエラーを記録

**出力タイミング**: ハンドル生成失敗、CopyBuffer失敗時

**レベル**: ERROR

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "INDICATOR_ERROR",
  "level": "ERROR",
  "indicatorType": "iMA",
  "reason": "Handle creation failed"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| indicatorType | string | ✓ | インジケータ種別 |
| reason | string | ✓ | エラー理由 |

#### 3.7.2 CONFIG_ERROR

**目的**: 設定エラーを記録

**出力タイミング**: 設定読込失敗、検証失敗時

**レベル**: ERROR

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:00:00",
  "event": "CONFIG_ERROR",
  "level": "ERROR",
  "errorType": "unsupported_version",
  "reason": "Unsupported formatVersion: 2.0"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| errorType | string | ✓ | エラー種別 |
| reason | string | ✓ | エラー理由 |

**errorType一覧**:
- `file_not_found`: ファイルが見つからない
- `json_parse_failed`: JSON解析失敗
- `unsupported_version`: formatVersion非互換
- `schema_validation_failed`: スキーマ検証失敗
- `block_ref_missing`: ブロック参照切れ

#### 3.7.3 RUNTIME_ERROR

**目的**: 実行時エラーを記録

**出力タイミング**: 実行時の予期しないエラー発生時

**レベル**: ERROR

**必須フィールド**:
```json
{
  "ts": "2026-01-22 10:01:00",
  "event": "RUNTIME_ERROR",
  "level": "ERROR",
  "errorType": "unexpected_exception",
  "reason": "Null pointer dereference in Block evaluation"
}
```

---

## 4. ログ出力実装ガイドライン

### 4.1 Logger実装のインターフェース

```mql5
class Logger {
public:
    // 初期化系
    void LogConfigLoaded(bool success, string version, int strategyCount, int blockCount);
    void LogInitSuccess(string message);
    void LogInitFailed(string reason);

    // 評価系
    void LogBarEvalStart(datetime barTime);
    void LogStrategyEval(string strategyId, int priority, bool adopted, string reason);
    void LogRuleGroupEval(string strategyId, string ruleGroupId, bool matched);
    void LogBlockEval(string blockId, const BlockResult &result);

    // 発注系
    void LogOrderAttempt(const OrderRequest &request);
    void LogOrderResult(bool success, ulong ticket, string reason);
    void LogOrderReject(string rejectType, string reason);

    // ガード系
    void LogLimitExceeded(string limitType, int current, int max);
    void LogGuardTriggered(string guardType, string reason);

    // 管理系
    void LogManagementAction(string actionType, ulong ticket, string detail);
    void LogPositionClose(ulong ticket, string closeReason, double profit);

    // ナンピン系
    void LogNanpinAction(string actionType, ulong ticket, int count, string detail);

    // エラー系
    void LogIndicatorError(string indicatorType, string reason);
    void LogConfigError(string errorType, string reason);
    void LogRuntimeError(string errorType, string reason);

    // 汎用
    void LogInfo(string event, string message);
    void LogWarn(string event, string message);
    void LogError(string event, string message);
};
```

### 4.2 JSONL形式の出力規約

**基本ルール**:
- 1行1イベント
- 有効なJSON形式
- 改行コード: LF（\n）
- 文字エンコーディング: UTF-8

**文字列エスケープ**:
```mql5
string Logger::EscapeJSON(string str) {
    StringReplace(str, "\\", "\\\\");  // バックスラッシュ
    StringReplace(str, "\"", "\\\"");  // ダブルクォート
    StringReplace(str, "\n", "\\n");   // 改行
    StringReplace(str, "\r", "\\r");   // キャリッジリターン
    StringReplace(str, "\t", "\\t");   // タブ
    return str;
}
```

**タイムスタンプ形式**:
- ISO8601形式: `YYYY-MM-DD HH:MM:SS`
- タイムゾーン: MT5サーバー時刻（ブローカー依存）
- 例: `"2026-01-22 10:01:00"`

### 4.3 ログローテーション

**日次ローテーション**:
```mql5
// ログファイルパス生成
MqlDateTime dt;
TimeToStruct(TimeCurrent(), dt);
string date = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);
m_logPath = "strategy/logs/strategy_" + date + ".jsonl";
```

**古いログの削除**:
- 手動削除（運用担当者が実施）
- 推奨保存期間: 30日間
- 重要ログ（バックテスト結果等）は別途バックアップ

---

## 5. 検証スクリプトでの使用方法

### 5.1 ログの読み込み

**Python例**:
```python
import json
from datetime import datetime

def load_jsonl(filepath):
    events = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                event = json.loads(line)
                events.append(event)
            except json.JSONDecodeError as e:
                print(f"Invalid JSON: {line}")
    return events

# 使用例
events = load_jsonl("strategy_20260122.jsonl")
print(f"Total events: {len(events)}")
```

### 5.2 必須テストの検証

#### 5.2.1 新バーのみエントリー評価

```python
def test_bar_eval_interval(events):
    """BAR_EVAL_STARTが1分間隔であることを確認"""
    bar_starts = [e for e in events if e["event"] == "BAR_EVAL_START"]

    for i in range(len(bar_starts) - 1):
        t1 = datetime.strptime(bar_starts[i]["barTimeM1"], "%Y-%m-%d %H:%M:%S")
        t2 = datetime.strptime(bar_starts[i+1]["barTimeM1"], "%Y-%m-%d %H:%M:%S")
        delta = (t2 - t1).total_seconds()

        assert delta == 60, f"BAR_EVAL_START interval is not 1 minute: {delta}s"

    print("✓ BAR_EVAL_START at 1-min interval")
```

#### 5.2.2 同一足再エントリー禁止

```python
def test_no_reentry_same_bar(events):
    """同一barTimeM1でORDER_RESULTが複数出ないことを確認"""
    bar_starts = {e["barTimeM1"]: e for e in events if e["event"] == "BAR_EVAL_START"}
    order_results = [e for e in events if e["event"] == "ORDER_RESULT" and e["success"]]

    # 各ORDER_RESULTのbarTimeM1を特定
    bar_time_map = {}
    for order in order_results:
        # 直近のBAR_EVAL_STARTを検索
        bar_time = find_bar_time(order["ts"], events)
        if bar_time in bar_time_map:
            assert False, f"Multiple ORDER_RESULT in same bar: {bar_time}"
        bar_time_map[bar_time] = order

    print("✓ No re-entry in same bar")

def find_bar_time(ts, events):
    """tsより前の直近BAR_EVAL_STARTのbarTimeM1を返す"""
    bar_starts = [e for e in events if e["event"] == "BAR_EVAL_START" and e["ts"] <= ts]
    if not bar_starts:
        return None
    return bar_starts[-1]["barTimeM1"]
```

#### 5.2.3 OR/AND短絡評価

```python
def test_and_short_circuit(events):
    """BLOCK_EVALがFAIL時に後続評価が打ち切られることを確認"""
    rulegroup_evals = [e for e in events if e["event"] == "RULEGROUP_EVAL"]

    for rg_eval in rulegroup_evals:
        if rg_eval["matched"]:
            continue  # 成立時はチェック不要

        # この RuleGroup の BLOCK_EVAL を取得
        rg_id = rg_eval["ruleGroupId"]
        ts_start = rg_eval["ts"]
        # 同一tsのBLOCK_EVALを取得（実際は前後のイベントから特定）
        block_evals = [e for e in events if e["event"] == "BLOCK_EVAL" and e["ts"] == ts_start]

        # 最初のFAIL後に評価がないことを確認
        for i, be in enumerate(block_evals):
            if be["status"] == "FAIL":
                # この後にブロック評価がないことを確認
                assert i == len(block_evals) - 1, f"AND short-circuit failed in {rg_id}"
                break

    print("✓ AND short-circuit working")
```

### 5.3 統計分析

```python
def analyze_logs(events):
    """ログの統計分析"""
    # イベント種別ごとのカウント
    event_counts = {}
    for e in events:
        event_type = e["event"]
        event_counts[event_type] = event_counts.get(event_type, 0) + 1

    print("Event counts:")
    for event_type, count in sorted(event_counts.items()):
        print(f"  {event_type}: {count}")

    # BLOCK_EVALのPASS/FAIL比率
    block_evals = [e for e in events if e["event"] == "BLOCK_EVAL"]
    pass_count = sum(1 for e in block_evals if e["status"] == "PASS")
    fail_count = sum(1 for e in block_evals if e["status"] == "FAIL")
    print(f"\nBLOCK_EVAL: PASS={pass_count}, FAIL={fail_count}")

    # ORDER_RESULTの成功率
    order_results = [e for e in events if e["event"] == "ORDER_RESULT"]
    success_count = sum(1 for e in order_results if e["success"])
    print(f"\nORDER_RESULT: Success={success_count}/{len(order_results)}")
```

---

## 6. トラブルシュート

### 6.1 ログが出力されない

**原因**:
- ファイルオープン失敗
- 権限不足
- ディスクフル

**確認方法**:
```mql5
int handle = FileOpen(m_logPath, FILE_WRITE|FILE_READ|FILE_TXT);
if (handle == INVALID_HANDLE) {
    Print("ERROR: Cannot open log file: ", m_logPath);
    Print("GetLastError(): ", GetLastError());
}
```

**対応**:
- `MQL5/Files/strategy/logs/` ディレクトリが存在するか確認
- MT5の「ファイルサンドボックス」設定を確認
- ディスク容量を確認

### 6.2 JSONL形式が不正

**原因**:
- 文字列エスケープ漏れ
- JSON構文エラー

**確認方法**:
```bash
# 各行がJSONとして有効か確認
while IFS= read -r line; do
  echo "$line" | jq . > /dev/null || echo "Invalid JSON: $line"
done < strategy_20260122.jsonl
```

**対応**:
- EscapeJSON()関数を使用
- reason文字列に特殊文字が含まれていないか確認

### 6.3 タイムスタンプがずれる

**原因**:
- MT5サーバー時刻とローカル時刻の違い
- ブローカーによるタイムゾーン設定

**対応**:
- MT5サーバー時刻を基準にする（TimeCurrent()）
- バックテストとフォワードで同じ時刻基準を使用

---

## 7. 参照ドキュメント

本ログイベント仕様書は以下のドキュメントを基に作成されています：

- `docs/03_design/45_interface_contracts.md` - Logger インターフェース
- `docs/03_design/50_ea_runtime_design.md` - ログ出力実装
- `docs/04_operations/90_observability_and_testing.md` - ログ設計・検証
- `docs/02_requirements/12_acceptance_criteria.md` - 受入基準

---

## 8. 変更履歴

| 版 | 日付 | 変更内容 |
|----|------|---------|
| v1.0 | 2026-01-22 | 初版作成、全イベント種別の完全定義 |

---
