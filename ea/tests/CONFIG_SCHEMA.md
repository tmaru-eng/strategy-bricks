# Strategy Bricks 統一設定ファイルスキーマ

## 概要

このドキュメントは、Strategy Bricks GUIビルダーとEA（MQL5）の両方で使用される統一JSON設定ファイルフォーマットを定義します。このスキーマは、ストラテジー設定の一貫性を保ち、GUIで作成した設定をEAで実行可能にし、さらにPythonバックテストエンジンでも使用できるように設計されています。

## バージョン

- **スキーマバージョン**: 1.0
- **最終更新**: 2026-01-26
- **互換性**: GUI Builder v1.0+, EA v1.0+, Backtest Engine v1.0+

## 設計原則

1. **後方互換性**: 将来のバージョンでも既存の設定ファイルが動作するよう、`formatVersion`フィールドで管理
2. **拡張性**: 新しいブロックタイプやパラメータを追加しても既存の実装に影響しない
3. **明確性**: すべてのフィールドは明確な意味を持ち、ドキュメント化されている
4. **検証可能性**: 必須フィールドとオプションフィールドが明確に定義されている
5. **プラットフォーム非依存**: GUI、EA、Pythonエンジンのすべてで同じフォーマットを使用

## ルートオブジェクト構造

```json
{
  "meta": { ... },
  "globalGuards": { ... },
  "strategies": [ ... ],
  "blocks": [ ... ]
}
```

### フィールド一覧

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `meta` | Object | ✓ | メタデータ情報 |
| `globalGuards` | Object | ✓ | グローバルガード設定 |
| `strategies` | Array | ✓ | ストラテジー定義の配列 |
| `blocks` | Array | ✓ | ブロック定義の配列 |


## 1. メタデータ (meta)

メタデータセクションは、設定ファイルのバージョン管理と生成情報を含みます。

### スキーマ

```json
{
  "meta": {
    "formatVersion": "1.0",
    "name": "My Strategy",
    "generatedBy": "GUI Builder",
    "generatedAt": "2026-01-26T10:30:00Z",
    "description": "Optional strategy description",
    "author": "Optional author name",
    "tags": ["optional", "tags"]
  }
}
```

### フィールド定義

| フィールド | 型 | 必須 | 説明 | 例 |
|-----------|-----|------|------|-----|
| `formatVersion` | String | ✓ | スキーマバージョン | "1.0" |
| `name` | String | ✓ | ストラテジー設定の名前 | "My Strategy" |
| `generatedBy` | String | ✓ | 生成元（GUI Builder, Manual, etc.） | "GUI Builder" |
| `generatedAt` | String (ISO 8601) | ✓ | 生成日時 | "2026-01-26T10:30:00Z" |
| `description` | String | ✗ | ストラテジーの説明 | "Trend following strategy" |
| `author` | String | ✗ | 作成者名 | "John Doe" |
| `tags` | Array<String> | ✗ | タグ（分類用） | ["scalping", "trend"] |

### バリデーションルール

- `formatVersion`: 現在は "1.0" のみサポート
- `name`: 1文字以上、255文字以下
- `generatedAt`: ISO 8601形式の日時文字列
- `tags`: 各タグは1文字以上、50文字以下


## 2. グローバルガード (globalGuards)

グローバルガードは、すべてのストラテジーに適用される共通の制約条件を定義します。

### スキーマ

```json
{
  "globalGuards": {
    "timeframe": "M1",
    "useClosedBarOnly": true,
    "noReentrySameBar": true,
    "maxPositionsTotal": 5,
    "maxPositionsPerSymbol": 3,
    "maxSpreadPips": 2.5,
    "session": {
      "enabled": true,
      "windows": [
        { "start": "00:00", "end": "23:59" }
      ],
      "weekDays": {
        "sun": false,
        "mon": true,
        "tue": true,
        "wed": true,
        "thu": true,
        "fri": true,
        "sat": false
      }
    }
  }
}
```

### フィールド定義

