# 04_operations/80_testing.md
# テスト計画 — Strategy Bricks（仮称）

## 0. ドキュメント情報
- ファイル名：`docs/04_operations/80_testing.md`
- 版：v0.1
- 対象：テスト担当、品質保証担当
- 目的：具体的なテスト手法と項目を定義

---

## 1. テスト戦略

### 1.1 テストレベル

**単体テスト（Unit Testing）:**
- 対象：個別のクラス・関数
- 目的：各コンポーネントが仕様通り動作することを確認
- 手法：独立したテストケース、モック使用

**統合テスト（Integration Testing）:**
- 対象：複数コンポーネントの連携
- 目的：コンポーネント間のインターフェースが正しく動作することを確認
- 手法：実際のデータフロー、ログベース検証

**E2Eテスト（End-to-End Testing）:**
- 対象：GUI → JSON → EA → Market
- 目的：システム全体が一貫して動作することを確認
- 手法：バックテスト、ログ確認

**回帰テスト（Regression Testing）:**
- 対象：変更後の既存機能
- 目的：変更が既存機能に影響しないことを確認
- 手法：自動化テストスイート、ログ比較

### 1.2 テスト方針

**ログベース検証を中心とする:**
- すべてのログイベントが記録されることを前提
- ログから挙動を追跡可能にする
- バックテストで再現性を確保

**受入基準に基づくテストケース:**
- `docs/02_requirements/12_acceptance_criteria.md` の各ACをテストケース化
- 成功基準・失敗例を明確化

**自動化可能な部分は自動化:**
- ログ解析スクリプト（Python等）
- バックテスト結果の比較スクリプト

---

## 2. 単体テスト

### 2.1 ConfigValidator（設定検証）

**目的:** 設定ファイルの検証ロジックが正しく動作することを確認

**テストケース:**

#### TC-CV-01: formatVersion互換性チェック

**前提条件:**
- Config構造体準備

**テストデータ:**
- formatVersion = "1.0" → 合格
- formatVersion = "2.0" → 不合格
- formatVersion = "" → 不合格

**実行:**
```mql5
bool result1 = ValidateFormatVersion(config1); // "1.0"
bool result2 = ValidateFormatVersion(config2); // "2.0"
bool result3 = ValidateFormatVersion(config3); // ""
```

**期待結果:**
- result1 == true
- result2 == false（ログにエラー出力）
- result3 == false（ログにエラー出力）

#### TC-CV-02: 必須フィールドチェック

**テストデータ:**
- globalGuards.timeframe = "M1" → 合格
- globalGuards.timeframe = "" → 不合格
- globalGuards.timeframe = "M5" → 不合格

**期待結果:**
- "M1"のみ合格
- その他は不合格でログ出力

#### TC-CV-03: ブロック参照チェック

**テストデータ:**
- blockId = "filter.spreadMax#1"（存在する）→ 合格
- blockId = "nonexistent#1"（存在しない）→ 不合格

**期待結果:**
- 存在しないblockIdで不合格
- ログに"Block reference not found: nonexistent#1"

---

### 2.2 CompositeEvaluator（複合評価器）

**目的:** OR/AND短絡評価が正しく動作することを確認

**テストケース:**

#### TC-CE-01: OR短絡評価（最初に成立）

**前提条件:**
- 3つのRuleGroupを準備
- RuleGroup#1: 成立（全条件PASS）
- RuleGroup#2: 成立（全条件PASS）
- RuleGroup#3: 不成立（一部FAIL）

**実行:**
```mql5
bool result = evaluator.EvaluateOR(entryRequirement);
```

**期待結果:**
- result == true
- RuleGroup#1のみ評価される
- RuleGroup#2, #3は評価されない（ログなし）

#### TC-CE-02: OR短絡評価（2番目に成立）

**前提条件:**
- RuleGroup#1: 不成立
- RuleGroup#2: 成立
- RuleGroup#3: 成立

**期待結果:**
- result == true
- RuleGroup#1, #2が評価される
- RuleGroup#3は評価されない

