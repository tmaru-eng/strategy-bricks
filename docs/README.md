# 資料体系（提案）：Strategy Bricks（仮称）

目的：
- 全体像（企画）から実装（設計）まで、議論の粒度を揃え、変更に強いドキュメント構造を作る。

起点：
- `docs/README.md`：資料体系の索引と更新の入口
- `docs/00_overview.md`：合意事項・前提の要約（最初に読む）

推奨フォルダ：
docs/
  00_overview.md
  01_proposal/
  02_requirements/
  03_design/
  04_operations/
  05_development_plan/

---

## 00_overview（引き継ぎ／合意事項）
全体の前提・制約・優先順位を短く把握するための要約。

### 00_overview.md（Handover Notes）
- 重要要件（M1/確定足/同一足禁止/OR×AND）
- 合意済みの構成イメージと役割分担
- 未決事項と次に決めるべきこと

---

## 01_proposal（企画資料：Why / What / Value）
「意思決定者・協力者に短時間で説明する」ための資料群。
実装詳細は載せない（入れるとしても図と概要レベル）。

### 01_proposal/01_project_brief.md（1〜3ページ相当）
- 背景／課題（単一戦略の破綻、運用負担、条件追加の属人化）
- 目的（GUIでブロック合成→EA実行）
- 価値（再利用・検証・拡張が速い、運用が安全）
- 提供物（Electron Builder、EA Runtime、JSON設定、テンプレ戦略）
- スコープ（M1、確定足、同一足再エントリー禁止、ナンピンモード）
- ざっくりロードマップ（MVP→拡張）
- リスクと対策（過最適化、計算負荷、運用事故）

### 01_proposal/02_concept_deck.md（図多めの企画デッキ）
- 全体アーキテクチャ図（Electron→JSON→EA）
- ユーザーフロー（ブロック選択→検証→出力→EA稼働）
- ルール構造図（OR枠×AND内）
- 競合解決（priority+firstOnly）
- ナンピンモードの位置づけ（安全装置込み）

---

## 02_requirements（要件定義：What / Constraints / Acceptance）
「作るものの境界」と「守るルール」を確定させる。
実装の仕方は極力書かない（設計書に送る）。

### 02_requirements/10_requirements.md（要件定義書）
- 目的・成功条件
- 機能要件（EA、GUI、設定）
- 非機能要件（メンテ性、性能、観測性）
- 制約（M1のみ、確定足、同一足再エントリー禁止）
- 受入条件（テスターでの再現性、ログ出力、設定互換性）

### 02_requirements/11_user_stories.md（ユーザーストーリー/ユースケース）
- 「ブロックを組む」「パラメータ調整」「テンプレから作る」「active.jsonで反映」等

### 02_requirements/12_acceptance_criteria.md（受入基準）
- 例：新バーのみエントリー評価される
- 例：同一バー内で複数回エントリーしない
- 例：設定参照切れをGUIで検出
- 例：ブロック評価のreasonがログに残る

---

## 03_design（設計資料：How / Interfaces / Data）
「AIエージェントが分担実装しやすい」ために最重要。
契約（スキーマ/インターフェース）をここに集約。

### 03_design/20_architecture.md（アーキテクチャ設計）
- レイヤ（Domain/Application/Infra）
- 主要コンポーネント責務
- 依存方向ルール
- Mermaid：EA内部データフロー、GUI→出力フロー

### 03_design/30_config_spec.md（設定ファイル仕様：契約）
- strategy_config.json v1 スキーマ
- entryRequirement = OR(ruleGroups)
- ruleGroup = AND(conditions)
- formatVersionと互換性ルール
- active.json運用

### 03_design/40_block_catalog_spec.md（ブロックカタログ仕様：契約）
- block_catalog.json の構造（typeId、paramsSchema、UIヒント）
- BlockResult（PASS/FAIL/NEUTRAL、direction、reason、score）
- カテゴリ（filter/trend/trigger/lot/risk/exit/nanpin）

### 03_design/50_ea_runtime_design.md（EA詳細設計）
- 新バー検知（M1）
- shift=1統一（確定足）
- 同一足再エントリー禁止（二重ガード）
- IndicatorCache（ハンドル共有）
- OrderExecutor/PositionManager/StateStore

### 03_design/60_gui_builder_design.md（GUI詳細設計）
- 画面構成（Palette/Canvas/Property/Validate/Export）
- OR枠×AND内のUI制約
- paramsSchema→フォーム自動生成
- Export先（profiles/ と active.json）

### 03_design/70_security_safety.md（安全設計）
- リスクガード（最大ポジ、最大ロット、スプレッド停止）
- ナンピン安全装置（最大回数、シリーズ損切り、最大時BE決済）
- 運用事故防止（設定バリデーション、ログ）

---

## 04_operations（運用・検証：Run / Test / Observe）
「実運用で壊れない」「原因追跡できる」ための資料。

### 04_operations/80_testing.md（テスト計画）
- ConfigValidatorテスト
- CompositeEvaluatorテスト（OR/AND短絡）
- ブロック単体テスト方針
- ストラテジーテスターでの確認項目（再現性）

### 04_operations/90_observability_and_testing.md（ログ/モニタリングとテスト）
- ログ項目（ブロックreason、採用Strategy、発注拒否理由）
- デバッグモード
- レポート出力（CSV/JSON）

### 04_operations/99_runbook.md（運用手順）
- active.json差し替え
- パラメータ変更手順
- トラブルシュート（発注失敗、スプレッド停止、ハンドル失敗）

---

## 05_development_plan（開発計画：Plan / Milestones / Execution）
要件・設計の合意を前提に、開発順序と検証の観点を整理する。

### 05_development_plan/10_development_plan.md（開発計画）
- フェーズ分割と成果物
- マイルストーン定義
- 並行ストリームと未決事項

---

# 最小セット（まず作るなら）
- 01_project_brief.md（企画サマリ）
- 02_requirements/10_requirements.md（要件定義）
- 03_design/30_config_spec.md（設定スキーマ：契約）
- 03_design/40_block_catalog_spec.md（ブロック仕様：契約）
- 03_design/50_ea_runtime_design.md（EA詳細設計）