| フィールド | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `timeframe` | String | ✓ | 時間軸 | "M1" 固定（MVP） |
| `useClosedBarOnly` | Boolean | ✓ | 確定足のみ使用 | true 固定（MVP） |
| `noReentrySameBar` | Boolean | ✓ | 同一足再エントリー禁止 | true 固定（MVP） |
| `maxPositionsTotal` | Integer | ✓ | 最大ポジション数（全体） | 1以上 |
| `maxPositionsPerSymbol` | Integer | ✓ | 最大ポジション数（シンボル毎） | 1以上 |
| `maxSpreadPips` | Number | ✓ | 最大スプレッド（pips） | 0以上 |
| `session` | Object | ✓ | セッション設定 | 下記参照 |

### session オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `enabled` | Boolean | ✓ | セッション制限の有効/無効 |
| `windows` | Array<TimeWindow> | ✓ | 取引時間帯の配列 |
| `weekDays` | Object | ✓ | 曜日別の有効/無効 |

### TimeWindow オブジェクト

| フィールド | 型 | 必須 | 説明 | 形式 |
|-----------|-----|------|------|------|
| `start` | String | ✓ | 開始時刻 | "HH:MM" (24時間形式) |
| `end` | String | ✓ | 終了時刻 | "HH:MM" (24時間形式) |

### weekDays オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `sun` | Boolean | ✓ | 日曜日 |
| `mon` | Boolean | ✓ | 月曜日 |
| `tue` | Boolean | ✓ | 火曜日 |
| `wed` | Boolean | ✓ | 水曜日 |
| `thu` | Boolean | ✓ | 木曜日 |
| `fri` | Boolean | ✓ | 金曜日 |
| `sat` | Boolean | ✓ | 土曜日 |

### バリデーションルール

- `timeframe`: 現在は "M1" のみサポート
- `maxPositionsTotal` >= `maxPositionsPerSymbol`
- `maxSpreadPips` >= 0
- `windows`: 少なくとも1つの時間帯が必要（enabled=trueの場合）
- `start` < `end` (各TimeWindow内)


## 3. ストラテジー (strategies)

ストラテジー配列は、複数のトレーディングストラテジーを定義します。各ストラテジーは独立して評価され、優先度に基づいて実行されます。

### スキーマ

```json
{
  "strategies": [
    {
      "id": "S1",
      "name": "Strategy 1",
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
              { "blockId": "trend.maRelation#1" },
              { "blockId": "trigger.bbReentry#1" }
            ]
          }
        ]
      },
      "lotModel": {
        "type": "lot.fixed",
        "params": { "lots": 0.1 }
      },
      "riskModel": {
        "type": "risk.fixedSLTP",
        "params": { "slPips": 30, "tpPips": 30 }
      },
      "exitModel": {
        "type": "exit.none",
        "params": {}
      },
      "nanpinModel": {
        "type": "nanpin.off",
        "params": {}
      }
    }
  ]
}
```

### Strategy オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `id` | String | ✓ | ストラテジーの一意識別子 |
| `name` | String | ✓ | ストラテジー名（表示用） |
| `enabled` | Boolean | ✓ | 有効/無効フラグ |
| `priority` | Integer | ✓ | 優先度（大きいほど優先） |
| `conflictPolicy` | String | ✓ | 競合解決ポリシー |
| `directionPolicy` | String | ✓ | 方向ポリシー |
| `entryRequirement` | Object | ✓ | エントリー要件（DNF形式） |
| `lotModel` | Object | ✓ | ロット計算モデル |
| `riskModel` | Object | ✓ | リスク管理モデル |
| `exitModel` | Object | ✓ | エグジットモデル |
| `nanpinModel` | Object | ✓ | ナンピンモデル |

### conflictPolicy の値

| 値 | 説明 |
|----|------|
| `firstOnly` | 最初にマッチしたストラテジーのみ実行（MVP既定） |
| `bestScore` | 最高スコアのストラテジーを実行（将来拡張） |
| `all` | すべてマッチしたストラテジーを実行（将来拡張） |

### directionPolicy の値

