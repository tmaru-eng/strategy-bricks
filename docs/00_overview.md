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
- Electron Strategy Builder
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

---
