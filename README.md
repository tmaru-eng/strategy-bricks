# Strategy Bricks（仮称）

MT5（MQL5）EA をJSON設定駆動で動作させるシステム。Electron GUIでブロック（レゴ）を組み合わせて戦略を構築し、EAが実行します。

## プロジェクト概要

Strategy Bricksは、トレーディング戦略を「ブロック」として構築し、GUIで視覚的に組み立てることができるシステムです。

**重要な設計方針:**
- 保守性を最優先（疎結合、副作用の集約）
- AIエージェントが分担実装しやすい構造
- すべての判定・計算はブロック化（副作用なし）
- 発注・決済などの副作用はExecutor/Managerに集約

## ディレクトリ構造

```
Strategy Bricks/
├── docs/                    # ドキュメント（要件・設計・運用）
│   ├── 00_overview.md       # 合意事項・前提条件（最優先で確認）
│   ├── README.md            # ドキュメント全体の索引
│   ├── 01_proposal/         # 企画資料
│   ├── 02_requirements/     # 要件定義
│   ├── 03_design/           # 設計仕様（契約定義 - 最重要）
│   ├── 04_operations/       # 運用・テスト計画
│   └── 05_development_plan/ # 開発計画とマイルストーン
├── ea/                      # EA Runtime（MQL5）
│   ├── src/                 # ソースコード
│   └── include/             # ヘッダファイル
├── gui/                     # GUI Builder（Electron）
│   └── src/                 # ソースコード
├── config/                  # 設定ファイル
│   └── samples/             # サンプル設定
└── scripts/                 # 検証・運用スクリプト
    └── validation/          # ログ検証スクリプト
```

## クイックスタート

### ドキュメントを読む

**必ず最初に読むべきファイル:**
- `docs/00_overview.md` - 合意事項・前提条件・重要要件の要約
- `docs/README.md` - ドキュメント全体の索引

**主要ドキュメント:**
- `docs/03_design/30_config_spec.md` - strategy_config.json スキーマ
- `docs/03_design/40_block_catalog_spec.md` - block_catalog.json スキーマ
- `docs/03_design/45_interface_contracts.md` - インターフェース契約書
- `docs/03_design/50_ea_runtime_design.md` - EA Runtime詳細設計
- `docs/03_design/60_gui_builder_design.md` - GUI Builder詳細設計

### 開発を開始する

**現在の状態:**
- ドキュメント成熟度: **98%**
- 実装状態: **Phase 0完了間近**（未決事項決定済み、契約書作成済み）

**次のステップ:**
1. プロトタイプ検証（EA）の実施
2. GUI技術検証の実施
3. Phase 1（EA Runtime MVP）の実装開始

**開発計画:**
- `docs/05_development_plan/10_development_plan.md` - 全体計画
- `docs/05_development_plan/15_mvp_checklist.md` - MVPチェックリスト

## 絶対に守るべき要件（強い制約）

以下は要件定義で**絶対条件**として合意済み。これらに違反する実装は許容されません:

1. **対象プラットフォーム**: MT5（MQL5）のみ
2. **動作時間足**: M1（1分足）固定
3. **判定基準**: 基本は確定足（shift=1）、未確定足（shift=0）の使用は原則禁止
4. **エントリー評価**: M1新バー時のみ評価（1分に1回）
5. **同一足再エントリー禁止**: 必須（二重ガード実装）
6. **相場判断**: 上位足は原則使わず、M1のみでトレンド/押し目/トリガーを判断
7. **ルール構造**: DNF形式（枠がOR、ルール内がAND）
8. **ポジション制限超過時**: 新規エントリー停止、ポジション管理のみ実施

詳細: `docs/00_overview.md`

## 設定ファイル仕様（契約）

### strategy_config.json（active.json）

**ファイル運用:**
- EA読込パス: `MQL5/Files/strategy/active.json`（既定）
- Builder出力: `profiles/<name>.json`（保存用）+ `active.json`（実行用）

**重要フィールド:**
- `meta.formatVersion`: 必須。非対応バージョンは起動後に取引処理を停止
- `globalGuards`: EA全体のガード設定
- `strategies[]`: Strategy配列（priority順）
- `blocks[]`: ブロック実体定義

詳細: `docs/03_design/30_config_spec.md`

### block_catalog.json

**ブロック設計原則:**
- ブロックは「判定・計算」のみ（副作用禁止）
- 入力: Context（Market/State/IndicatorCache/Params）
- 出力: BlockResult（status/direction/reason）

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

## ライセンス

TBD

## 貢献

TBD

## 連絡先

TBD

---

**最終更新**: 2026-01-22
**プロジェクト状態**: Phase 0（契約確定）- 実装開始間近
**ドキュメント成熟度**: 98%
