# 申し送り（Handover Notes）— Strategy Bricks（仮称）

## 0. ドキュメントの起点
- 体系の索引は `docs/README.md` を参照する。
- 開発計画は `docs/05_development_plan/10_development_plan.md` を参照する。
- 本書は合意事項と前提の要約として維持する。

## 1. プロジェクトの狙い（要約）
- MT5（MQL5）EAを **設定駆動（JSON）**で動かす。
- 戦略はGUI（Electron）で **ブロック（レゴ）**を組み合わせて作る。
- ブロックは「判定・計算のみ」（副作用なし）。発注や決済など副作用はExecutor/Managerに集約する。
- 保守性（疎結合）を最優先し、AIエージェントが分担実装しやすい構造にする。

## 2. すでに合意している重要要件（絶対条件）
- 対象：MT5（MQL5）
- 動作足：**1分足（M1）**
- 判定：**基本は確定足（closed bar / shift=1）**
- エントリー：**同一足での再エントリー禁止**
- 相場判断：**上位足は原則使わず、M1のみでトレンド/押し目/トリガーを判断**
- ルール構造：**枠がOR、ルール内がAND**（DNF形式）
  - EntryRequirement = OR(ruleGroups)
  - ruleGroup = AND(conditions)
- ポジション制限超過時：**新規エントリー停止、ポジション管理のみ実施**
- ナンピン（平均建値改善）はモードとして用意
  - 分割エントリーの発想
  - ただし **損切り（損失限定）を行う**
  - ポジション数が増えすぎた場合に平均建値で決済する挙動も必要

## 3. 企画・要件ドキュメントの現状
- 企画資料（Project Brief）v0.1 と 要件定義書 v0.1 を Markdownで作成済み（本スレの直前出力）。
- 設計書は未作成（次の優先タスク）。

## 4. 既存コード（参考実装）についての位置づけ
- 既存EAコードは参考であり、**新規で作成する方針**。
- 既存コードの良い点：
  - 判定種類（Trend_Judge/Trigger_Judge）＝ブロックカタログの原型
  - ナンピン・平均建値決済・モンテカルロ等の要素が揃っている
- 移行時の注意（新設計では必須対応）：
  - 未確定足参照（shift=0）を排除し、shift=1中心へ統一
  - インジケータはハンドルキャッシュ（IndicatorCache）で計算重複を抑える
  - エントリー評価は新バー（M1）に閉じ込める（同一足禁止の確実化）

## 5. システム構成（合意イメージ）
### 5.1 コンポーネント
- GUI Builder（Electron）
  - block_catalog.json を読み込みパレット表示
  - OR/ANDルールをノードで編集
  - paramsSchemaに基づきフォーム生成
  - validate → export（profiles/<name>.json + active.json）
- MT5 EA Runtime
  - active.json（strategy_config.json）を読み込み
  - Strategyをpriority順に評価（MVPは firstOnly）
  - ブロック評価→シグナル→Executorで発注
  - 制限超過時は管理のみ
  - ログ（reason）で原因追跡可能にする

### 5.2 ルール評価
- OR（ruleGroups）を短絡評価
- AND（conditions）を短絡評価
- 成立したRuleGroup/ブロックreasonをログ出力

## 6. 優先順位（次にやるべきこと）
最優先：**「契約」を固める**
1) `strategy_config.json v1` の具体スキーマ（設計書：Config Spec）
2) `block_catalog.json` のスキーマ（設計書：Block Catalog Spec）
3) EA側インターフェース定義
   - IBlock Evaluate(ctx)->BlockResult
   - Context（Market/State/Params/Indicators）
   - OrderExecutor/PositionManagerの責務境界
4) MVPブロックセットの確定（最小で枠が動く）
   - filter.spreadMax
   - env.session.timeWindow
   - trend.maRelation（M1のみ）
   - trigger.bbReentry（確定足で回帰系）
   - lot.fixed
   - risk.fixedSLTP（または最小限のSL/TP）
5) ElectronはMVPとして「OR/AND編集」「params編集」「validate」「export」まで

## 7. 未決事項の決定（2026-01-22）

### 7.1 MVP実装前に決定済み（優先度A）

**A1. ポジション管理のタイミング → 決定：新バーのみ**
- M1新バー時のみポジション管理アクション（トレール、建値移動等）を評価
- 理由：エントリー評価と統一、ログ量削減、再現性向上、複雑度低減

**A2. IndicatorCacheのハンドル生成タイミング → 決定：OnInit時**
- OnInit時に全ハンドル生成（遅延生成なし）
- 理由：エラー検出を起動時に前倒し可能、確実性優先

