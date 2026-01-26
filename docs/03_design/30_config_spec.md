# 03_design/30_config_spec.md
# 設定ファイル仕様（契約）— strategy_config.json v1（active.json運用）

## 0. 目的
- Electron Builder が出力する戦略設定を MT5 EA が **同一解釈で実行**するための契約を定義する。
- “メンテナンス性”の観点から、仕様変更は `formatVersion` により管理する。

## 1. ファイル運用
- 推奨：EAは `MQL5/Files/strategy/active.json` を既定パスとして読む
- Builderは以下を出力する
  - `profiles/<name>.json`（保存用）
  - `active.json`（EA実行用：現在有効な設定）

## 2. 互換性
- `meta.formatVersion` は必須
- EAは `meta.formatVersion` が対応範囲外の場合、**起動後に取引処理を停止**し、理由をログ出力する

## 3. ルール構造（DNF：枠OR × 内AND）
- EntryRequirement = OR（ruleGroups）
- ruleGroup = AND（conditions）
- ルール内は「全てを満たした時のみ成立」
- 枠は「どれか成立すれば成立」

```mermaid
flowchart TB
  CFG[strategy_config.json] --> STRATS[strategies[]]
  STRATS --> ER[entryRequirement（OR）]
  ER --> RG1[ruleGroup（AND）]
  ER --> RG2[ruleGroup（AND）]
  RG1 --> C1[condition blockRef]
  RG1 --> C2[condition blockRef]
  STRATS --> LOT[lotModel]
  STRATS --> RISK[riskModel]
  STRATS --> EXIT[exitModel]
  STRATS --> NAN[nanpinModel]
```

## 4. 評価タイミング（強い制約）
- 動作足：M1
- エントリー評価：**M1新バー時のみ**
- 判定参照：**基本は確定足（shift=1）**
- 同一足再エントリー禁止：**必須（二重ガード）**
  - 新バー評価のみ
  - `lastEntryBarTime` で同一バーの発注拒否

## 5. 設定JSONのトップレベル構造（案）
> ここでは “スキーマ草案” として定義する。厳密JSON Schema化は次フェーズ。

- `meta`：メタ情報
- `globalGuards`：EA全体のガード（最大ポジ、スプレッド、同一足禁止など）
- `strategies[]`：Strategyの配列（priority順）

### 5.1 例（最小構成のサンプル）
```json
{
  "meta": {
    "formatVersion": "1.0",
    "name": "active",
    "generatedBy": "Strategy Bricks Builder",
    "generatedAt": "2026-01-22T00:00:00Z"
  },
  "globalGuards": {
    "timeframe": "M1",
    "useClosedBarOnly": true,
    "noReentrySameBar": true,
    "maxPositionsTotal": 1,
    "maxPositionsPerSymbol": 1,
    "maxSpreadPips": 2.0,
    "session": {
      "enabled": true,
      "windows": [
        { "start": "07:00", "end": "14:59" },
        { "start": "15:03", "end": "03:00" }
      ],
      "weekDays": { "mon": true, "tue": true, "wed": true, "thu": true, "fri": true }
    }
  },
  "strategies": [
    {
      "id": "S1",
      "name": "M1 Pullback Basic",
      "enabled": true,
      "priority": 10,
      "conflictPolicy": "firstOnly",
      "directionPolicy": "both",
      "entryRequirement": {
        "type": "OR",
        "ruleGroups": [
          {
            "id": "RG1",
            "type": "AND",
            "conditions": [
              { "blockId": "filter.spreadMax#1" },
              { "blockId": "env.session#1" },
              { "blockId": "trend.maRelation#1" },
              { "blockId": "trigger.bbReentry#1" }
            ]
          }
        ]
      },
      "lotModel": { "type": "lot.fixed", "params": { "lots": 0.1 } },
      "riskModel": { "type": "risk.fixedSLTP", "params": { "slPips": 30, "tpPips": 30 } },
      "exitModel": { "type": "exit.none", "params": {} },
      "nanpinModel": { "type": "nanpin.off", "params": {} }
    }
  ],
  "blocks": [
    { "id": "filter.spreadMax#1", "typeId": "filter.spreadMax", "params": { "maxSpreadPips": 2.0 } },
    { "id": "env.session#1", "typeId": "env.session.timeWindow", "params": { "useGlobal": true } },
    { "id": "trend.maRelation#1", "typeId": "trend.maRelation", "params": { "period": 200, "maType": "EMA", "relation": "closeAbove" } },
    { "id": "trigger.bbReentry#1", "typeId": "trigger.bbReentry", "params": { "period": 20, "deviation": 2.0, "side": "lowerToInside" } }
  ]
}
```

## 6. フィールド定義（要点）
### 6.1 meta
- `formatVersion`：必須（例：`"1.0"`）
- `name`：任意（active/profilename）
- `generatedBy`/`generatedAt`：任意（運用・追跡に有用）

### 6.2 globalGuards（代表）
- `timeframe`：固定（"M1"）
- `useClosedBarOnly`：true固定（要件）
- `noReentrySameBar`：true固定（要件）
- `maxPositionsTotal` / `maxPositionsPerSymbol`
- `maxSpreadPips`
- `session`：時間帯・曜日制御（（Spread/Session/Volatility/News等）のうちSessionをここで実現）