| 値 | 説明 |
|----|------|
| `both` | ロング・ショート両方可能 |
| `longOnly` | ロングのみ |
| `shortOnly` | ショートのみ |


## 4. エントリー要件 (entryRequirement)

エントリー要件は、DNF（選言標準形）形式で定義されます：OR(AND, AND, ...)

### スキーマ

```json
{
  "entryRequirement": {
    "type": "OR",
    "ruleGroups": [
      {
        "id": "RG1",
        "type": "AND",
        "conditions": [
          { "blockId": "filter.spreadMax#1" },
          { "blockId": "trend.maRelation#1" }
        ]
      }
    ]
  }
}
```

### entryRequirement オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `type` | String | ✓ | "OR" 固定（ルールグループ間はOR） |
| `ruleGroups` | Array<RuleGroup> | ✓ | ルールグループの配列 |

### RuleGroup オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `id` | String | ✓ | ルールグループの一意識別子 |
| `type` | String | ✓ | "AND" 固定（条件間はAND） |
| `conditions` | Array<Condition> | ✓ | 条件の配列 |

### Condition オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `blockId` | String | ✓ | 参照するブロックのID |

### バリデーションルール

- `ruleGroups`: 少なくとも1つのルールグループが必要
- `conditions`: 少なくとも1つの条件が必要
- `blockId`: blocks配列内に存在するIDを参照する必要がある


## 5. モデル定義

### 5.1 ロットモデル (lotModel)

ロット計算方法を定義します。

#### lot.fixed（固定ロット）

