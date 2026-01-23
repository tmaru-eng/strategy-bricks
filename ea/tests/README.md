# Strategy Bricks EA Tests

## テスト用設定ファイル

### active.json

テスト用の設定ファイルです。以下の配置先にコピーしてください：

```
MQL5/Files/strategy/active.json
```

### 設定内容

- **Strategy**: M1 Pullback Basic
- **ロング条件** (RG1_Long):
  - スプレッド <= 2.0 pips
  - セッション時間内
  - 終値 > EMA(200)
  - BB下限からの回帰
- **ショート条件** (RG2_Short):
  - スプレッド <= 2.0 pips
  - セッション時間内
  - 終値 < EMA(200)
  - BB上限からの回帰
- **ロット**: 0.1（固定）
- **SL/TP**: 30 pips / 30 pips

## MT5 Strategy Tester設定

1. **モード**: Every tick
2. **期間**: 2024-01-01 ~ 2024-01-31
3. **シンボル**: USDJPY
4. **時間足**: M1

## 受入基準チェックリスト

- [ ] **AC-01**: `BAR_EVAL_START`が1分間隔で出力される
- [ ] **AC-02**: 同一足再エントリーで`ORDER_REJECT`が出力される
- [ ] **AC-03**: OR/AND短絡評価が正しく動作する
- [ ] **AC-07**: formatVersion非互換でINIT_FAILED
- [ ] **AC-10**: ブロック判定理由がログに残る
- [ ] **AC-11**: 発注失敗理由がログに残る

## ログファイル

ログは以下の場所に出力されます：

```
MQL5/Files/strategy/logs/strategy_YYYYMMDD.jsonl
```

## フォルダ構成

```
MQL5/
├── Experts/
│   └── StrategyBricks/
│       └── StrategyBricks.mq5  # コンパイル後に配置
├── Include/
│   └── StrategyBricks/         # include/*.mqh をコピー
└── Files/
    └── strategy/
        ├── active.json          # 設定ファイル
        └── logs/                # ログ出力先
```

## コンパイル方法

1. MetaEditorを開く
2. `ea/src/StrategyBricks.mq5`を開く
3. F7でコンパイル
4. エラーがないことを確認

## 注意事項

- **M1固定**: 他の時間足では動作しません
- **確定足基準**: shift=1のデータを使用
- **同一足再エントリー禁止**: 二重ガードで保護