**A3. OrderExecutorの発注モード → 決定：同期発注**
- MVP段階は同期発注のみ実装
- 理由：エラーハンドリング明確、ログ追跡容易、MVP簡素化

**A4. Nanpinモードの詳細ルール → 決定：MVP段階ではnanpin.off固定**
- Phase 1-3ではナンピン機能を実装しない
- Phase 4で実装（追加条件の厳格化、シリーズ損切り等）
- 理由：MVP範囲の明確化、安全性優先

**A5. Strategy競合解決ポリシーの拡張 → 決定：MVP段階では"firstOnly"固定**
- Phase 1-3では"firstOnly"のみ実装
- Phase 4で"bestScore"、"all"等を拡張
- 理由：MVP範囲の明確化

### 7.2 Phase 4以降で決定予定（優先度B）

- ナンピン詳細仕様（追加条件を逆行幅のみ／再トリガー必須等、どこまで厳格にするか）
- Strategy競合解決の拡張方法（"bestScore"のスコア算出方法、"all"の発注順序等）
- ルール合成の拡張（NOT, KofN, スコア合成）
- ニュース連携（設計余地は残すが初期は外部APIなし）
- 状態永続化（再起動復元の範囲）
- ポジション管理の毎Tick評価オプション（必要性を検証後に検討）

## 8. 重要な設計ガイド（メンテ性のための規約）
- ブロックは副作用禁止（発注・決済・変更しない）
- 副作用はExecutor/Managerに集約
- IndicatorCacheでハンドル共有（OnInitまたは初回利用で生成）
- 新バー検知でエントリー評価を1回/分に固定
- lastEntryBarTime等で同一足エントリーを二重で防止
- formatVersionで互換性管理（非互換は実行停止＋ログ）

## 9. AIエージェント分担の推奨（衝突を避ける切り方）
- Agent A：strategy_config.json v1 スキーマ & Validator仕様
- Agent B：block_catalog.json スキーマ & paramsSchema/UIヒント設計
- Agent C：EA Core（Orchestrator/CompositeEvaluator/StrategyEngine）
- Agent D：IndicatorCache（ハンドル共有・CopyBuffer・shift=1統一）
- Agent E：OrderExecutor/PositionManager（副作用まとめ）
- Agent F：Electron Builder（Canvas/Property/Validate/Export）
- Agent G：MVPブロック実装（Spread/Session/MA/BB-Reentry）

## 10. 参考：用語（ブロック遊びの一般名称）
- ブロックプログラミング（Block-based Programming）
- ビジュアルプログラミング（Visual Programming）
- ノードベース（Node-based Editor）
- ルール構造はDNF（ORでAND塊を束ねる）

## 11. 合意事項・矛盾・未決事項の一覧（運用）

### 11.0 記載ルール
- 合意事項一覧：種別（制約/契約/用語）、要約、参照元（ファイル/節）を必須とする。
- 矛盾一覧：ステータスは「要判断」で固定し、参照元は2件以上を推奨する。
- 未決事項一覧：影響範囲/優先度（高/中/低）/担当者（owner）/参照元を必須とする。
- 用語正規化：用語/定義/別表記/参照元を記載し、定義は単一定義に統合する。
- 変更提案の影響点：追加/変更/削除の別、対象、理由、参照元を記載する。

### 11.1 合意事項一覧

| ID | 種別 | 要約 | 参照元 |
| --- | --- | --- | --- |
| A-01 | 制約 | 動作足はM1、評価はM1新バーのみ、判定は確定足（shift=1） | docs/03_design/30_config_spec.md（4. 評価タイミング）, docs/02_requirements/10_requirements.md（6. 制約） |
| A-02 | 制約 | 同一足再エントリー禁止（二重ガード必須） | docs/03_design/30_config_spec.md（4. 評価タイミング）, docs/02_requirements/10_requirements.md（6. 制約） |
| A-03 | 契約 | EntryRequirementはOR、ruleGroupはANDのDNF構造 | docs/03_design/30_config_spec.md（3. ルール構造）, docs/02_requirements/10_requirements.md（4.1 FR-GUI-02） |
| A-04 | 契約 | `meta.formatVersion` 必須、非互換は取引停止＋理由ログ | docs/03_design/30_config_spec.md（2. 互換性）, docs/02_requirements/10_requirements.md（4.2 FR-EA-01） |
| A-05 | 契約 | conflictPolicyのMVP既定は `firstOnly` | docs/03_design/30_config_spec.md（6.3 strategies[]）, docs/02_requirements/10_requirements.md（4.2 FR-EA-06） |
| A-06 | 契約 | ブロックは副作用禁止、BlockResultはPASS/FAIL/NEUTRAL等を持つ | docs/03_design/40_block_catalog_spec.md（1. ブロック設計原則） |
| A-07 | 契約 | GUI/EAは `typeId` を共通キーとしてブロックを一致させる | docs/03_design/40_block_catalog_spec.md（0. 目的, 6. ブロックID運用） |
| A-08 | 契約 | paramsSchemaに基づきGUIでフォーム生成する | docs/03_design/40_block_catalog_spec.md（3. paramsSchema）, docs/02_requirements/10_requirements.md（4.1 FR-GUI-03） |

