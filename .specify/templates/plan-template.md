# 実装計画: [FEATURE]

**ブランチ**: `[###-feature-name]` | **日付**: [DATE] | **仕様**: [link]
**入力**: `/specs/[###-feature-name]/spec.md` の機能仕様

**注記**: このテンプレートは `/speckit.plan` コマンドで埋められます。
実行手順は `.specify/templates/commands/plan.md` を参照してください。

## サマリ

[機能仕様から抽出: 主要要件 + リサーチに基づく技術アプローチ]

## 技術的コンテキスト

<!--
  要対応: このセクションの内容をプロジェクト固有の技術詳細に置き換えてください。
  ここでの構成は、反復プロセスを導くための参考構成です。
-->

**言語/バージョン**: [例: Python 3.11、Swift 5.9、Rust 1.75 または 要確認]
**主要依存関係**: [例: FastAPI、UIKit、LLVM または 要確認]
**ストレージ**: [該当する場合、例: PostgreSQL、CoreData、ファイル または N/A]
**テスト**: [例: pytest、XCTest、cargo test または 要確認]
**対象プラットフォーム**: [例: Linux サーバー、iOS 15+、WASM または 要確認]
**プロジェクト種別**: [単体/ウェブ/モバイル - ソース構成を決定]
**性能目標**: [ドメイン固有の目標、例: 1000 req/s、10k lines/sec、60 fps または 要確認]
**制約**: [ドメイン固有の制約、例: <200ms p95、<100MB、オフライン対応 または 要確認]
**規模/スコープ**: [ドメイン固有、例: 10k users、1M LOC、50 画面 または 要確認]

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

## プロジェクト構成

### ドキュメント（この機能）

```text
specs/[###-feature]/
├── plan.md              # このファイル（/speckit.plan コマンド出力）
├── research.md          # フェーズ0の出力（/speckit.plan コマンド）
├── data-model.md        # フェーズ1の出力（/speckit.plan コマンド）
├── quickstart.md        # フェーズ1の出力（/speckit.plan コマンド）
├── contracts/           # フェーズ1の出力（/speckit.plan コマンド）
└── tasks.md             # フェーズ2の出力（/speckit.tasks コマンド - /speckit.plan では生成しない）
```

### ソースコード（リポジトリ直下）
<!--
  要対応: 下記のプレースホルダツリーを、この機能の実際の構成に置き換えてください。
  使わない選択肢は削除し、選んだ構成を実際のパスで展開してください
  （例: apps/admin、packages/something）。
  生成した計画には選択肢ラベルを含めないこと。
-->

```text
# [未使用なら削除] 選択肢1: 単体プロジェクト（既定）
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [未使用なら削除] 選択肢2: Webアプリ（"frontend" + "backend" を検出した場合）
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [未使用なら削除] 選択肢3: モバイル + API（"iOS/Android" を検出した場合）
api/
└── [上記 backend と同様の構成]

ios/ または android/
└── [プラットフォーム固有の構成: 機能モジュール、UIフロー、プラットフォームテスト]
```

**構成決定**: [選択した構成の説明と、上記に記載した実パスの参照]

## 複雑性トラッキング

> **憲章チェックで違反があり、正当化が必要な場合のみ記入**

| 違反 | 必要な理由 | 却下したより簡単な代替案と理由 |
|-----------|------------|-------------------------------------|
| [例: 4つ目のプロジェクト] | [現在の必要性] | [なぜ3プロジェクトでは不十分か] |
| [例: Repository パターン] | [具体的課題] | [なぜ直接DBアクセスでは不十分か] |
