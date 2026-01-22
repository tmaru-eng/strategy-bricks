# フェーズ0: リサーチ結果

## 1. 整理対象の範囲

- **Decision**: 整理対象は `docs/` 配下のみとし、`README.md` と `CLAUDE.md` は参照のみ。
- **Rationale**: 合意事項の一次情報源を `docs/` に限定し、運用の一貫性を保つため。
- **Alternatives considered**: `README.md`/`CLAUDE.md` を一次情報源に含める案
  （情報の重複と更新コストが増えるため不採用）。

## 2. 一覧の集約先

- **Decision**: 合意事項/矛盾/未決事項の一覧は `docs/00_overview.md` に集約し、
  `docs/README.md` から参照可能にする。
- **Rationale**: 最初に参照される入口に集約することでレビュー効率が上がるため。
- **Alternatives considered**: 新規ドキュメントの追加（入口が分散するため不採用）。

## 3. 矛盾の扱い

- **Decision**: ドキュメント間の矛盾は優先順位を設けず、すべて「要判断」として記録する。
- **Rationale**: 既存合意を崩さず判断待ちを明確化するため。
- **Alternatives considered**: 形式的な優先順位付け（誤解が生まれる可能性があるため不採用）。

## 4. 未決事項の管理

- **Decision**: 未決事項には必ず担当者（owner）を設定する。
- **Rationale**: 未決事項の滞留を防ぎ、判断の責任者を明確にするため。
- **Alternatives considered**: 任意運用（放置されるリスクが高いため不採用）。

## 5. 用語の正規化

- **Decision**: 同じ用語に異なる定義がある場合は用語を統合し、単一定義に正規化する。
- **Rationale**: 用語の一貫性を保ち、レビューの迷いを減らすため。
- **Alternatives considered**: 併記・注釈運用（継続的な混乱を招くため不採用）。