#### TC-CE-03: AND短絡評価（最初にFAIL）

**前提条件:**
- 4つのConditionを準備
- Condition#1: FAIL
- Condition#2, #3, #4: PASS

**実行:**
```mql5
bool result = evaluator.EvaluateAND(ruleGroup);
```

**期待結果:**
- result == false
- Condition#1のみ評価される
- Condition#2, #3, #4は評価されない

#### TC-CE-04: AND短絡評価（全てPASS）

**前提条件:**
- 全てのConditionがPASS

**期待結果:**
- result == true
- 全Conditionが評価される

---

### 2.3 ブロック単体テスト

**目的:** 各ブロックが正しく判定を行うことを確認

**テストケース:**

#### TC-BL-01: filter.spreadMax

**テストデータ:**
- maxSpreadPips = 2.0
- 現在スプレッド = 1.5 pips → PASS
- 現在スプレッド = 3.0 pips → FAIL

**実行:**
```mql5
Context ctx1 = CreateContext(1.5);
BlockResult result1 = block.Evaluate(ctx1);

Context ctx2 = CreateContext(3.0);
BlockResult result2 = block.Evaluate(ctx2);
```

**期待結果:**
- result1.status == PASS
- result2.status == FAIL
- result2.reason == "Spread=3.0 pips (max=2.0)"

#### TC-BL-02: trend.maRelation

**テストデータ:**
- period = 200, maType = "EMA", relation = "closeAbove"
- Close[1] = 1.10500, MA[1] = 1.10000 → PASS
- Close[1] = 1.09500, MA[1] = 1.10000 → FAIL

**期待結果:**
- Close > MA → PASS
- Close < MA → FAIL
- reason文字列に価格とMA値が含まれる

#### TC-BL-03: trigger.bbReentry

**テストデータ:**
- side = "lowerToInside"
- Close[2] < Lower[2], Close[1] >= Lower[1] → PASS
- Close[2] >= Lower[2] → FAIL

**期待結果:**
- 外→内回帰でPASS
- それ以外でFAIL

---

### 2.4 IndicatorCache

**目的:** インジケータのハンドル共有と値キャッシュが正しく動作することを確認

**テストケース:**

#### TC-IC-01: ハンドル共有

**実行:**
```mql5
int handle1 = cache.GetMAHandle(Symbol(), 200, 0, MODE_EMA);
int handle2 = cache.GetMAHandle(Symbol(), 200, 0, MODE_EMA);
```

**期待結果:**
- handle1 == handle2（同一ハンドル）
- iMA()は1回のみ呼ばれる

#### TC-IC-02: 値キャッシュ

**実行:**
```mql5
datetime barTime = iTime(Symbol(), PERIOD_M1, 1);
double value1 = cache.GetMAValue(handle, 1, barTime);
double value2 = cache.GetMAValue(handle, 1, barTime);
```

**期待結果:**
- value1 == value2
- CopyBuffer()は1回のみ呼ばれる（同一barTime）

#### TC-IC-03: キャッシュクリア

**実行:**
```mql5
cache.ClearValueCache();
double value3 = cache.GetMAValue(handle, 1, barTime);
```

**期待結果:**
- CopyBuffer()が再度呼ばれる

---

## 3. 統合テスト

### 3.1 新バー検知

**目的:** M1新バー検知が正しく動作することを確認

**テストケース:**

#### TC-IT-01: 新バー検知の動作

**実行:**
1. バックテストを1時間実行
2. ログファイルでBAR_EVAL_STARTイベントを抽出

**検証スクリプト（Python）:**
```python
import json
from datetime import datetime, timedelta

# ログファイル読込
with open('strategy_20240110.jsonl', 'r') as f:
    logs = [json.loads(line) for line in f]

# BAR_EVAL_STARTイベント抽出
bar_events = [log for log in logs if log['event'] == 'BAR_EVAL_START']

# 件数チェック
assert len(bar_events) == 60, f"Expected 60, got {len(bar_events)}"

# barTimeM1が1分刻みかチェック
prev_time = None
for event in bar_events:
    current_time = datetime.fromisoformat(event['barTimeM1'])
    if prev_time:
        delta = (current_time - prev_time).total_seconds()
        assert delta == 60, f"Expected 60s, got {delta}s"
    prev_time = current_time

print("TC-IT-01: PASS")
```

