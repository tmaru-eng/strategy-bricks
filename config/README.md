# 設定ファイル

strategy_config.jsonとblock_catalog.jsonのサンプルファイルを格納します。

## ディレクトリ構造

```
config/
└── samples/            # サンプル設定
    ├── strategy_config_mvp.json      # MVP設定サンプル
    ├── block_catalog_mvp.json        # MVPブロックカタログ
    └── README.md                     # サンプルの説明
```

## 実装状況

**現在の状態**: 未実装（Phase 0完了後に作成予定）

**次のステップ**:
1. strategy_config_mvp.jsonの作成（MVPブロック使用）
2. block_catalog_mvp.jsonの作成（MVPブロック8種）

## 設定ファイル仕様

### strategy_config.json

**用途**: EA Runtimeが読み込む戦略設定

**ファイル運用**:
- EA読込パス: `MQL5/Files/strategy/active.json`（既定）
- Builder出力: `profiles/<name>.json`（保存用）+ `active.json`（実行用）

**重要フィールド**:
- `meta.formatVersion`: 必須（例：`"1.0"`）
- `globalGuards`: EA全体のガード設定
- `strategies[]`: Strategy配列（priority順）
- `blocks[]`: ブロック実体定義

**サンプル構造**:
```json
{
  "meta": {
    "formatVersion": "1.0",
    "name": "active",
    "generatedBy": "Strategy Bricks Builder"
  },
  "globalGuards": {
    "timeframe": "M1",
    "useClosedBarOnly": true,
    "noReentrySameBar": true,
    "maxPositionsTotal": 1
  },
  "strategies": [
    {
      "id": "S1",
      "name": "M1 Pullback Basic",
      "priority": 10,
      "entryRequirement": { ... }
    }
  ],
  "blocks": [ ... ]
}
```

詳細: `docs/03_design/30_config_spec.md`

### block_catalog.json

**用途**: GUI Builderが読み込むブロック定義カタログ

**重要フィールド**:
- `meta.formatVersion`: 必須（例：`"1.0"`）
- `blocks[]`: ブロック定義配列
  - `typeId`: ブロックタイプID（例：`"filter.spreadMax"`）
  - `category`: カテゴリ（例：`"filter"`）
  - `displayName`: 表示名
  - `paramsSchema`: パラメータのJSON Schema

**MVPブロック（8種）**:
1. filter.spreadMax
2. env.session.timeWindow
3. trend.maRelation
4. trigger.bbReentry
5. lot.fixed
6. risk.fixedSLTP
7. exit.none
8. nanpin.off

詳細: `docs/03_design/40_block_catalog_spec.md`

## 使用方法

### GUI Builder開発時

```bash
# block_catalog.jsonを読み込んでパレット表示
gui/src/services/CatalogLoader.ts
```

### EA Runtime開発時

```bash
# strategy_config.jsonを読み込んで実行
ea/src/Config/ConfigLoader.mq5
```

### バックテスト実行時

1. GUI Builderでactive.jsonを出力
2. `MQL5/Files/strategy/active.json`に配置
3. MT5でEAを起動

---

**最終更新**: 2026-01-22
