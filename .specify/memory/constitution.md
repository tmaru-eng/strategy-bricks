<!--
Sync Impact Report
- バージョン変更: 1.0.3 -> 1.1.0
- 変更された原則: なし
- 追加セクション: なし
- 削除セクション: なし
- 更新対象テンプレート:
  - ✅ .specify/templates/agent-file-template.md
  - ✅ .specify/templates/checklist-template.md
  - ✅ .specify/templates/plan-template.md
  - ✅ .specify/templates/spec-template.md
  - ✅ .specify/templates/tasks-template.md
  - ⚠ .specify/templates/commands/ (directory not present)
- フォローアップTODO: なし
-->
# Strategy Bricks 憲章

## 基本原則

### I. 契約優先ドキュメント
- すべての挙動、インターフェース、スキーマは実装前に `docs/` に明記する。
- 契約変更は該当設計書（例: `docs/03_design/`）と `docs/README.md`、
  制約が変わる場合は `docs/00_overview.md` も更新する。
- 未決事項は担当者と日付を添えて該当ドキュメントに記録する。
理由: 共有された契約が実装・エージェント間の逸脱を防ぐ。

### II. ブロックの純粋性と副作用の分離
- ブロックは `BlockResult` を返す純粋な評価でなければならず、
  取引実行や状態変更を行わない。
- すべての副作用（発注、ポジション変更、永続化）は Executor/Manager に集約する。
理由: 純粋性は決定性を高め、テストとレビューを容易にする。

### III. M1確定足の決定的評価
- 戦略評価は M1 の新バーでのみ実行する。
- インジケータ参照は確定足（`shift=1`）のみ。`shift=0` は禁止。
- 同一足再エントリーは二重ガード（新バー判定 + `lastEntryBarTime`）で防止する。
- エントリー条件は DNF（OR が ruleGroups、AND が ruleGroup 内）を守り、
  短絡評価を実装する。
理由: 再現性の高い評価で、過最適化や運用上の事故を減らす。

### IV. 設定駆動の互換性
- 実行時の挙動は `strategy_config.json`/`active.json` と
  `block_catalog.json` によって定義する。
- `meta.formatVersion` は必須。非互換は取引を停止し理由をログに残す。
- GUI と EA は catalog 定義（paramsSchema、型、既定値）を契約として扱う。
理由: GUI と EA の整合性を保ちつつ、安全に進化させるため。

### V. 追跡可能な判断と必須テスト
- すべての評価、選択、発注試行は
  `docs/04_operations/90_observability_and_testing.md` に従って理由をログ化する。
- ランタイム変更時は、新バー評価・同一足再エントリー禁止・OR/AND短絡の
  受入テストを必ず含める。
- 設定読込やインジケータ失敗は取引停止（no-trade）とし、明示ログを残す。
理由: 運用は判断の可観測性と予測可能な失敗モードに依存する。

## 絶対に守るべき取引制約

- プラットフォーム: MT5（MQL5）限定。
- 時間足: M1 のみ。上位足はトレンド/トリガー判断に使わない。
- ポジション制限超過時は新規エントリーを停止し、管理のみ行う。
- ナンピンは有効化する場合も損失限定を必須とし、MVP は `nanpin.off`。
- Strategy 競合ポリシーは MVP で `firstOnly` 固定（設計書更新で変更可能）。

## ドキュメント運用と遵守レビュー

- 本プロジェクトの運用ドキュメントとテンプレートは日本語で維持する。
- 制約やスキーマの変更は `docs/00_overview.md`、該当設計書、
  本憲章を同一変更で更新する。
- 機能の spec/plan には該当原則を参照する
  「憲章チェック（Constitution Check）」を必ず含める。
- レビューは原則遵守を確認し、例外は理由と影響を文書化する。

## ガバナンス

- 本憲章は他のローカル運用より優先し、矛盾があればドキュメント側を修正する。
- 改定は理由の明記、憲章本文の更新、影響テンプレート/文書の同時更新を要する
  （必要に応じて `docs/README.md` の索引も調整）。
- バージョンはセマンティック・バージョニング:
  - MAJOR: 原則の削除、または互換性のないガバナンス変更。
  - MINOR: 原則/セクション追加、またはガイダンスの実質的拡張。
  - PATCH: 意味変更のない明確化・文言修正。
- 仕様/計画/タスク作成時の遵守確認は必須。例外はレビューで記録する。

**Version**: 1.1.0 | **Ratified**: 2026-01-22 | **Last Amended**: 2026-01-22
