# 01_proposal/02_concept_deck.md
# コンセプトデッキ — Strategy Bricks（仮称）

## 0. ドキュメント情報
- ファイル名：`docs/01_proposal/02_concept_deck.md`
- 版：v0.1
- 対象：意思決定者、協力者、ステークホルダー
- 目的：視覚的な企画説明資料として全体像を短時間で理解可能にする

---

## 1. プロジェクト概要

### 1.1 What（何を作るか）

**Strategy Bricks（仮称）**

MT5で動く戦略自動売買システム。ブロック（レゴ）を組み合わせてGUIで戦略を構築し、EAが実行します。

**主要コンポーネント:**
- **Electron Strategy Builder（GUI）**: ブロックを組み合わせて戦略構築
- **MT5 EA Runtime**: JSON設定を読み込んで自動売買実行
- **JSON契約**: strategy_config.json（設定ファイル）

---

## 2. 全体アーキテクチャ図

```mermaid
flowchart TB
    subgraph "1. 設計フェーズ（ユーザー操作）"
        USER[ユーザー]
        BUILDER[Electron Strategy Builder]
        CAT[block_catalog.json<br/>ブロック定義]
    end

    subgraph "2. 設定生成"
        PROF[profiles/name.json<br/>保存用設定]
        ACT[active.json<br/>実行用設定]
    end

    subgraph "3. 実行フェーズ（自動）"
        EA[MT5 EA Runtime]
        MKT[Market/Broker]
    end

    subgraph "4. 観測"
        LOG[Logs<br/>ログファイル]
        RPT[Reports<br/>バックテスト結果]
    end

    USER -->|ブロック配置・編集| BUILDER
    CAT -->|読込| BUILDER
    BUILDER -->|Export| PROF
    BUILDER -->|Export| ACT

    ACT -->|読込| EA
    EA -->|発注・決済| MKT
    EA -->|ログ出力| LOG
    EA -->|結果| RPT

    LOG -->|確認| USER
    RPT -->|確認| USER

    style BUILDER fill:#e1ffe1
    style EA fill:#ffe1e1
    style ACT fill:#fff5e1
```

---

## 3. ユーザーフロー

```mermaid
flowchart LR
    START([開始])
    PALETTE[1. パレットから<br/>ブロック選択]
    CANVAS[2. Canvasに配置<br/>OR/AND構成]
    PARAM[3. パラメータ編集<br/>PropertyPanel]
    VAL[4. Validate<br/>エラーチェック]
    EXP[5. Export<br/>active.json生成]
    EA_START[6. EA起動<br/>MT5]
    TRADE[7. 自動売買実行]
    LOG_CHK[8. ログ確認<br/>改善]
    END([終了])

    START --> PALETTE
    PALETTE --> CANVAS
    CANVAS --> PARAM
    PARAM --> VAL
    VAL -->|エラーあり| PARAM
    VAL -->|OK| EXP
    EXP --> EA_START
    EA_START --> TRADE
    TRADE --> LOG_CHK
    LOG_CHK -->|調整| PARAM
    LOG_CHK --> END

    style CANVAS fill:#e1f5ff
    style VAL fill:#ffe1e1
    style TRADE fill:#e1ffe1
```

---

## 4. ルール構造図（OR枠×AND内）

### 4.1 DNF形式の視覚化

```mermaid
flowchart TB
    subgraph "Strategy: M1 Pullback"
        direction TB

        subgraph "EntryRequirement（OR）"
            RG1[RuleGroup #1<br/>強気押し目]
            RG2[RuleGroup #2<br/>弱気押し目]
        end

        subgraph "RuleGroup #1（AND）"
            F1[Filter: Spread ≤ 2.0 pips]
            E1[Env: Session 7:00-15:00]
            T1[Trend: Close > MA200]
            TR1[Trigger: BB外→内回帰]

            F1 --> E1
            E1 --> T1
            T1 --> TR1
        end

        subgraph "RuleGroup #2（AND）"
            F2[Filter: Spread ≤ 2.0 pips]
            E2[Env: Session 15:03-03:00]
            T2[Trend: Close < MA200]
            TR2[Trigger: BB外→内回帰]

            F2 --> E2
            E2 --> T2
            T2 --> TR2
        end

        ENTRY[エントリー候補]
    end

    RG1 -->|成立| ENTRY
    RG2 -->|成立| ENTRY

    style RG1 fill:#ffe1e1
    style RG2 fill:#e1f5ff
    style ENTRY fill:#e1ffe1
```

### 4.2 短絡評価の仕組み