### 11.2 矛盾一覧（ステータスは「要判断」）

| ID | 内容 | ステータス | 参照元 |
| --- | --- | --- | --- |
| C-01 | ポジション管理の評価タイミングが「新バーのみ決定」と「未決事項」で不整合 | 要判断 | docs/00_overview.md（7.1 A1）, docs/05_development_plan/10_development_plan.md（5. 未決事項とリスク） |

補足: `docs/01_proposal/02_concept_deck.md`、`docs/02_requirements/12_acceptance_criteria.md`、`docs/03_design/20_architecture.md` では矛盾は検出されていない。

### 11.3 未決事項一覧

| ID | 内容 | 影響範囲 | 優先度 | 担当者（owner） | 参照元 |
| --- | --- | --- | --- | --- | --- |
| U-01 | ナンピン詳細仕様（追加条件、シリーズ損切りなど） | EA Runtime/運用 | 中 | EA Runtime担当 | docs/00_overview.md（7.2）, docs/05_development_plan/10_development_plan.md（5. 未決事項とリスク） |
| U-02 | Strategy競合解決の拡張（bestScore/all等） | EA Runtime/評価 | 中 | EA Runtime担当 | docs/00_overview.md（7.2） |
| U-03 | ルール合成拡張（NOT, KofN, スコア合成） | GUI Builder/EA | 低 | GUI Builder担当 | docs/00_overview.md（7.2） |
| U-04 | ニュース連携（外部APIなしの初期方針含む） | GUI Builder/EA | 低 | 運用/検証担当 | docs/00_overview.md（7.2） |
| U-05 | 状態永続化（再起動復元範囲） | EA Runtime | 中 | EA Runtime担当 | docs/00_overview.md（7.2） |
| U-06 | ポジション管理の毎Tick評価オプション | EA Runtime | 低 | EA Runtime担当 | docs/00_overview.md（7.2） |
| U-07 | ログ形式（CSV/JSONL）とテスト自動化範囲 | 運用/検証 | 中 | 運用/検証担当 | docs/05_development_plan/10_development_plan.md（5. 未決事項とリスク）, docs/04_operations/90_observability_and_testing.md（5. 未決事項） |

### 11.4 用語正規化

| 正規用語 | 定義 | 別表記 | 参照元 |
| --- | --- | --- | --- |
| GUI Builder | 戦略をGUIで構築し `active.json` を生成するアプリ | Strategy Builder, Electron Strategy Builder, Strategy Bricks Builder | docs/01_proposal/01_project_brief.md（1.2）, docs/01_proposal/02_concept_deck.md（概要） |
| EA Runtime | MT5上で実行されるEAの実行基盤 | EA, MT5 EA | docs/02_requirements/10_requirements.md（2.1）, docs/03_design/50_ea_runtime_design.md（1.1） |
| Strategy | RuleGroupとロット/リスク/決済/ナンピンを含む取引ルールセット | 戦略 | docs/02_requirements/10_requirements.md（3. 用語定義） |
| ruleGroup | AND条件の集合（全条件PASSで成立） | RuleGroup | docs/03_design/30_config_spec.md（3. ルール構造） |
| EntryRequirement | OR条件の合成ルート | エントリー条件ルート | docs/02_requirements/10_requirements.md（3. 用語定義） |
| Block | 判定・計算のみを行う副作用なしの部品 | ブロック | docs/03_design/40_block_catalog_spec.md（1. ブロック設計原則） |

### 11.5 変更提案の影響点（テンプレート）

| ID | 種別 | 対象 | 影響/理由 | 参照元 |
| --- | --- | --- | --- | --- |
| I-01 | 追加/変更/削除 | <項目> | <理由> | <参照元> |

---