**期待結果:**
- BAR_EVAL_START == 60回
- 各barTimeM1が1分間隔

---

### 3.2 同一足再エントリー禁止

**テストケース:**

#### TC-IT-02: 同一足再エントリー禁止の動作

**実行:**
1. 複数RuleGroupを持つ戦略でバックテスト
2. ログファイルでORDER_RESULTとORDER_REJECTを抽出

**検証スクリプト（Python）:**
```python
# ORDER_RESULT/REJECT抽出
order_events = [log for log in logs if log['event'] in ['ORDER_RESULT', 'ORDER_REJECT']]

# barTimeM1ごとにグループ化
from collections import defaultdict
by_bar = defaultdict(list)
for event in order_events:
    bar_time = event.get('barTimeM1', '')
    by_bar[bar_time].append(event)

# 各barで最大1回のORDER_RESULTをチェック
for bar_time, events in by_bar.items():
    results = [e for e in events if e['event'] == 'ORDER_RESULT']
    assert len(results) <= 1, f"Multiple ORDER_RESULT for bar {bar_time}"

    # 2回目以降はREJECT
    if len(events) > 1:
        for e in events[1:]:
            assert e['event'] == 'ORDER_REJECT'
            assert e['rejectType'] == 'SAME_BAR_REENTRY'

print("TC-IT-02: PASS")
```

**期待結果:**
- 各barTimeM1でORDER_RESULTは最大1回
- 2回目以降はORDER_REJECT

---

### 3.3 OR/AND評価

**テストケース:**

#### TC-IT-03: OR短絡評価（統合）

**実行:**
1. 3つのRuleGroupを持つ戦略でバックテスト
2. RuleGroup#1が成立するケースのログ確認

**検証スクリプト（Python）:**
```python
# 特定barTimeのイベント抽出
target_bar = '2024-01-10 10:00:00'
bar_events = [log for log in logs if log.get('barTimeM1') == target_bar]

# RULEGROUP_EVALイベント確認
rg_evals = [e for e in bar_events if e['event'] == 'RULEGROUP_EVAL']

# 最初のRuleGroupが成立していたら、2つ目以降は評価されない
if rg_evals and rg_evals[0].get('matched'):
    assert len(rg_evals) == 1, "OR short-circuit failed"

print("TC-IT-03: PASS")
```

---

### 3.4 ポジション制限

**テストケース:**

#### TC-IT-04: ポジション制限の動作

**実行:**
1. maxPositionsTotal = 2 に設定
2. バックテスト実行
3. 2ポジション保有後のエントリー条件成立時のログ確認

**検証スクリプト（Python）:**
```python
# LIMIT_EXCEEDEDイベント確認
limit_events = [log for log in logs if log['event'] == 'LIMIT_EXCEEDED']

# LIMIT_EXCEEDED後にORDER_ATTEMPTがないことを確認
for limit_event in limit_events:
    limit_time = limit_event['ts']
    limit_bar = limit_event.get('barTimeM1', '')

    # 同一barのORDER_ATTEMPT確認
    order_attempts = [log for log in logs
                     if log['event'] == 'ORDER_ATTEMPT'
                     and log.get('barTimeM1') == limit_bar]

    assert len(order_attempts) == 0, f"ORDER_ATTEMPT after LIMIT_EXCEEDED at {limit_bar}"

print("TC-IT-04: PASS")
```

---

## 4. ストラテジーテスター検証

### 4.1 再現性テスト

**目的:** 同じ設定・同じ期間でバックテストした時、結果が同じになることを確認

**テストケース:**

#### TC-ST-01: 再現性の確認

**実行:**
1. 戦略Aで2024-01-01〜2024-01-31のバックテスト実行（1回目）
2. 結果を記録: Total Trades, Profit, Drawdown
3. 同じ設定で再度バックテスト実行（2回目）
4. 結果を比較