### 6.3 strategies[]
- `priority`：数値（推奨：**大きいほど優先**）
- `conflictPolicy`：MVPは `"firstOnly"` を既定
- `directionPolicy`：`"longOnly" | "shortOnly" | "both"`
- `entryRequirement`：OR/AND構造
- `lotModel`：固定／変動（SL条件や資産から決定）／モンテカルロ／マーチン等
- `riskModel`：SL/TP/トレール等（最低限 SL/TP はMVP必須）
- `exitModel`：週末決済、反対シグナル、平均利益決済、建値、部分決済等
- `nanpinModel`：ナンピン（分割エントリー）と安全装置

### 6.4 blocks[]
- Builderが生成する「実体定義」
- `blockId`参照の解決先
- 追加・変更を局所化するため、Strategyからは `blockId` を参照する方式を基本とする

#### 6.4.1 blockId形式仕様（v1.1追加）

**形式**: `{typeId}#{uniqueIndex}`

**ルール**:
- typeIdはblock_catalog.jsonで定義されたブロックタイプ識別子
- uniqueIndexは正の整数（1から開始）
- セパレータは`#`（ハッシュ記号）必須
- 同じtypeIdでも異なるパラメータを持つ場合は異なるindexを使用

**例**:
```json
{
  "blocks": [
    {
      "id": "filter.spreadMax#1",
      "typeId": "filter.spreadMax",
      "params": { "maxSpreadPips": 2.0 }
    },
    {
      "id": "trend.maRelation#1",
      "typeId": "trend.maRelation",
      "params": { "period": 200, "maType": "EMA", "relation": "closeAbove" }
    },
    {
      "id": "trend.maRelation#2",
      "typeId": "trend.maRelation",
      "params": { "period": 50, "maType": "SMA", "relation": "closeBelow" }
    }
  ]
}
```

#### 6.4.2 blockId検証要件（v1.1追加）

**GUI Builder側の検証**:
1. **一意性**: blocks[]配列内のすべてのblockIdは一意でなければならない
2. **参照解決**: strategies[].entryRequirement.ruleGroups[].conditions[].blockIdで参照されるすべてのblockIdは、blocks[]配列に存在しなければならない
3. **形式準拠**: すべてのblockIdは`{typeId}#{index}`形式に従わなければならない（正規表現: `^[a-zA-Z0-9._]+#\d+$`）

**EA Runtime側の検証**:
1. **参照検証**: ConfigLoader::ValidateBlockReferences()で全参照の解決可能性を確認
2. **重複検証**: ConfigLoader::ValidateDuplicateBlockIds()で重複を検出
3. **形式検証**: ConfigLoader::ValidateBlockIdFormat()で形式準拠を確認
4. **初期化失敗**: 検証失敗時はINIT_FAILEDを返し、詳細をログ出力

#### 6.4.3 共有ブロックの扱い（v1.1追加）

**定義**: 複数のstrategyまたはruleGroupで同じblockIdを参照するブロック

**重要**: 共有ブロックはblocks[]配列に1回のみ出現し、複数のconditionsから同じblockIdで参照される

**例**:
```json
{
  "strategies": [
    {
      "id": "S1",
      "entryRequirement": {
        "ruleGroups": [
          {
            "id": "RG1",
            "conditions": [
              { "blockId": "filter.spreadMax#1" },
              { "blockId": "trend.maRelation#1" }
            ]
          }
        ]
      }
    },
    {
      "id": "S2",
      "entryRequirement": {
        "ruleGroups": [
          {
            "id": "RG2",
            "conditions": [
              { "blockId": "filter.spreadMax#1" },
              { "blockId": "trend.maRelation#2" }
            ]
          }
        ]
      }
    }
  ],
  "blocks": [
    {
      "id": "filter.spreadMax#1",
      "typeId": "filter.spreadMax",
      "params": { "maxSpreadPips": 2.0 }
    },
    {
      "id": "trend.maRelation#1",
      "typeId": "trend.maRelation",
      "params": { "period": 200, "maType": "EMA", "relation": "closeAbove" }
    },
    {
      "id": "trend.maRelation#2",
      "typeId": "trend.maRelation",
      "params": { "period": 50, "maType": "SMA", "relation": "closeBelow" }
    }
  ]
}
```

上記の例では、`filter.spreadMax#1`は両方のstrategyで共有されている。

## 7. 未決事項（連携先で検討継続）
- ポジション管理の評価タイミング：毎Tick vs 新バーのみ
- conflictPolicy の拡張：bestScore / all / allowMulti 等
- nanpinModel の詳細（再トリガー必須化、シリーズ損切りの定義粒度）
- （Volatility/News等）の扱い：初期はVolatilityのみ、Newsは外部連携前提で将来拡張

## 8. 変更履歴

| 版 | 日付 | 変更内容 |
|----|------|---------|
| v1.0 | 2026-01-22 | 初版作成 |
| v1.1 | 2026-01-26 | blockId形式仕様と検証要件を追加（セクション6.4.1-6.4.3） |