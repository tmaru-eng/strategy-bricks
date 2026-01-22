# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Strategy Bricks（仮称）は、MT5（MQL5）EA をJSON設定駆動で動作させるシステムです。Electron GUIでブロック（レゴ）を組み合わせて戦略を構築し、EAが実行します。

**重要な設計方針:**
- 保守性を最優先（疎結合、副作用の集約）
- AIエージェントが分担実装しやすい構造
- すべての判定・計算はブロック化（副作用なし）
- 発注・決済などの副作用はExecutor/Managerに集約

## ドキュメント体系

**必ず最初に読むべきファイル:**
- `docs/00_overview.md` - 合意事項・前提条件・重要要件の要約
- `docs/README.md` - ドキュメント全体の索引

**主要ドキュメント構成:**
```
docs/
  00_overview.md           # 引き継ぎ事項（最優先で確認）
  01_proposal/             # 企画資料（Why/What/Value）
  02_requirements/         # 要件定義（制約・受入条件）
  03_design/               # 設計仕様（契約定義 - 最重要）
    30_config_spec.md      # strategy_config.json スキーマ
    40_block_catalog_spec.md  # block_catalog.json スキーマ
  04_operations/           # 運用・テスト計画
  05_development_plan/     # 開発計画とマイルストーン
```

## 絶対に守るべき要件（強い制約）

以下は要件定義で**絶対条件**として合意済み。これらに違反する実装は許容されません:

1. **対象プラットフォーム**: MT5（MQL5）のみ
2. **動作時間足**: M1（1分足）固定
3. **判定基準**: 基本は確定足（shift=1）、未確定足（shift=0）の使用は原則禁止
4. **エントリー評価**: M1新バー時のみ評価（1分に1回）
5. **同一足再エントリー禁止**: 必須（二重ガード実装）
   - 新バー評価のみ
   - `lastEntryBarTime` による発注拒否
6. **相場判断**: 上位足は原則使わず、M1のみでトレンド/押し目/トリガーを判断
7. **ルール構造**: DNF形式（枠がOR、ルール内がAND）
   - EntryRequirement = OR(ruleGroups)
   - ruleGroup = AND(conditions)
8. **ポジション制限超過時**: 新規エントリー停止、ポジション管理のみ実施
9. **ナンピン（平均建値改善）**: モードとして用意
   - 分割エントリーの発想
   - 必ず損切り（損失限定）を行う
   - ポジション数増加時の平均建値決済も必要

## 設定ファイル仕様（契約）

### strategy_config.json（active.json）

**ファイル運用:**
- EA読込パス: `MQL5/Files/strategy/active.json`（既定）
- Builder出力: `profiles/<name>.json`（保存用）+ `active.json`（実行用）

**重要フィールド:**
- `meta.formatVersion`: 必須。非対応バージョンは起動後に取引処理を停止
- `globalGuards`: EA全体のガード設定
  - `timeframe`: "M1" 固定
  - `useClosedBarOnly`: true 固定
  - `noReentrySameBar`: true 固定
  - `maxPositionsTotal` / `maxPositionsPerSymbol`
  - `maxSpreadPips`
  - `session`: 時間帯・曜日制御
- `strategies[]`: Strategy配列（priority順）
  - `priority`: 数値（大きいほど優先）
  - `conflictPolicy`: MVPは "firstOnly" 既定
  - `directionPolicy`: "longOnly" | "shortOnly" | "both"
  - `entryRequirement`: OR/AND構造
  - `lotModel`, `riskModel`, `exitModel`, `nanpinModel`
- `blocks[]`: ブロック実体定義（typeIdとparamsを持つ）

詳細: `docs/03_design/30_config_spec.md`

### block_catalog.json

**ブロック設計原則:**
- ブロックは「判定・計算」のみ（副作用禁止）
- 入力: Context（Market/State/IndicatorCache/Params）
- 出力: BlockResult
  - `status`: PASS / FAIL / NEUTRAL
  - `direction`: LONG / SHORT / NEUTRAL（必要時のみ）
  - `reason`: 文字列（ログ用）
  - `score`: 任意（将来拡張）

**カテゴリ:**
- filter: スプレッド/セッション/ボラティリティ等
- env: 時間帯、曜日、取引停止等
- trend: M1のみのトレンド判定
- trigger: 押し目・回帰・ブレイク等
- lot: ロット計算（固定、変動、モンテカルロ等）
- risk: SL/TP、ATR等
- exit: トレール、建値、平均利益、週末決済等
- nanpin: 分割エントリー、平均建値決済、シリーズ損切り

**MVPブロック（最小セット）:**
- filter.spreadMax
- env.session.timeWindow
- trend.maRelation（M1：終値とMAの上下）
- trigger.bbReentry（確定足で外→内回帰）
- lot.fixed
- risk.fixedSLTP
- exit.none
- nanpin.off

詳細: `docs/03_design/40_block_catalog_spec.md`

## 開発コマンド

**現在の状態:**
- このリポジトリは現在ドキュメント専用です
- MQL5コードやElectron GUIの実装はまだ含まれていません
- ビルド・テスト・実行コマンドは実装フェーズで追加予定