**検証:**
```python
# 1回目の結果
result1 = {
    'total_trades': 150,
    'profit': 1250.50,
    'drawdown': -320.00,
}

# 2回目の結果
result2 = {
    'total_trades': 150,
    'profit': 1250.50,
    'drawdown': -320.00,
}

# 比較
assert result1 == result2, "Reproducibility test failed"

# ログファイルも比較
with open('log1.jsonl', 'r') as f1, open('log2.jsonl', 'r') as f2:
    logs1 = f1.readlines()
    logs2 = f2.readlines()
    assert logs1 == logs2, "Log files differ"

print("TC-ST-01: PASS")
```

**期待結果:**
- Total Trades一致
- Profit一致
- Drawdown一致
- ログファイル内容一致

---

### 4.2 必須テスト項目（バックテスト）

**テストケース:**

#### TC-ST-02: M1新バーのみ評価

**検証:** AC-01に準拠（`12_acceptance_criteria.md`参照）

#### TC-ST-03: 同一足再エントリー禁止

**検証:** AC-02に準拠

#### TC-ST-04: スプレッド超過時の停止

**検証:** AC-05に準拠

#### TC-ST-05: ポジション制限超過時の停止

**検証:** AC-04に準拠

#### TC-ST-06: ナンピン最大段数制限

**検証:** AC-12に準拠

#### TC-ST-07: ナンピンシリーズ損切り

**検証:** AC-13に準拠

---

## 5. ログベース検証

### 5.1 ログ解析スクリプト

**目的:** ログファイルから自動的に検証を行う

**スクリプト例（Python）:**

```python
#!/usr/bin/env python3
import json
import sys
from datetime import datetime
from collections import defaultdict

class LogValidator:
    def __init__(self, log_file):
        with open(log_file, 'r') as f:
            self.logs = [json.loads(line) for line in f]

    def validate_bar_eval_frequency(self, expected_minutes):
        """BAR_EVAL_STARTが期待回数出現するか"""
        bar_events = [log for log in self.logs if log['event'] == 'BAR_EVAL_START']
        actual = len(bar_events)
        assert actual == expected_minutes, f"Expected {expected_minutes} bars, got {actual}"
        print(f"✓ BAR_EVAL_START frequency: {actual}/{expected_minutes}")

    def validate_no_same_bar_reentry(self):
        """同一barTimeM1でORDER_RESULTが複数ないか"""
        by_bar = defaultdict(int)
        for log in self.logs:
            if log['event'] == 'ORDER_RESULT' and log.get('success'):
                bar_time = log.get('barTimeM1', '')
                by_bar[bar_time] += 1

        duplicates = {bar: count for bar, count in by_bar.items() if count > 1}
        assert len(duplicates) == 0, f"Duplicate ORDER_RESULT: {duplicates}"
        print(f"✓ No same-bar re-entry")

    def validate_block_eval_reasons(self):
        """すべてのBLOCK_EVALにreasonがあるか"""
        block_evals = [log for log in self.logs if log['event'] == 'BLOCK_EVAL']
        missing_reasons = [log for log in block_evals if not log.get('reason')]
        assert len(missing_reasons) == 0, f"Missing reasons: {len(missing_reasons)}"
        print(f"✓ All BLOCK_EVAL have reasons ({len(block_evals)} events)")

    def validate_order_reject_reasons(self):
        """すべてのORDER_REJECTにreasonがあるか"""
        order_rejects = [log for log in self.logs if log['event'] == 'ORDER_REJECT']
        missing_reasons = [log for log in order_rejects if not log.get('reason')]
        assert len(missing_reasons) == 0, f"Missing reasons: {len(missing_reasons)}"
        print(f"✓ All ORDER_REJECT have reasons ({len(order_rejects)} events)")

    def validate_limit_exceeded_behavior(self):
        """LIMIT_EXCEEDED後にORDER_ATTEMPTがないか"""
        limit_events = [log for log in self.logs if log['event'] == 'LIMIT_EXCEEDED']
        for limit_event in limit_events:
            limit_bar = limit_event.get('barTimeM1', '')
            order_attempts = [log for log in self.logs
                            if log['event'] == 'ORDER_ATTEMPT'
                            and log.get('barTimeM1') == limit_bar]
            assert len(order_attempts) == 0, f"ORDER_ATTEMPT after LIMIT at {limit_bar}"
        print(f"✓ No ORDER_ATTEMPT after LIMIT_EXCEEDED ({len(limit_events)} limits)")

# 使用例
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <log_file.jsonl>")
        sys.exit(1)

    validator = LogValidator(sys.argv[1])

    # 検証実行
    validator.validate_bar_eval_frequency(60)  # 1時間のテストを想定
    validator.validate_no_same_bar_reentry()
    validator.validate_block_eval_reasons()
    validator.validate_order_reject_reasons()
    validator.validate_limit_exceeded_behavior()

    print("\n✅ All validations passed!")
```