```mermaid
flowchart LR
    START([評価開始])
    RG1{RuleGroup #1}
    RG2{RuleGroup #2}
    RG3{RuleGroup #3}
    ADOPT[採用]
    REJECT[見送り]

    START --> RG1
    RG1 -->|成立| ADOPT
    RG1 -->|不成立| RG2
    RG2 -->|成立| ADOPT
    RG2 -->|不成立| RG3
    RG3 -->|成立| ADOPT
    RG3 -->|不成立| REJECT

    style ADOPT fill:#e1ffe1
    style REJECT fill:#ffe1e1
```

---

## 5. 競合解決（priority + firstOnly）

### 5.1 複数戦略の評価順序

```mermaid
flowchart TB
    START([M1新バー])
    SORT[Strategy を priority 降順でソート]

    S1{Strategy #1<br/>priority=10}
    S2{Strategy #2<br/>priority=5}
    S3{Strategy #3<br/>priority=3}

    ENTRY1[エントリー<br/>Strategy #1]
    ENTRY2[エントリー<br/>Strategy #2]
    ENTRY3[エントリー<br/>Strategy #3]
    NO_ENTRY[見送り]

    START --> SORT
    SORT --> S1

    S1 -->|成立| ENTRY1
    S1 -->|不成立| S2

    S2 -->|成立| ENTRY2
    S2 -->|不成立| S3

    S3 -->|成立| ENTRY3
    S3 -->|不成立| NO_ENTRY

    style ENTRY1 fill:#e1ffe1
    style ENTRY2 fill:#e1ffe1
    style ENTRY3 fill:#e1ffe1
    style NO_ENTRY fill:#ffe1e1
```

### 5.2 conflictPolicy: firstOnly

```mermaid
flowchart LR
    S1[Strategy #1]
    S2[Strategy #2]
    S3[Strategy #3]
    ENTRY[エントリー]
    SKIP[スキップ]

    S1 -->|成立| ENTRY
    ENTRY -->|firstOnly| SKIP
    S2 -.不評価.-> SKIP
    S3 -.不評価.-> SKIP

    style ENTRY fill:#e1ffe1
    style SKIP fill:#ffe1e1
```

---

## 6. ナンピンモードの位置づけ

### 6.1 ナンピン戦略の流れ

```mermaid
flowchart TB
    ENTRY1[初回エントリー]
    CHECK1{価格逆行？<br/>+追加条件}
    ENTRY2[2回目エントリー<br/>平均建値改善]
    CHECK2{最大段数？}
    ENTRY3[3回目エントリー]
    MAX_CHECK{平均建値+α<br/>到達？}
    BE_CLOSE[平均建値で<br/>全決済]
    SERIES_CHECK{累積損失<br/>> 閾値？}
    SERIES_CUT[シリーズ損切り<br/>全決済]
    NORMAL[通常管理<br/>SL/TP]

    ENTRY1 --> CHECK1
    CHECK1 -->|Yes| ENTRY2
    CHECK1 -->|No| NORMAL

    ENTRY2 --> CHECK2
    CHECK2 -->|No| CHECK1
    CHECK2 -->|Yes| ENTRY3

    ENTRY3 --> MAX_CHECK
    MAX_CHECK -->|Yes| BE_CLOSE
    MAX_CHECK -->|No| SERIES_CHECK

    SERIES_CHECK -->|Yes| SERIES_CUT
    SERIES_CHECK -->|No| NORMAL

    style ENTRY1 fill:#e1ffe1
    style ENTRY2 fill:#e1f5ff
    style ENTRY3 fill:#e1f5ff
    style BE_CLOSE fill:#fff5e1
    style SERIES_CUT fill:#ffe1e1
```

### 6.2 ナンピン安全装置

```mermaid
flowchart TB
    subgraph "安全装置"
        MAX_COUNT[最大段数制限<br/>例: 3回まで]
        SERIES_SL[シリーズ損切り<br/>累積損失 > 閾値]
        BE_AT_MAX[最大時BE決済<br/>平均建値+α]
        ADD_COND[追加条件<br/>逆行幅/ATR倍率]
    end

    subgraph "リスク"
        RISK1[無限ナンピン]
        RISK2[累積損失拡大]
        RISK3[ポジション増加]
    end

    MAX_COUNT -->|防止| RISK1
    SERIES_SL -->|防止| RISK2
    BE_AT_MAX -->|防止| RISK3
    ADD_COND -->|緩和| RISK2

    style MAX_COUNT fill:#e1ffe1
    style SERIES_SL fill:#e1ffe1
    style BE_AT_MAX fill:#e1ffe1
    style RISK1 fill:#ffe1e1
    style RISK2 fill:#ffe1e1
    style RISK3 fill:#ffe1e1
```

---

## 7. 価値提案の図解

### 7.1 従来の課題

