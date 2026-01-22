# EA Runtime（MQL5）

MT5上で動作するExpert Advisor（EA）の実装です。

## ディレクトリ構造

```
ea/
├── src/              # ソースコード（.mq5ファイル）
│   ├── StrategyBricks.mq5        # メインEAファイル
│   ├── Config/                   # 設定関連
│   ├── Core/                     # コアロジック
│   ├── Blocks/                   # ブロック実装
│   ├── Indicators/               # インジケータキャッシュ
│   ├── Execution/                # 発注・管理
│   └── Utils/                    # ユーティリティ
└── include/          # ヘッダファイル（.mqhファイル）
    ├── Common.mqh                # 共通定義
    ├── Interfaces.mqh            # インターフェース定義
    └── Structs.mqh               # 構造体定義
```

## 実装状況

**現在の状態**: 未実装（Phase 0完了後に開始予定）

**次のステップ**:
1. プロトタイプ検証（Phase 0）
2. コア実装（Phase 1）

## 設計ドキュメント

**必読**:
- `docs/03_design/45_interface_contracts.md` - インターフェース契約書
- `docs/03_design/50_ea_runtime_design.md` - EA Runtime詳細設計

**参照**:
- `docs/03_design/30_config_spec.md` - 設定ファイル仕様
- `docs/03_design/40_block_catalog_spec.md` - ブロックカタログ仕様

## 開発環境

**必要なツール**:
- MetaTrader 5（MT5）
- MetaEditor（MT5付属）

**コンパイル**:
```
MetaEditorでStrategyBricks.mq5を開き、Compileボタンを押す
```

**テスト**:
- Strategy Tester（MT5付属）を使用

## 重要な実装ルール

1. **shift=1（確定足）の使用を徹底**
   - shift=0（未確定足）の使用は原則禁止
2. **ブロックは副作用なし**
   - 判定・計算のみ
   - OrderSend()等の直接呼び出し禁止
3. **IndicatorCache経由でインジケータ取得**
   - 直接iMA()等を呼ばない
4. **ログ出力の徹底**
   - すべての判定・発注・拒否理由をログに残す

詳細: `docs/03_design/50_ea_runtime_design.md`

---

**最終更新**: 2026-01-22
