# 検証・運用スクリプト

ログ検証、バックテスト分析、運用タスク自動化などのスクリプトを格納します。

## ディレクトリ構造

```
scripts/
├── validation/         # ログ検証スクリプト
│   ├── validate_logs.py            # メイン検証スクリプト
│   ├── test_ac01_bar_eval.py       # AC-01検証
│   ├── test_ac02_no_reentry.py     # AC-02検証
│   └── test_ac03_short_circuit.py  # AC-03検証
├── analysis/           # バックテスト分析（将来）
└── utils/              # ユーティリティ（将来）
```

## 実装状況

**現在の状態**: 未実装（Phase 3で作成予定）

**次のステップ**:
1. validate_logs.pyの作成（Phase 3開始時）
2. 受入基準AC-01〜AC-11の検証スクリプト作成

## 検証スクリプト仕様

### validate_logs.py

**用途**: EAが出力したJSONLログを解析し、受入基準を自動検証

**実行方法**（将来）:
```bash
python scripts/validation/validate_logs.py \
  --log-file MQL5/Files/strategy/logs/strategy_20260122.jsonl \
  --test AC-01,AC-02,AC-03
```

**検証項目**:
- AC-01: エントリー評価タイミング（M1新バーのみ）
- AC-02: 同一足再エントリー禁止
- AC-03: OR/AND短絡評価
- AC-04: ポジション制限超過時の挙動
- AC-05: スプレッド超過時の停止
- AC-10: ブロック判定理由がログに残る
- AC-11: 発注失敗理由がログに残る

### test_ac01_bar_eval.py

**用途**: AC-01（エントリー評価タイミング）の検証

**検証内容**:
1. BAR_EVAL_STARTが1分間隔で出力されているか
2. barTimeM1が連続して1分刻みか
3. 1時間で60回のBAR_EVAL_STARTがあるか

**実装例**:
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

### test_ac02_no_reentry.py

**用途**: AC-02（同一足再エントリー禁止）の検証

**検証内容**:
1. 同一barTimeM1でORDER_RESULTが複数出ないか
2. 2回目以降はORDER_REJECTで"SAME_BAR_REENTRY"か

**実装例**:
```python
def test_no_reentry_same_bar(events):
    """同一barTimeM1でORDER_RESULTが複数出ないことを確認"""
    bar_starts = {e["barTimeM1"]: e for e in events if e["event"] == "BAR_EVAL_START"}
    order_results = [e for e in events if e["event"] == "ORDER_RESULT" and e["success"]]

    bar_time_map = {}
    for order in order_results:
        bar_time = find_bar_time(order["ts"], events)
        if bar_time in bar_time_map:
            assert False, f"Multiple ORDER_RESULT in same bar: {bar_time}"
        bar_time_map[bar_time] = order

    print("✓ No re-entry in same bar")
```

### test_ac03_short_circuit.py

**用途**: AC-03（OR/AND短絡評価）の検証

**検証内容**:
1. BLOCK_EVALがFAIL時に後続評価が打ち切られるか（AND短絡）
2. 最初のRuleGroupが成立時に後続RuleGroupが評価されないか（OR短絡）

## 必要な環境

**Python**:
- Python 3.8以上
- 必要なライブラリ: `jsonlines`, `pandas` (optional)

**インストール**（将来）:
```bash
pip install -r scripts/requirements.txt
```

## 参照ドキュメント

**必読**:
- `docs/04_operations/85_log_event_spec.md` - ログイベント仕様書
- `docs/02_requirements/12_acceptance_criteria.md` - 受入基準

**参照**:
- `docs/04_operations/90_observability_and_testing.md` - 観測性とテスト

---

**最終更新**: 2026-01-22