```json
{
  "type": "lot.fixed",
  "params": {
    "lots": 0.1
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `lots` | Number | ✓ | 固定ロット数 | > 0 |

#### lot.riskPercent（リスクパーセント）

```json
{
  "type": "lot.riskPercent",
  "params": {
    "riskPercent": 1.5,
    "minLot": 0.01,
    "maxLot": 0.5
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `riskPercent` | Number | ✓ | リスク率（%） | > 0 |
| `minLot` | Number | ✓ | 最小ロット | > 0 |
| `maxLot` | Number | ✓ | 最大ロット | >= minLot |

### 5.2 リスクモデル (riskModel)

ストップロス（SL）とテイクプロフィット（TP）の設定方法を定義します。

#### risk.fixedSLTP（固定SL/TP）

```json
{
  "type": "risk.fixedSLTP",
  "params": {
    "slPips": 30,
    "tpPips": 30
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `slPips` | Number | ✓ | ストップロス（pips） | > 0 |
| `tpPips` | Number | ✓ | テイクプロフィット（pips） | > 0 |

#### risk.atrBased（ATRベース）

```json
{
  "type": "risk.atrBased",
  "params": {
    "atrPeriod": 14,
    "buyTpRatio": 3.0,
    "buySlRatio": 1.5,
    "sellTpRatio": 3.0,
    "sellSlRatio": 1.5
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `atrPeriod` | Integer | ✓ | ATR期間 | > 0 |
| `buyTpRatio` | Number | ✓ | ロングTP倍率 | > 0 |
| `buySlRatio` | Number | ✓ | ロングSL倍率 | > 0 |
| `sellTpRatio` | Number | ✓ | ショートTP倍率 | > 0 |
| `sellSlRatio` | Number | ✓ | ショートSL倍率 | > 0 |


### 5.3 エグジットモデル (exitModel)

ポジションのエグジット条件を定義します。

#### exit.none（エグジットなし）

```json
{
  "type": "exit.none",
  "params": {}
}
```

SL/TPのみでエグジット（追加のエグジット条件なし）

#### exit.trail（トレーリングストップ）

```json
{
  "type": "exit.trail",
  "params": {
    "startPips": 30,
    "trailPips": 15
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `startPips` | Number | ✓ | トレール開始（pips） | > 0 |
| `trailPips` | Number | ✓ | トレール幅（pips） | > 0 |

#### exit.breakEven（建値移動）

```json
{
  "type": "exit.breakEven",
  "params": {
    "triggerPips": 15,
    "offsetPips": 3
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `triggerPips` | Number | ✓ | 建値移動トリガー（pips） | > 0 |
| `offsetPips` | Number | ✓ | 建値からのオフセット（pips） | >= 0 |

#### exit.weekendClose（週末決済）

```json
{
  "type": "exit.weekendClose",
  "params": {
    "dayOfWeek": 5,
    "closeTime": "23:00",
    "warningTime": "22:30"
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `dayOfWeek` | Integer | ✓ | 曜日（0=日, 5=金） | 0-6 |
| `closeTime` | String | ✓ | 決済時刻 | "HH:MM" |
| `warningTime` | String | ✓ | 警告時刻 | "HH:MM" |


### 5.4 ナンピンモデル (nanpinModel)

平均建値改善のための分割エントリーを定義します。

#### nanpin.off（ナンピンなし）

```json
{
  "type": "nanpin.off",
  "params": {}
}
```

ナンピン機能を使用しない

#### nanpin.fixed（固定間隔ナンピン）

```json
{
  "type": "nanpin.fixed",
  "params": {
    "intervalPips": 20,
    "maxCount": 2,
    "lotAdjustMethod": 2
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| `intervalPips` | Number | ✓ | ナンピン間隔（pips） | > 0 |
| `maxCount` | Integer | ✓ | 最大ナンピン回数 | > 0 |
| `lotAdjustMethod` | Integer | ✓ | ロット調整方法 | 0, 1, 2 |

**lotAdjustMethod の値:**
- `0`: 同じロット
- `1`: 倍ロット
- `2`: マーチンゲール（2倍、4倍、8倍...）

**重要:** ナンピンは必ず損切り（損失限定）を行う設計です。


## 6. ブロック (blocks)

ブロック配列は、ストラテジーで使用される判定・計算ブロックを定義します。各ブロックは副作用を持たず、純粋な判定・計算のみを行います。

### スキーマ

```json
{
  "blocks": [
    {
      "id": "filter.spreadMax#1",
      "typeId": "filter.spreadMax",
      "params": {
        "maxSpreadPips": 2.5
      }
    },
    {
      "id": "trend.maRelation#1",
      "typeId": "trend.maRelation",
      "params": {
        "period": 20,
        "maMethod": "SMA",
        "appliedPrice": "CLOSE",
        "relation": "above"
      }
    }
  ]
}
```

### Block オブジェクト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `id` | String | ✓ | ブロックの一意識別子 |
| `typeId` | String | ✓ | ブロックタイプID |
| `params` | Object | ✓ | ブロック固有のパラメータ |

### ブロックID命名規則

ブロックIDは以下の形式に従います：

```
<category>.<type>#<instance>
```

**例:**
- `filter.spreadMax#1`
- `trend.maRelation#1`
- `trigger.bbReentry#1`

**ルール:**
- カテゴリとタイプは `typeId` と一致する必要がある
- インスタンス番号（#の後）は同じtypeIdの複数インスタンスを区別する
- インスタンス番号は1から始まる整数

### バリデーションルール

- `id`: 設定ファイル内で一意である必要がある
- `id`: `<category>.<type>#<number>` の形式に従う必要がある
- `typeId`: block_catalog.json で定義されたタイプである必要がある
- `params`: typeIdに対応するparamsSchemaに従う必要がある


## 7. ブロックカテゴリとタイプ

### 7.1 フィルターブロック (filter.*)

スプレッド、ボラティリティ、セッションなどの基本的なフィルター条件

#### filter.spreadMax

```json
{
  "id": "filter.spreadMax#1",
  "typeId": "filter.spreadMax",
  "params": {
    "maxSpreadPips": 2.5
  }
}
```

#### filter.volatility.atrRange

```json
{
  "id": "filter.atrRange#1",
  "typeId": "filter.volatility.atrRange",
  "params": {
    "period": 14,
    "minAtr": 0.0003,
    "maxAtr": 0.005
  }
}
```

#### filter.volatility.stddevRange

```json
{
  "id": "filter.stddevRange#1",
  "typeId": "filter.volatility.stddevRange",
  "params": {
    "period": 20,
    "maPeriod": 20,
    "maMethod": "SMA",
    "appliedPrice": "CLOSE",
    "min": 0.00005,
    "max": 0.002
  }
}
```

#### filter.session.daysOfWeek

```json
{
  "id": "filter.daysOfWeek#1",
  "typeId": "filter.session.daysOfWeek",
  "params": {
    "days": [1, 2, 3, 4, 5]
  }
}
```

### 7.2 トレンドブロック (trend.*)

M1のみでトレンドを判定

#### trend.maRelation

```json
{
  "id": "trend.maRelation#1",
  "typeId": "trend.maRelation",
  "params": {
    "period": 20,
    "maType": "SMA",
    "relation": "closeAbove"
  }
}
```

**relation の値:**
- `closeAbove`: 終値がMAより上
- `closeBelow`: 終値がMAより下
- `above`: 価格がMAより上（旧形式、互換性のため残す）
- `below`: 価格がMAより下（旧形式、互換性のため残す）

#### trend.sarDirection

```json
{
  "id": "trend.sarDirection#1",
  "typeId": "trend.sarDirection",
  "params": {
    "step": 0.02,
    "maximum": 0.2,
    "direction": "bullish"
  }
}
```

**direction の値:**
- `bullish`: 上昇トレンド
- `bearish`: 下降トレンド


### 7.3 トリガーブロック (trigger.*)

エントリーのトリガー条件（押し目、回帰、ブレイクアウトなど）

#### trigger.bbReentry

```json
{
  "id": "trigger.bbReentry#1",
  "typeId": "trigger.bbReentry",
  "params": {
    "period": 20,
    "deviation": 2.0,
    "side": "lowerToInside"
  }
}
```

**side の値:**
- `lowerToInside`: 下バンド外から内側への回帰
- `upperToInside`: 上バンド外から内側への回帰

#### trigger.bbBreakout

```json
{
  "id": "trigger.bbBreakout#1",
  "typeId": "trigger.bbBreakout",
  "params": {
    "period": 20,
    "deviation": 2.0,
    "direction": "upper"
  }
}
```

**direction の値:**
- `upper`: 上バンドブレイクアウト
- `lower`: 下バンドブレイクアウト

#### trigger.rsiLevel

```json
{
  "id": "trigger.rsiLevel#1",
  "typeId": "trigger.rsiLevel",
  "params": {
    "period": 14,
    "level": 30,
    "direction": "crossAbove"
  }
}
```

**direction の値:**
- `crossAbove`: レベルを下から上にクロス
- `crossBelow`: レベルを上から下にクロス

#### trigger.cciLevel

```json
{
  "id": "trigger.cciLevel#1",
  "typeId": "trigger.cciLevel",
  "params": {
    "period": 14,
    "appliedPrice": "TYPICAL",
    "threshold": -100,
    "mode": "oversold"
  }
}
```

**mode の値:**
- `oversold`: 売られ過ぎ（閾値を下から上にクロス）
- `overbought`: 買われ過ぎ（閾値を上から下にクロス）

#### trigger.wprLevel

```json
{
  "id": "trigger.wprLevel#1",
  "typeId": "trigger.wprLevel",
  "params": {
    "period": 14,
    "threshold": -80,
    "mode": "oversold"
  }
}
```

#### trigger.mfiLevel

```json
{
  "id": "trigger.mfiLevel#1",
  "typeId": "trigger.mfiLevel",
  "params": {
    "period": 14,
    "appliedVolume": "TICK",
    "threshold": 20,
    "mode": "oversold"
  }
}
```

#### trigger.sarFlip

```json
{
  "id": "trigger.sarFlip#1",
  "typeId": "trigger.sarFlip",
  "params": {
    "step": 0.02,
    "maximum": 0.2
  }
}
```

#### trigger.rviCross

```json
{
  "id": "trigger.rviCross#1",
  "typeId": "trigger.rviCross",
  "params": {
    "period": 10,
    "direction": "golden"
  }
}
```

**direction の値:**
- `golden`: ゴールデンクロス（RVIがシグナルを上抜け）
- `dead`: デッドクロス（RVIがシグナルを下抜け）


### 7.4 Bill Williamsブロック (bill.*)

Bill Williams指標に基づくブロック

#### bill.alligator

```json
{
  "id": "bill.alligator#1",
  "typeId": "bill.alligator",
  "params": {
    "jawPeriod": 13,
    "jawShift": 8,
    "teethPeriod": 8,
    "teethShift": 5,
    "lipsPeriod": 5,
    "lipsShift": 3,
    "maMethod": "SMMA",
    "appliedPrice": "MEDIAN",
    "position": "above"
  }
}
```

**position の値:**
- `above`: 価格がアリゲーターより上
- `below`: 価格がアリゲーターより下

#### bill.fractals

```json
{
  "id": "bill.fractals#1",
  "typeId": "bill.fractals",
  "params": {
    "direction": "up"
  }
}
```

**direction の値:**
- `up`: 上向きフラクタル
- `down`: 下向きフラクタル

### 7.5 オシレーターブロック (osc.*)

モメンタム、MACD、OSMAなどのオシレーター

#### osc.momentum

```json
{
  "id": "osc.momentum#1",
  "typeId": "osc.momentum",
  "params": {
    "period": 14,
    "appliedPrice": "CLOSE",
    "comparison": "above",
    "threshold": 100
  }
}
```

**comparison の値:**
- `above`: 閾値より上
- `below`: 閾値より下

#### osc.osma

```json
{
  "id": "osc.osma#1",
  "typeId": "osc.osma",
  "params": {
    "fastEma": 12,
    "slowEma": 26,
    "signal": 9,
    "appliedPrice": "CLOSE",
    "comparison": "above",
    "threshold": 0
  }
}
```


## 8. バックテスト統合のための拡張

このスキーマは、GUIビルダー、EA（MQL5）、およびPythonバックテストエンジンの3つのコンポーネントで共有されます。バックテスト機能のために、以下の拡張が考慮されています。

### 8.1 バックテスト実行パラメータ

バックテスト実行時には、設定ファイルとは別に以下のパラメータが必要です：

```json
{
  "symbol": "USDJPY",
  "timeframe": "M1",
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-03-31T23:59:59Z"
}
```

これらのパラメータは設定ファイルには含まれず、バックテスト実行時にコマンドライン引数またはGUIから指定されます。

### 8.2 バックテスト結果フォーマット

バックテスト結果は以下のフォーマットで出力されます：

```json
{
  "metadata": {
    "strategyName": "My Strategy",
    "symbol": "USDJPY",
    "timeframe": "M1",
    "startDate": "2024-01-01T00:00:00Z",
    "endDate": "2024-03-31T23:59:59Z",
    "executionTimestamp": "2024-04-01T10:30:00Z"
  },
  "summary": {
    "totalTrades": 150,
    "winningTrades": 90,
    "losingTrades": 60,
    "winRate": 60.0,
    "totalProfitLoss": 125.50,
    "maxDrawdown": 45.20,
    "avgTradeProfitLoss": 0.84
  },
  "trades": [
    {
      "entryTime": "2024-01-01T10:00:00Z",
      "entryPrice": 145.123,
      "exitTime": "2024-01-01T10:15:00Z",
      "exitPrice": 145.156,
      "positionSize": 1.0,
      "profitLoss": 0.033,
      "type": "BUY"
    }
  ]
}
```

### 8.3 設定ファイルの互換性

バックテストエンジンは、このスキーマに準拠したすべての設定ファイルを読み込むことができます。ただし、以下の制限があります：

1. **簡易シミュレーション**: 初期実装では、すべてのブロックタイプが完全にサポートされるわけではありません
2. **基本ブロックのみ**: MVP段階では、filter.spreadMax、trend.maRelation、trigger.bbReentryなどの基本ブロックのみサポート
3. **拡張性**: 将来的には、すべてのブロックタイプをサポートする予定


## 9. 完全な設定例

以下は、すべての要素を含む完全な設定ファイルの例です：

```json
{
  "meta": {
    "formatVersion": "1.0",
    "name": "Multi-Strategy Example",
    "generatedBy": "GUI Builder",
    "generatedAt": "2026-01-26T10:30:00Z",
    "description": "Example configuration with multiple strategies",
    "author": "Strategy Bricks Team"
  },
  "globalGuards": {
    "timeframe": "M1",
    "useClosedBarOnly": true,
    "noReentrySameBar": true,
    "maxPositionsTotal": 3,
    "maxPositionsPerSymbol": 2,
    "maxSpreadPips": 2.5,
    "session": {
      "enabled": true,
      "windows": [
        { "start": "00:00", "end": "23:59" }
      ],
      "weekDays": {
        "sun": false,
        "mon": true,
        "tue": true,
        "wed": true,
        "thu": true,
        "fri": true,
        "sat": false
      }
    }
  },
  "strategies": [
    {
      "id": "S1",
      "name": "Trend Following Strategy",
      "enabled": true,
      "priority": 10,
      "conflictPolicy": "firstOnly",
      "directionPolicy": "both",
      "entryRequirement": {
        "type": "OR",
        "ruleGroups": [
          {
            "id": "RG1_Long",
            "type": "AND",
            "conditions": [
              { "blockId": "filter.spreadMax#1" },
              { "blockId": "trend.maRelation#1" },
              { "blockId": "trigger.bbReentry#1" }
            ]
          },
          {
            "id": "RG2_Short",
            "type": "AND",
            "conditions": [
              { "blockId": "filter.spreadMax#1" },
              { "blockId": "trend.maRelation#2" },
              { "blockId": "trigger.bbReentry#2" }
            ]
          }
        ]
      },
      "lotModel": {
        "type": "lot.fixed",
        "params": { "lots": 0.1 }
      },
      "riskModel": {
        "type": "risk.fixedSLTP",
        "params": { "slPips": 30, "tpPips": 30 }
      },
      "exitModel": {
        "type": "exit.trail",
        "params": { "startPips": 20, "trailPips": 10 }
      },
      "nanpinModel": {
        "type": "nanpin.off",
        "params": {}
      }
    }
  ],
  "blocks": [
    {
      "id": "filter.spreadMax#1",
      "typeId": "filter.spreadMax",
      "params": { "maxSpreadPips": 2.5 }
    },
    {
      "id": "trend.maRelation#1",
      "typeId": "trend.maRelation",
      "params": {
        "period": 20,
        "maType": "SMA",
        "relation": "closeAbove"
      }
    },
    {
      "id": "trend.maRelation#2",
      "typeId": "trend.maRelation",
      "params": {
        "period": 20,
        "maType": "SMA",
        "relation": "closeBelow"
      }
    },
    {
      "id": "trigger.bbReentry#1",
      "typeId": "trigger.bbReentry",
      "params": {
        "period": 20,
        "deviation": 2.0,
        "side": "lowerToInside"
      }
    },
    {
      "id": "trigger.bbReentry#2",
      "typeId": "trigger.bbReentry",
      "params": {
        "period": 20,
        "deviation": 2.0,
        "side": "upperToInside"
      }
    }
  ]
}
```


## 10. バリデーションチェックリスト

設定ファイルを検証する際は、以下の項目を確認してください：

### 10.1 必須フィールド

- [ ] `meta.formatVersion` が存在し、"1.0" である
- [ ] `meta.name` が存在し、1文字以上である
- [ ] `meta.generatedBy` が存在する
- [ ] `meta.generatedAt` が存在し、ISO 8601形式である
- [ ] `globalGuards` が存在し、すべての必須フィールドを含む
- [ ] `strategies` 配列が存在し、少なくとも1つのストラテジーを含む
- [ ] `blocks` 配列が存在する

### 10.2 グローバルガード

- [ ] `timeframe` が "M1" である
- [ ] `useClosedBarOnly` が true である
- [ ] `noReentrySameBar` が true である
- [ ] `maxPositionsTotal` >= `maxPositionsPerSymbol`
- [ ] `maxSpreadPips` >= 0
- [ ] `session.enabled` が true の場合、少なくとも1つの `windows` が存在する

### 10.3 ストラテジー

- [ ] 各ストラテジーの `id` が一意である
- [ ] 各ストラテジーの `priority` が整数である
- [ ] `conflictPolicy` が有効な値である（"firstOnly", "bestScore", "all"）
- [ ] `directionPolicy` が有効な値である（"both", "longOnly", "shortOnly"）
- [ ] `entryRequirement.type` が "OR" である
- [ ] 少なくとも1つの `ruleGroups` が存在する
- [ ] 各 `ruleGroup.type` が "AND" である
- [ ] 各 `ruleGroup` に少なくとも1つの `conditions` が存在する

### 10.4 ブロック

- [ ] 各ブロックの `id` が一意である
- [ ] 各ブロックの `id` が `<category>.<type>#<number>` の形式に従う
- [ ] 各ブロックの `typeId` が有効なブロックタイプである
- [ ] 各ブロックの `params` が typeId に対応するスキーマに従う
- [ ] ストラテジーで参照されているすべての `blockId` が `blocks` 配列に存在する

### 10.5 モデル

- [ ] `lotModel.type` が有効な値である
- [ ] `riskModel.type` が有効な値である
- [ ] `exitModel.type` が有効な値である
- [ ] `nanpinModel.type` が有効な値である
- [ ] 各モデルの `params` が type に対応するスキーマに従う


## 11. 拡張性とバージョニング

### 11.1 将来のバージョン

このスキーマは拡張可能に設計されています。将来のバージョンでは以下の拡張が予定されています：

1. **新しいブロックタイプ**: 新しいカテゴリやタイプのブロックを追加
2. **新しいモデルタイプ**: 新しいlot/risk/exit/nanpinモデルを追加
3. **新しいconflictPolicy**: "bestScore", "all" などの実装
4. **スコアリングシステム**: ブロックやストラテジーのスコアリング機能
5. **条件演算子の拡張**: NOT, KofN などの論理演算子
6. **上位足サポート**: M1以外の時間軸のサポート（将来的に）

### 11.2 後方互換性

新しいバージョンのスキーマは、以下の原則に従って後方互換性を維持します：

1. **必須フィールドの追加禁止**: 既存の必須フィールドは削除せず、新しい必須フィールドは追加しない
2. **オプションフィールドの追加**: 新しい機能はオプションフィールドとして追加
3. **デフォルト値の提供**: 新しいオプションフィールドには適切なデフォルト値を提供
4. **formatVersionチェック**: EAとバックテストエンジンは formatVersion をチェックし、非対応バージョンを拒否

### 11.3 バージョン管理戦略

```
formatVersion: "1.0"  - 初期バージョン（MVP）
formatVersion: "1.1"  - マイナーアップデート（後方互換性あり）
formatVersion: "2.0"  - メジャーアップデート（破壊的変更の可能性）
```

## 12. 参考資料

### 12.1 関連ドキュメント

- `docs/03_design/30_config_spec.md` - 詳細な設定仕様
- `docs/03_design/40_block_catalog_spec.md` - ブロックカタログ仕様
- `docs/00_overview.md` - プロジェクト概要と設計方針
- `.kiro/specs/gui-backtest-integration/requirements.md` - バックテスト統合要件
- `.kiro/specs/gui-backtest-integration/design.md` - バックテスト統合設計

### 12.2 実装ガイドライン

- **EA実装**: MQL5でこのスキーマを読み込み、ブロックを評価し、ストラテジーを実行
- **GUI実装**: Electronでこのスキーマに準拠した設定ファイルを生成
- **バックテスト実装**: Pythonでこのスキーマを読み込み、過去データでシミュレーション

### 12.3 サポート

質問や問題がある場合は、プロジェクトドキュメントを参照するか、開発チームに連絡してください。

---

**ドキュメントバージョン**: 1.0  
**最終更新日**: 2026-01-26  
**作成者**: Strategy Bricks Development Team

