# 開発計画（MVP前提）— Strategy Bricks（仮称）

## 0. 目的
- 仕様契約を固め、EA Runtime と GUI Builder を並行開発できる状態にする。
- 再現性・安全性の要件を満たす MVP を短期間で検証可能にする。

## 1. 前提と参照ドキュメント
- 参照: `docs/00_overview.md`, `docs/02_requirements/10_requirements.md`, `docs/03_design/30_config_spec.md`, `docs/03_design/40_block_catalog_spec.md`, `docs/04_operations/90_observability_and_testing.md`
- 重要前提: M1のみ、確定足（shift=1）、同一足再エントリー禁止、OR×AND、Strategyは firstOnly、ポジション管理は新バーのみ。

## 2. フェーズと成果物
### Phase 0: 契約確定
- `strategy_config.json v1` スキーマ確定。
- `block_catalog.json` スキーマ確定。
- 主要インターフェース（IBlock/BlockResult/Context）を文書化。
- 完了条件: スキーマ差分が凍結され、サンプル設定が読み書き可能。

### Phase 1: EA Runtime MVP
- StrategyEngine/CompositeEvaluator/IndicatorCache/Executor 骨格。
- MVPブロック実装（例: spread/session/maRelation/bbReentry/lot.fixed/risk.fixedSLTP）。
- ログ出力（BLOCK_EVAL/ORDER_RESULT など）を仕様通りに実装。
- 完了条件: `active.json` を読込でき、要件テスト項目がログで追跡可能。

### Phase 2: GUI Builder MVP
- Palette/Canvas/Property/Validate/Export の基本導線。
- paramsSchema からフォーム生成。
- 完了条件: `profiles/<name>.json` と `active.json` を出力できる。

### Phase 3: 統合検証
- GUI 出力 → EA 読込 → バックテストの一連動作。
- 必須テスト（新バーのみ評価、同一足禁止、OR/AND短絡）を検証。
- 完了条件: 代表シナリオで再現性が取れること。

### Phase 4: 安全装置・運用強化
- リスクガード/ナンピン安全装置/ログ整備の強化。
- 完了条件: 運用事故の主要パターンがログと制限で防止できる。

## 3. ワークストリーム（並行可能）
- 仕様契約: スキーマ、互換性ルール、サンプル設定。
- EA Runtime: Engine/Cache/Executor/PositionManager/Log。
- GUI Builder: UI制約（OR×AND）/フォーム生成/検証。
- 検証: テスト項目整理、テストデータ準備、再現性確認。

## 4. マイルストーン定義（最小）
- M0: 契約凍結（Config/Block Catalog/Interfaces）。
- M1: EAコア動作（新バー評価・ログ・MVPブロック）。
- M2: GUIで設定作成・出力。
- M3: 統合検証完了（必須テスト達成）。
- M4: 運用安全性強化（制限/ログ/ナンピン安全）。

## 5. 未決事項とリスク
- ナンピン詳細仕様（段数、追加条件、シリーズ損切り）。(owner: EA Runtime担当)
- Strategy競合解決の拡張（firstOnly以外）。(owner: EA Runtime担当)
- ログ形式（CSV/JSONL）とテスト自動化範囲。(owner: 運用/検証担当)

## 6. 進め方（更新ルール）
- 仕様変更は該当ドキュメントと `docs/README.md` を同時更新。
- フェーズ完了時は本ドキュメントの完了条件を更新して履歴を残す。