**実行:**
```bash
python validate_logs.py strategy_20240110.jsonl
```

---

## 6. 回帰テスト

### 6.1 回帰テスト戦略

**目的:** 変更が既存機能に影響しないことを確認

**手法:**
1. **ベースライン確立**：MVP完成時のバックテスト結果とログを保存
2. **変更後テスト**：変更後に同じバックテストを実行
3. **結果比較**：差分を確認し、意図しない変更がないか検証

**対象:**
- コアロジック変更（StrategyEngine, CompositeEvaluator等）
- ブロック追加・変更
- 設定スキーマ変更

### 6.2 回帰テスト実施手順

**手順:**

1. **ベースライン保存:**
```bash
# バックテスト実行
# 結果をbaseline/に保存
cp strategy_20240110.jsonl baseline/
cp backtest_results.json baseline/
```

2. **変更実施:**
（コード変更、ブロック追加等）

3. **回帰テスト実行:**
```bash
# 同じ設定・期間でバックテスト実行
# 結果をregression/に保存
cp strategy_20240110.jsonl regression/
cp backtest_results.json regression/
```

4. **結果比較:**
```python
#!/usr/bin/env python3
import json

# バックテスト結果比較
with open('baseline/backtest_results.json', 'r') as f:
    baseline = json.load(f)

with open('regression/backtest_results.json', 'r') as f:
    regression = json.load(f)

# 主要メトリクス比較
metrics = ['total_trades', 'profit', 'drawdown', 'profit_factor']
for metric in metrics:
    if baseline[metric] != regression[metric]:
        print(f"⚠ {metric} changed: {baseline[metric]} → {regression[metric]}")
    else:
        print(f"✓ {metric} unchanged: {baseline[metric]}")

# ログ比較（エントリー時刻等）
# ...
```

5. **差分の確認:**
- 意図した変更か検証
- 意図しない変更があれば原因調査

---

## 7. テストケース一覧（MVP）

### 7.1 単体テスト

| ID | カテゴリ | テスト内容 | 優先度 |
|----|---------|----------|--------|
| TC-CV-01 | ConfigValidator | formatVersionチェック | Critical |
| TC-CV-02 | ConfigValidator | 必須フィールドチェック | Critical |
| TC-CV-03 | ConfigValidator | ブロック参照チェック | Critical |
| TC-CE-01 | CompositeEvaluator | OR短絡評価（最初に成立） | Critical |
| TC-CE-02 | CompositeEvaluator | OR短絡評価（2番目に成立） | High |
| TC-CE-03 | CompositeEvaluator | AND短絡評価（最初にFAIL） | Critical |
| TC-CE-04 | CompositeEvaluator | AND短絡評価（全てPASS） | High |
| TC-BL-01 | Block | filter.spreadMax | Critical |
| TC-BL-02 | Block | trend.maRelation | Critical |
| TC-BL-03 | Block | trigger.bbReentry | High |
| TC-IC-01 | IndicatorCache | ハンドル共有 | High |
| TC-IC-02 | IndicatorCache | 値キャッシュ | High |
| TC-IC-03 | IndicatorCache | キャッシュクリア | Medium |

