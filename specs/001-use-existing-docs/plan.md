# 実装計画: 既存ドキュメント準拠の進行

**ブランチ**: `[001-use-existing-docs]` | **日付**: 2026-01-22 | **仕様**: /Users/ctake3/Documents/pProgram/MQL/Strategy Bricks/specs/001-use-existing-docs/spec.md
**入力**: `/Users/ctake3/Documents/pProgram/MQL/Strategy Bricks/specs/001-use-existing-docs/spec.md` の機能仕様

## サマリ

既存ドキュメント（`docs/`）に記載された合意事項・制約・用語を一覧化し、
矛盾は「要判断」として記録、未決事項は担当者必須で管理する。
一覧は `docs/00_overview.md` に集約し、`docs/README.md` から参照可能にする。
同一用語の定義差は統合し、単一定義に正規化する。

## 技術的コンテキスト

**言語/バージョン**: Markdown（既存ドキュメントの日本語記述）
**主要依存関係**: なし（ドキュメント整理のみ）
**ストレージ**: Git リポジトリ内の Markdown ファイル
**テスト**: 目視レビュー + 受入シナリオの確認
**対象プラットフォーム**: Git リポジトリ（ドキュメント運用）
**プロジェクト種別**: ドキュメントのみ
**性能目標**: なし（ドキュメント運用）
**制約**: 整理対象は `docs/` のみ、一覧は `docs/00_overview.md` に集約、
  出力は日本語、新規要件の追加なし
**規模/スコープ**: `docs/` 配下の合意事項・制約・用語・未決事項

## 憲章チェック（Constitution Check）

*ゲート: フェーズ0のリサーチ前に必須。フェーズ1設計後に再確認。*

- ランタイム変更が M1 新バー評価、確定足（`shift=1`）、同一足再エントリー禁止を
  維持していることを確認する。
- DNF ルール構造（OR が ruleGroups、AND が ruleGroup 内）と短絡評価を確認する。
- ブロックが副作用を持たず、副作用が Executor/Manager に集約されていることを確認する。
- 設定/スキーマ変更が `docs/03_design/` を更新し、非互換時に
  `meta.formatVersion` を更新していることを確認する。
- 観測性と必須テストが `docs/04_operations/90_observability_and_testing.md`
  に沿って計画されていることを確認する。
- 制約変更がある場合は `docs/00_overview.md` と
  `.specify/memory/constitution.md` を更新する。

**チェック結果（初回）**: 本機能はドキュメント整理のみであり、
ランタイム・契約・観測性に影響しないため遵守。

## プロジェクト構成

### ドキュメント（この機能）

```text
/Users/ctake3/Documents/pProgram/MQL/Strategy Bricks/specs/001-use-existing-docs/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml
└── tasks.md
```

### ソースコード（リポジトリ直下）

```text
/Users/ctake3/Documents/pProgram/MQL/Strategy Bricks/docs/
├── 00_overview.md
├── README.md
├── 01_proposal/
├── 02_requirements/
├── 03_design/
├── 04_operations/
└── 05_development_plan/
```

**構成決定**: 本機能は `docs/` 配下の内容整理のみを対象とし、
ソースコードの追加・変更は行わない。

## 複雑性トラッキング

該当なし（憲章違反なし）。

## 憲章チェック（再確認）

フェーズ1設計後も、ランタイム/契約/観測性に影響しないため遵守。