**将来の実装時:**
- EA開発: MetaEditor（MT5付属）を使用
- GUI開発: Electron + Node.js
- テスト: MT5 Strategy Tester

## アーキテクチャの重要ポイント

### EA Runtime 主要コンポーネント（設計予定）

1. **StrategyEngine**: 戦略の評価と実行制御
2. **CompositeEvaluator**: OR/AND短絡評価の実装
3. **IndicatorCache**: ハンドル共有・計算重複抑制
   - OnInitまたは初回利用で生成
   - shift=1統一（確定足）
4. **OrderExecutor**: 発注処理の集約（副作用）
5. **PositionManager**: ポジション管理の集約（副作用）
6. **StateStore**: 状態管理（lastEntryBarTime等）

### Electron Builder 主要機能（設計予定）

1. **Palette**: block_catalog.jsonからブロック一覧表示
2. **Canvas**: OR/ANDルールをノードで編集
3. **Property**: paramsSchemaに基づくフォーム自動生成
4. **Validate**: 設定の検証
5. **Export**: profiles/<name>.json + active.json出力

## 実装時の重要ルール

### ブロック実装

```mql5
// ✅ 良い例: 副作用なし、判定のみ
struct BlockResult Evaluate(const Context &ctx) {
   double ma = ctx.indicators.GetMA(period, maType, 1);  // shift=1
   bool pass = (ctx.market.close[1] > ma);
   return BlockResult(pass ? PASS : FAIL, LONG, "Close > MA");
}

// ❌ 悪い例: 副作用あり、shift=0使用
struct BlockResult Evaluate(const Context &ctx) {
   double ma = ctx.indicators.GetMA(period, maType, 0);  // shift=0 禁止!
   if (pass) OrderSend(...);  // 副作用禁止!
   return result;
}
```

### 新バー検知

```mql5
// M1新バー時のみエントリー評価
static datetime lastBarTime = 0;
datetime currentBarTime = iTime(Symbol(), PERIOD_M1, 0);

if (currentBarTime != lastBarTime) {
   lastBarTime = currentBarTime;
   // ここでエントリー評価（shift=1使用）
}
```

### 同一足再エントリー防止（二重ガード）

```mql5
// 1. 新バー評価のみ（上記）
// 2. lastEntryBarTimeチェック
if (currentBarTime == lastEntryBarTime) {
   return;  // 同一足での再エントリー拒否
}
```

## ログ出力の重要性

すべての判定・発注・拒否理由をログに残すこと:

- ブロック評価結果（BLOCK_EVAL）
- 採用されたStrategy（STRATEGY_SELECT）
- 発注結果（ORDER_RESULT）
- 発注拒否理由（ORDER_REJECT）
- reason文字列で原因追跡可能にする

詳細: `docs/04_operations/90_observability_and_testing.md`

## 開発の進め方

### Phase 0: 契約確定（最優先）
- strategy_config.json v1 スキーマ確定
- block_catalog.json スキーマ確定
- 主要インターフェース（IBlock/BlockResult/Context）文書化

### Phase 1: EA Runtime MVP
- Engine/Evaluator/Cache/Executor 骨格実装
- MVPブロック実装
- ログ出力実装

### Phase 2: GUI Builder MVP
- Palette/Canvas/Property/Validate/Export 実装
- paramsSchemaからフォーム生成

### Phase 3: 統合検証
- GUI出力 → EA読込 → バックテスト
- 必須テスト項目の検証

### Phase 4: 安全装置・運用強化
- リスクガード/ナンピン安全装置
- ログ整備

詳細: `docs/05_development_plan/10_development_plan.md`

## AIエージェント分担の推奨

衝突を避けるため、以下のように担当を分けることを推奨:

- Agent A: strategy_config.json v1 スキーマ & Validator仕様
- Agent B: block_catalog.json スキーマ & paramsSchema/UIヒント設計
- Agent C: EA Core（Orchestrator/CompositeEvaluator/StrategyEngine）
- Agent D: IndicatorCache（ハンドル共有・CopyBuffer・shift=1統一）
- Agent E: OrderExecutor/PositionManager（副作用まとめ）
- Agent F: Electron Builder（Canvas/Property/Validate/Export）
- Agent G: MVPブロック実装（Spread/Session/MA/BB-Reentry）

## 未決事項（実装時に決定が必要）

1. ポジション管理を「毎Tick」か「新バーのみ」か
2. ナンピン詳細仕様（追加条件の厳格度）
3. Strategy競合解決の拡張（bestScore/all等）
4. ルール合成の拡張（NOT, KofN, スコア合成）
5. ニュース連携（外部API）
6. 状態永続化（再起動復元の範囲）

## 参考: 用語集

- **ブロック**: 判定・計算のみを行う副作用なしの単位（filter/trend/trigger等）
- **Strategy**: エントリー要件（OR×AND）+ リスク管理（lot/SL/TP等）の組
- **DNF**: Disjunctive Normal Form（選言標準形）= OR(AND, AND, ...)
- **shift**: ローソク足のインデックス（0=現在足、1=確定足）
- **確定足**: shift=1、すでに確定した過去の足
- **未確定足**: shift=0、現在形成中の足（原則使用禁止）
- **ナンピン**: 平均建値改善のための分割エントリー（損切り必須）