```mermaid
flowchart TB
    subgraph "従来のEA開発"
        CODE[コード直接編集]
        COMPILE[コンパイル]
        TEST[テスト]
        DEBUG[デバッグ]
        DEPLOY[デプロイ]

        CODE --> COMPILE
        COMPILE -->|エラー| CODE
        COMPILE -->|OK| TEST
        TEST -->|失敗| DEBUG
        DEBUG --> CODE
        TEST -->|OK| DEPLOY
    end

    subgraph "課題"
        C1[条件追加が困難]
        C2[保守コスト高]
        C3[属人化]
        C4[検証が難しい]
    end

    CODE -.-> C1
    COMPILE -.-> C2
    DEBUG -.-> C3
    TEST -.-> C4

    style C1 fill:#ffe1e1
    style C2 fill:#ffe1e1
    style C3 fill:#ffe1e1
    style C4 fill:#ffe1e1
```

### 7.2 Strategy Bricksの価値

```mermaid
flowchart TB
    subgraph "Strategy Bricks"
        GUI[GUIでブロック配置]
        VAL[自動検証]
        EXP[JSON生成]
        EA[EA自動実行]
        LOG[ログで追跡]

        GUI --> VAL
        VAL --> EXP
        EXP --> EA
        EA --> LOG
    end

    subgraph "価値"
        V1[ノーコードで戦略構築]
        V2[変更が局所的<br/>保守容易]
        V3[再利用可能<br/>テンプレート]
        V4[ログで検証<br/>改善サイクル高速]
    end

    GUI -.-> V1
    VAL -.-> V2
    EXP -.-> V3
    LOG -.-> V4

    style V1 fill:#e1ffe1
    style V2 fill:#e1ffe1
    style V3 fill:#e1ffe1
    style V4 fill:#e1ffe1
```

---

## 8. 開発フェーズのロードマップ

```mermaid
gantt
    title Strategy Bricks 開発ロードマップ
    dateFormat YYYY-MM-DD
    section Phase 0
    契約確定（Config/Block Catalog） :p0, 2024-02-01, 14d
    インターフェース文書化 :p0-2, 2024-02-08, 7d

    section Phase 1
    EA Runtime MVP :p1, 2024-02-15, 21d
    Engine/Evaluator/Cache骨格 :p1-1, 2024-02-15, 14d
    MVPブロック実装 :p1-2, 2024-02-22, 14d
    ログ出力実装 :p1-3, 2024-02-29, 7d

    section Phase 2
    GUI Builder MVP :p2, 2024-03-01, 21d
    Palette/Canvas/Property実装 :p2-1, 2024-03-01, 14d
    Validate/Export実装 :p2-2, 2024-03-08, 14d

    section Phase 3
    統合検証 :p3, 2024-03-15, 14d
    GUI→EA連携 :p3-1, 2024-03-15, 7d
    バックテスト検証 :p3-2, 2024-03-22, 7d

    section Phase 4
    安全装置・運用強化 :p4, 2024-03-29, 14d
    リスクガード実装 :p4-1, 2024-03-29, 7d
    ナンピン安全装置実装 :p4-2, 2024-04-05, 7d
```

---

## 9. MVPスコープ

### 9.1 MVP必須機能

```mermaid
flowchart TB
    subgraph "MVP（最小実用）"
        direction LR

        subgraph "Builder"
            B1[ブロック配置]
            B2[OR/AND編集]
            B3[パラメータ編集]
            B4[Validate]
            B5[Export]
        end

        subgraph "EA"
            E1[設定読込]
            E2[新バー評価<br/>M1のみ]
            E3[OR/AND短絡評価]
            E4[同一足禁止]
            E5[基本発注]
        end

        subgraph "Blocks（MVP）"
            BL1[filter.spreadMax]
            BL2[env.session]
            BL3[trend.maRelation]
            BL4[trigger.bbReentry]
            BL5[lot.fixed]
            BL6[risk.fixedSLTP]
        end

        subgraph "管理"
            M1[ポジション制限]
            M2[ログ出力]
        end
    end

    B1 --> B2
    B2 --> B3
    B3 --> B4
    B4 --> B5

    E1 --> E2
    E2 --> E3
    E3 --> E4
    E4 --> E5

    style B4 fill:#ffe1e1
    style E3 fill:#e1f5ff
    style M2 fill:#e1ffe1
```

### 9.2 拡張機能（MVP後）