### 7.2 統合テスト

| ID | カテゴリ | テスト内容 | 優先度 |
|----|---------|----------|--------|
| TC-IT-01 | NewBarDetector | 新バー検知の動作 | Critical |
| TC-IT-02 | OrderExecutor | 同一足再エントリー禁止 | Critical |
| TC-IT-03 | Evaluator | OR短絡評価（統合） | Critical |
| TC-IT-04 | PositionManager | ポジション制限 | Critical |

### 7.3 ストラテジーテスター検証

| ID | テスト内容 | 優先度 |
|----|----------|--------|
| TC-ST-01 | 再現性の確認 | Critical |
| TC-ST-02 | M1新バーのみ評価 | Critical |
| TC-ST-03 | 同一足再エントリー禁止 | Critical |
| TC-ST-04 | スプレッド超過時の停止 | Critical |
| TC-ST-05 | ポジション制限超過時の停止 | Critical |
| TC-ST-06 | ナンピン最大段数制限 | High |
| TC-ST-07 | ナンピンシリーズ損切り | High |

---

## 8. テスト環境

### 8.1 バックテスト環境

**必要なもの:**
- MT5 Strategy Tester
- 履歴データ（M1、少なくとも1ヶ月分）
- StrategyBricks.ex5（EA）
- active.json（設定ファイル）

**推奨設定:**
- モデリング: Every tick（全ティック）
- Spread: 現在値または固定値
- 最適化: なし（再現性テストのため）

### 8.2 ログ解析環境

**必要なもの:**
- Python 3.x
- ログファイル（*.jsonl）
- 検証スクリプト

**セットアップ:**
```bash
# Python環境準備
python3 -m venv venv
source venv/bin/activate
pip install jsonlines

# ログファイル配置
cp ~/AppData/.../MQL5/Files/strategy/logs/*.jsonl ./logs/

# 検証実行
python validate_logs.py logs/strategy_20240110.jsonl
```

---

## 9. テスト自動化

### 9.1 自動化対象

**優先度高（MVP）:**
- ログベース検証（Python）
- 結果比較（バックテスト結果のdiff）

**優先度中（MVP後）:**
- GUI操作テスト（Selenium等）
- 単体テスト自動実行（CI/CD）

### 9.2 CI/CDパイプライン（将来）

```yaml
# .github/workflows/test.yml（例）
name: Test Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Setup Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.x'

    - name: Install dependencies
      run: |
        pip install jsonlines

    - name: Run log validation
      run: |
        python tests/validate_logs.py test_data/strategy_20240110.jsonl

    - name: Run regression tests
      run: |
        python tests/regression_test.py
```

---

## 10. テスト完了基準

### 10.1 MVP完了基準

**単体テスト:**
- [ ] Critical優先度の全テストケースがPASS

**統合テスト:**
- [ ] Critical優先度の全テストケースがPASS

**ストラテジーテスター検証:**
- [ ] TC-ST-01〜TC-ST-05（Critical）がPASS

**ログベース検証:**
- [ ] BAR_EVAL_START頻度確認
- [ ] 同一足再エントリー禁止確認
- [ ] reason文字列確認

**受入基準:**
- [ ] `12_acceptance_criteria.md` のCritical項目がすべてPASS

### 10.2 品質ゲート

**リリース不可条件:**
- Criticalテストケースの失敗
- 再現性テストの失敗
- 必須受入基準（AC-01〜AC-11）の未達

**警告条件:**
- Highテストケースの失敗（要調査）
- ログ欠落
- パフォーマンス劣化

---

## 11. 参照ドキュメント

本テスト計画は以下のドキュメントを基に作成されています:

- `docs/02_requirements/12_acceptance_criteria.md` - 受入基準
- `docs/03_design/50_ea_runtime_design.md` - EA Runtime詳細設計
- `docs/03_design/60_gui_builder_design.md` - GUI Builder詳細設計
- `docs/04_operations/90_observability_and_testing.md` - 観測性とテスト

---
