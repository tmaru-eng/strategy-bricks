# 03_design/40_block_catalog_spec.md
# ブロックカタログ仕様（契約）— block_catalog.json v1

## 0. 目的
- Builder（GUI）のパレット表示・フォーム生成と、EA（MQL5）のブロック生成を **同一のtypeId定義**で一致させる契約。

## 1. ブロックの設計原則（メンテナンス最優先）
- ブロックは「判定・計算」のみ（副作用禁止）
- 入力：Context（Market/State/IndicatorCache/Params）
- 出力：BlockResult
  - `status`：PASS / FAIL / NEUTRAL
  - `direction`：LONG / SHORT / NEUTRAL（必要なブロックのみ）
  - `reason`：文字列（ログに残す）
  - `score`：任意（将来拡張）

## 2. カタログJSON構造（案）
- `meta`：バージョン
- `blocks[]`：ブロック定義（typeId単位）

### 2.1 例（抜粋）
```json
{
  "meta": { "formatVersion": "1.0" },
  "blocks": [
    {
      "typeId": "filter.spreadMax",
      "category": "filter",
      "displayName": "Max Spread Filter",
      "description": "スプレッドが指定pips以下の時のみPASS",
      "paramsSchema": {
        "type": "object",
        "required": ["maxSpreadPips"],
        "properties": {
          "maxSpreadPips": {
            "type": "number",
            "minimum": 0.0,
            "maximum": 50.0,
            "default": 2.0,
            "ui": { "control": "number" }
          }
        }
      },
      "io": { "direction": "none", "score": "none" },
      "runtimeHints": { "timeframe": "M1", "useClosedBarOnly": true }
    }
  ]
}
```

## 3. paramsSchema（フォーム自動生成のための最小規約）
- 基本は JSON Schema 互換の形（厳密準拠は必須ではないが寄せる）
- `ui.control` を任意で持てる（Builder側でフォーム生成を安定化）
  - number / select / checkbox / timeWindow / enumFlags 等

## 4. カテゴリ（推奨）
- filter（（Spread/Session/Volatility/News等））
- env（時間帯、曜日、取引停止等）
- trend（M1のみのトレンド判定）
- trigger（押し目・回帰・ブレイク等のトリガー）
- lot（固定、変動、モンテカルロ、マーチン等）
- risk（SL/TP、ATR等）
- exit（トレール、建値、平均利益、週末等）
- nanpin（分割エントリー、平均建値決済、シリーズ損切り）

## 5. MVPブロック（最小セット提案）
- filter.spreadMax
- env.session.timeWindow
- trend.maRelation（M1：終値とMAの上下）
- trigger.bbReentry（確定足で外→内回帰）
- lot.fixed
- risk.fixedSLTP
- exit.none（or 最小の週末決済）
- nanpin.off

## 6. ブロックIDの命名・参照（運用規約）
- 実体（config内）では `id` をユニークにする
  - 例：`trend.maRelation#1`
- typeId はカタログのキー（EA/GUI共通）

## 7. ブロックの評価規約（EA側で統一）
- M1新バー評価で `shift=1` を標準入力として扱う
- 例外（shift=0許可）を作らない（要件で「基本は確定足」）
- IndicatorCache経由で取得し、ブロックが直接CopyBuffer乱用しない

## 8. 未決事項（連携先で検討継続）
- score導入の要否（bestScore等の競合解決に必要）
- NOT/KofN等の合成拡張（UIと設定表現の追加設計が必要）
- Newsフィルタの実装方式（外部連携なしの暫定策は時間帯ブラックアウト等）