```mermaid
flowchart TB
    subgraph "拡張（段階的追加）"
        direction LR

        subgraph "Blocks拡張"
            X1[多様なトレンド判定<br/>ADX/Structure等]
            X2[多様なトリガー<br/>pullback/breakout等]
            X3[ロットモデル<br/>資金割合/モンテカルロ等]
        end

        subgraph "ナンピン"
            N1[ナンピンモード高度化]
            N2[シリーズ損切り]
            N3[平均建値決済]
        end

        subgraph "管理拡張"
            A1[トレーリング]
            A2[建値移動]
            A3[週末決済]
            A4[緊急停止]
        end

        subgraph "GUI拡張"
            G1[テンプレート機能]
            G2[Undo/Redo]
            G3[プレビュー]
        end
    end

    style X1 fill:#e1f5ff
    style N1 fill:#ffe1e1
    style A1 fill:#e1ffe1
    style G1 fill:#fff5e1
```

---

## 10. リスクと対策

### 10.1 主要リスク

```mermaid
flowchart LR
    subgraph "リスク"
        R1[過最適化<br/>バックテストで好成績<br/>フォワードで失敗]
        R2[計算負荷増<br/>インジケータ重複計算]
        R3[運用事故<br/>連打/ナンピン暴走]
    end

    subgraph "対策"
        S1[テンプレと検証手順<br/>ログ、受入基準明確化]
        S2[IndicatorCache<br/>確定足評価で頻度制御]
        S3[ガード<br/>最大ポジ/総ロット<br/>スプレッド停止<br/>クールダウン<br/>シリーズ損切り]
    end

    R1 --> S1
    R2 --> S2
    R3 --> S3

    style R1 fill:#ffe1e1
    style R2 fill:#ffe1e1
    style R3 fill:#ffe1e1
    style S1 fill:#e1ffe1
    style S2 fill:#e1ffe1
    style S3 fill:#e1ffe1
```

---

## 11. 成果物（アウトプット）

```mermaid
flowchart TB
    subgraph "デリバリー"
        D1[Electron Strategy Builder<br/>アプリケーション]
        D2[MT5 EA Runtime<br/>StrategyBricks.ex5]
        D3[block_catalog.json<br/>ブロック定義]
        D4[strategy_config.json<br/>設定スキーマ]
        D5[テンプレ戦略セット<br/>複数]
        D6[ドキュメント一式<br/>企画/要件/設計/運用]
    end

    subgraph "ユーザー取得物"
        U1[戦略自動売買システム]
        U2[ノーコードで戦略構築]
        U3[再利用可能テンプレート]
        U4[ログで検証・改善]
    end

    D1 --> U1
    D2 --> U1
    D3 --> U2
    D4 --> U2
    D5 --> U3
    D6 --> U4

    style D1 fill:#e1ffe1
    style D2 fill:#e1ffe1
    style U1 fill:#fff5e1
    style U2 fill:#fff5e1
```

---

## 12. まとめ

### 12.1 Strategy Bricksの特徴

**1. ブロックベース設計:**
- 判定・計算はブロック化（副作用なし）
- ドラッグ＆ドロップで戦略構築
- 再利用可能、拡張容易

**2. DNF形式（OR枠×AND内）:**
- 複数の条件セットを柔軟に組み合わせ
- 短絡評価で効率的

**3. 設定駆動:**
- JSONで戦略を定義
- GUIで編集、EAが実行
- 実装とロジックの分離

**4. 観測性:**
- すべての判定・発注をログ出力
- "なぜ入った/入らなかった"を追跡可能
- 改善サイクル高速化

**5. 安全装置:**
- ポジション制限、ロット制限
- スプレッド停止、クールダウン
- ナンピン安全装置（段数制限、シリーズ損切り、BE決済）

### 12.2 ターゲットユーザー

**初心者トレーダー:**
- テンプレートから開始
- パラメータ調整のみ

**中級トレーダー:**
- ブロックを組み合わせて戦略構築
- バックテストで検証
- ログ確認して改善

**上級トレーダー:**
- 複雑な戦略を構築
- ナンピン戦略も活用
- 複数戦略を組み合わせて運用

### 12.3 次のステップ

**Phase 0（契約確定）:**
- strategy_config.json v1 スキーマ確定
- block_catalog.json スキーマ確定
- 主要インターフェース文書化

**Phase 1（EA Runtime MVP）:**
- Engine/Evaluator/Cache/Executor骨格実装
- MVPブロック実装
- ログ出力実装

**Phase 2（GUI Builder MVP）:**
- Palette/Canvas/Property/Validate/Export実装

**Phase 3（統合検証）:**
- GUI→EA連携
- バックテスト検証

---

## 13. 参照ドキュメント

本コンセプトデッキは以下のドキュメントを基に作成されています:

- `docs/00_overview.md` - 合意事項・前提条件
- `docs/01_proposal/01_project_brief.md` - 企画資料
- `docs/02_requirements/10_requirements.md` - 要件定義書
- `docs/03_design/20_architecture.md` - アーキテクチャ設計
- `docs/05_development_plan/10_development_plan.md` - 開発計画

詳細は各ドキュメントを参照してください。

---
