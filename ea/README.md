# Strategy Bricks EA Runtime MVP

JSON設定駆動型MT5エキスパートアドバイザーのMVP実装です。

## ファイル構成

```
ea/
├── src/
│   └── StrategyBricks.mq5          # メインEA
│
├── include/
│   ├── Common/
│   │   ├── Constants.mqh            # 定数定義
│   │   ├── Enums.mqh                # 列挙型
│   │   └── Structures.mqh           # 共通構造体
│   │
│   ├── Config/
│   │   ├── ConfigLoader.mqh         # JSON設定読み込み
│   │   └── ConfigValidator.mqh      # 設定検証
│   │
│   ├── Core/
│   │   ├── NewBarDetector.mqh       # M1新バー検知
│   │   ├── StrategyEngine.mqh       # 戦略評価エンジン
│   │   ├── CompositeEvaluator.mqh   # OR/AND短絡評価
│   │   └── BlockRegistry.mqh        # ブロック登録Factory
│   │
│   ├── Blocks/
│   │   ├── IBlock.mqh               # インターフェース
│   │   ├── Filter/FilterSpreadMax.mqh
│   │   ├── Env/EnvSessionTimeWindow.mqh
│   │   ├── Trend/TrendMARelation.mqh
│   │   ├── Trigger/TriggerBBReentry.mqh
│   │   ├── Lot/LotFixed.mqh
│   │   ├── Risk/RiskFixedSLTP.mqh
│   │   ├── Exit/ExitNone.mqh
│   │   └── Nanpin/NanpinOff.mqh
│   │
│   ├── Indicators/
│   │   └── IndicatorCache.mqh       # ハンドル共有・値キャッシュ
│   │
│   ├── Execution/
│   │   ├── OrderExecutor.mqh        # 発注処理
│   │   └── PositionManager.mqh      # ポジション管理
│   │
│   └── Support/
│       ├── StateStore.mqh           # 状態管理
│       ├── Logger.mqh               # JSONLログ出力
│       └── JsonParser.mqh           # JSON解析
│
└── tests/
    ├── active.json                  # テスト用設定
    └── README.md
```

## MVPブロック

| ブロック | typeId | 説明 |
|---------|--------|------|
| スプレッドフィルタ | filter.spreadMax | スプレッド上限チェック |
| セッションフィルタ | env.session.timeWindow | 時間帯・曜日チェック |
| MAトレンド | trend.maRelation | 終値とMAの上下関係 |
| BB回帰トリガー | trigger.bbReentry | BB外→内の回帰検出 |
| 固定ロット | lot.fixed | 固定ロット値 |
| 固定SL/TP | risk.fixedSLTP | 固定pipsのSL/TP |
| 出口なし | exit.none | SL/TPのみで決済 |
| ナンピン無効 | nanpin.off | ナンピン無効 |

## 設計の特徴

### 強い制約（絶対条件）

- **M1固定**: 1分足のみ
- **確定足基準**: shift=1のデータを使用
- **同一足再エントリー禁止**: 二重ガードで保護
  1. 新バー時のみ評価（第一ガード）
  2. lastEntryBarTimeチェック（第二ガード）
- **DNF形式**: 枠がOR、ルール内がAND

### アーキテクチャ

- **ブロック**: 副作用なし、判定・計算のみ
- **Executor/Manager**: 副作用を集約
- **IndicatorCache**: ハンドル共有、計算重複抑制
- **StateStore**: 状態の一元管理・永続化

## MT5への配置

```
MQL5/
├── Experts/
│   └── StrategyBricks.mq5      # ea/src/StrategyBricks.mq5
├── Include/
│   └── StrategyBricks/         # ea/include/* をコピー
└── Files/
    └── strategy/
        ├── active.json          # 設定ファイル
        └── logs/                # ログ出力先（自動作成）
```

## コンパイル

1. MetaEditorで `StrategyBricks.mq5` を開く
2. F7でコンパイル
3. エラーがないことを確認

## 入力パラメータ

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| InpConfigPath | strategy/active.json | 設定ファイルパス |
| InpEnableLogging | true | ログ出力有効 |

## ログ出力

JSONL形式で以下のイベントを記録：

- `CONFIG_LOADED` - 設定読込結果
- `BAR_EVAL_START` - 新バー評価開始
- `STRATEGY_EVAL` - Strategy評価結果
- `RULEGROUP_EVAL` - RuleGroup評価結果
- `BLOCK_EVAL` - ブロック評価結果
- `ORDER_ATTEMPT` - 発注試行
- `ORDER_RESULT` - 発注結果
- `ORDER_REJECT` - 発注拒否

## 参照ドキュメント

- `docs/03_design/45_interface_contracts.md` - インターフェース契約
- `docs/03_design/50_ea_runtime_design.md` - EA詳細設計
- `docs/03_design/30_config_spec.md` - strategy_config.jsonスキーマ
- `docs/05_development_plan/15_mvp_checklist.md` - MVPチェックリスト

---

**最終更新**: 2026-01-22（MVP実装完了）
