# 03_design/45_interface_contracts.md
# インターフェース契約書 — Strategy Bricks（仮称）

## 0. ドキュメント情報
- ファイル名：`docs/03_design/45_interface_contracts.md`
- 版：v1.0
- 対象：EA実装担当・GUI実装担当（AIエージェント含む）
- 目的：EA/GUI間の完全なインターフェース定義により、実装の一致を保証

---

## 1. 概要と目的

このドキュメントは、Strategy BricksのEA Runtime実装におけるすべてのインターフェース（構造体、クラス、関数シグネチャ）を完全に定義します。

### 1.1 契約の範囲

- **Context構造体**: ブロック評価時に渡されるすべての情報
- **IBlock インターフェース**: ブロックの実装規約
- **BlockResult構造体**: ブロック評価の結果
- **IndicatorCache インターフェース**: インジケータハンドル共有・値取得
- **OrderExecutor インターフェース**: 発注処理の集約
- **PositionManager インターフェース**: ポジション管理処理
- **StateStore インターフェース**: 状態管理
- **Logger インターフェース**: ログ出力

### 1.2 設計決定事項（2026-01-22）

以下の決定事項が本契約に反映されています：

- **A1. ポジション管理タイミング**: 新バーのみ（M1新バー時のみ評価）
- **A2. IndicatorCacheハンドル生成**: OnInit時に全ハンドル生成
- **A3. OrderExecutor発注モード**: 同期発注
- **A4. Nanpinモード**: MVP段階ではnanpin.off固定
- **A5. Strategy競合解決**: MVP段階では"firstOnly"固定

---

## 2. Context構造体（完全定義）

### 2.1 Context構造体の役割

ブロック評価時にすべての必要情報を一箇所にまとめて渡す構造体です。

### 2.2 MQL5定義

```mql5
// 市場情報
struct MarketInfo {
    string symbol;           // シンボル名
    double ask;              // 現在のASK価格
    double bid;              // 現在のBID価格
    double spread;           // スプレッド（pips）

    // 価格配列（shift=1の確定足）
    double close[];          // close[0] = shift=1の終値
    double high[];           // high[0] = shift=1の高値
    double low[];            // low[0] = shift=1の安値
    double open[];           // open[0] = shift=1の始値
};

// 状態情報
struct StateInfo {
    datetime barTime;        // 現在評価対象のバー時刻（M1）
    int positionsTotal;      // 全ポジション数
    int positionsBySymbol;   // シンボル別ポジション数
    int positionsLong;       // ロングポジション数
    int positionsShort;      // ショートポジション数

    datetime lastEntryBarTime;  // 最後にエントリーしたバー時刻
    int nanpinCount;            // 現在のナンピン段数
};

// Context（ブロック評価時に渡される完全な情報）
struct Context {
    MarketInfo market;       // 市場情報
    StateInfo state;         // 状態情報
    IndicatorCache* cache;   // インジケータキャッシュ（参照）

    // ブロック個別パラメータ（実装時に追加される）
    // ParamsMap params;     // 各ブロックが独自に持つパラメータ
};
```

### 2.3 Context構築タイミング

- **タイミング**: M1新バー時、ブロック評価の直前
- **構築場所**: CompositeEvaluator::BuildContext()
- **注意事項**:
  - close/high/low/open配列はshift=1の値を格納（確定足）
  - spread計算は現在のASK/BIDから算出
  - barTimeは現在のM1バー時刻（iTime(Symbol(), PERIOD_M1, 0)）

---

## 3. IBlock インターフェース

### 3.1 IBlockの役割

すべてのブロック実装が従うべき共通インターフェースです。

### 3.2 MQL5定義

```mql5
// ブロック基底クラス
class IBlock {
public:
    // 仮想デストラクタ
    virtual ~IBlock() {}

    // ブロック評価（純粋仮想関数）
    virtual BlockResult Evaluate(const Context &ctx) = 0;

    // typeId取得（純粋仮想関数）
    virtual string GetTypeId() const = 0;
};
```

### 3.3 実装規約

**必須事項:**
- すべてのブロックはIBlockを継承
- Evaluate()は副作用なし（判定・計算のみ）
- shift=1（確定足）のデータを使用
- IndicatorCache経由でインジケータ値を取得
- 評価結果はBlockResultで返却

**禁止事項:**
- 直接OrderSend()等の発注処理を呼ぶ
- グローバル変数に状態を保存
- shift=0（未確定足）の使用

### 3.4 実装例

```mql5
// filter.spreadMax の実装例
class FilterSpreadMax : public IBlock {
private:
    double m_maxSpreadPips;

public:
    FilterSpreadMax(double maxSpreadPips) : m_maxSpreadPips(maxSpreadPips) {}

    virtual ~FilterSpreadMax() {}

    virtual BlockResult Evaluate(const Context &ctx) {
        double currentSpread = ctx.market.spread;
        bool pass = (currentSpread <= m_maxSpreadPips);

        string reason = "Spread=" + DoubleToString(currentSpread, 1) +
                       " pips (max=" + DoubleToString(m_maxSpreadPips, 1) + ")";

        return BlockResult(pass ? PASS : FAIL, NEUTRAL, reason);
    }

    virtual string GetTypeId() const {
        return "filter.spreadMax";
    }
};
```

---

## 4. BlockResult構造体

### 4.1 BlockResultの役割

ブロック評価の結果を格納する構造体です。

### 4.2 MQL5定義

```mql5
// ブロック評価ステータス
enum BlockStatus {
    PASS,     // 条件成立（エントリー許可）
    FAIL,     // 条件不成立（エントリー拒否）
    NEUTRAL   // 判定なし（フィルタ系ではあまり使わない）
};

// 方向
enum Direction {
    LONG,     // ロング方向
    SHORT,    // ショート方向
    NEUTRAL   // 方向なし
};

// ブロック評価結果
struct BlockResult {
    BlockStatus status;    // 評価ステータス（必須）
    Direction direction;   // 方向（必要なブロックのみ）
    string reason;         // 理由（ログ用、必須）
    double score;          // スコア（将来拡張用、オプション）

    // 拡張フィールド（lot/risk系ブロック用）
    double lotValue;       // ロット値（lot系ブロックが設定）
    double slPips;         // SLのpips（risk系ブロックが設定）
    double tpPips;         // TPのpips（risk系ブロックが設定）
    double slPrice;        // SL価格（絶対値指定時）
    double tpPrice;        // TP価格（絶対値指定時）

    // コンストラクタ（基本）
    BlockResult(BlockStatus st, Direction dir, string rsn)
        : status(st), direction(dir), reason(rsn), score(0.0),
          lotValue(0.0), slPips(0.0), tpPips(0.0),
          slPrice(0.0), tpPrice(0.0) {}

    // コンストラクタ（スコア付き）
    BlockResult(BlockStatus st, Direction dir, string rsn, double sc)
        : status(st), direction(dir), reason(rsn), score(sc),
          lotValue(0.0), slPips(0.0), tpPips(0.0),
          slPrice(0.0), tpPrice(0.0) {}
};
```

### 4.3 フィールド詳細

#### 4.3.1 status（必須）

- **PASS**: 条件成立、エントリー許可
- **FAIL**: 条件不成立、エントリー拒否（AND短絡評価で即座に打ち切り）
- **NEUTRAL**: 判定なし（将来拡張用、現在は未使用）

#### 4.3.2 direction（必要なブロックのみ）

- **LONG**: ロング方向を示唆（trend/trigger系ブロック）
- **SHORT**: ショート方向を示唆
- **NEUTRAL**: 方向なし（filter/env系ブロック）

#### 4.3.3 reason（必須）

- ログに出力される文字列
- 判定理由を人間が理解できる形式で記述
- 例: "Spread=1.5 pips (max=2.0)", "Close[1]=1.2345 vs MA[1]=1.2340 (closeAbove)"

#### 4.3.4 score（将来拡張用）

- Strategy競合解決で"bestScore"ポリシーを使用する際のスコア
- MVP段階では未使用（0.0固定）
- Phase 4で実装予定

#### 4.3.5 拡張フィールド（lot/risk系ブロック用）

- **lotValue**: lot系ブロック（lot.fixed等）が設定
- **slPips/tpPips**: risk系ブロック（risk.fixedSLTP等）がpipsで設定
- **slPrice/tpPrice**: risk系ブロックが絶対価格で設定する場合

---

## 5. IndicatorCache インターフェース

### 5.1 IndicatorCacheの役割

インジケータハンドルの共有と値のキャッシュにより、計算重複を抑制します。

### 5.2 設計決定事項（A2）

- **ハンドル生成タイミング**: OnInit時に全ハンドル生成（遅延生成なし）
- **理由**: エラー検出を起動時に前倒し可能、確実性優先

### 5.3 MQL5定義

```mql5
class IndicatorCache {
private:
    // ハンドルキャッシュ
    struct HandleCacheEntry {
        string key;        // "MA_200_EMA_M1" 等のユニークキー
        int handle;        // インジケータハンドル
    };
    HandleCacheEntry m_handles[];

    // 値キャッシュ（同一バー内の値を保持）
    struct ValueCacheEntry {
        string key;         // "MA_200_EMA_1_<barTime>" 等
        datetime barTime;   // バー時刻
        double value;       // キャッシュされた値
    };
    ValueCacheEntry m_values[];

public:
    // 初期化（OnInit時に呼出）
    void Initialize();

    // クリーンアップ（OnDeinit時に呼出）
    void Cleanup();

    // 値キャッシュクリア（新バー時に呼出）
    void ClearValueCache();

    // MAハンドル取得（事前生成・共有）
    int GetMAHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                    int shift, ENUM_MA_METHOD maType,
                    ENUM_APPLIED_PRICE appliedPrice);

    // MA値取得（shift=1固定、値キャッシュあり）
    double GetMAValue(int handle, int index, datetime barTime);

    // BBハンドル取得
    int GetBBHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                    int shift, double deviation, ENUM_APPLIED_PRICE appliedPrice);

    // BB値取得（buffer: 0=middle, 1=upper, 2=lower）
    double GetBBValue(int handle, int bufferIndex, int dataIndex, datetime barTime);

    // ATRハンドル取得
    int GetATRHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period);

    // ATR値取得
    double GetATRValue(int handle, int index, datetime barTime);

    // 汎用CopyBuffer（他のインジケータ用）
    bool CopyBufferSafe(int handle, int bufferIndex, int startPos, int count,
                       double &buffer[]);
};
```

### 5.4 メソッド詳細

#### 5.4.1 Initialize()

**呼出タイミング**: OnInit時

**処理内容**:
- 現在は何もしない（ハンドルは初回利用時に遅延生成）
- 将来的には、設定ファイルから必要なインジケータを事前生成可能

**エラーハンドリング**:
- 特になし（遅延生成時にエラー処理）

#### 5.4.2 Cleanup()

**呼出タイミング**: OnDeinit時

**処理内容**:
```mql5
void IndicatorCache::Cleanup() {
    // 全ハンドルを解放
    for (int i = 0; i < ArraySize(m_handles); i++) {
        if (m_handles[i].handle != INVALID_HANDLE) {
            IndicatorRelease(m_handles[i].handle);
        }
    }
    ArrayResize(m_handles, 0);
    ArrayResize(m_values, 0);
}
```

**エラーハンドリング**:
- IndicatorRelease()の失敗は無視（クリーンアップ時）

#### 5.4.3 ClearValueCache()

**呼出タイミング**: M1新バー時

**処理内容**:
```mql5
void IndicatorCache::ClearValueCache() {
    ArrayResize(m_values, 0);
}
```

**目的**: 新バーでキャッシュをクリアし、古い値の再利用を防止

#### 5.4.4 GetMAHandle()

**シグネチャ**:
```mql5
int GetMAHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                int shift, ENUM_MA_METHOD maType,
                ENUM_APPLIED_PRICE appliedPrice)
```

**処理フロー**:
1. キー生成: `"MA_" + symbol + "_" + timeframe + "_" + period + "_" + maType + "_" + appliedPrice`
2. キャッシュ検索: 既存ハンドルがあれば返却
3. 新規生成: `iMA(symbol, timeframe, period, shift, maType, appliedPrice)`
4. キャッシュ登録: `m_handles[]`に追加
5. ハンドル返却

**エラーハンドリング**:
```mql5
int handle = iMA(symbol, timeframe, period, shift, maType, appliedPrice);
if (handle == INVALID_HANDLE) {
    Print("ERROR: iMA failed - ", symbol, " ", period, " ", maType);
    return INVALID_HANDLE;
}
```

#### 5.4.5 GetMAValue()

**シグネチャ**:
```mql5
double GetMAValue(int handle, int index, datetime barTime)
```

**処理フロー**:
1. キー生成: `"MAV_" + handle + "_" + index + "_" + barTime`
2. 値キャッシュ検索: 同一バー時刻の値があれば返却
3. CopyBuffer実行: `CopyBuffer(handle, 0, index, 1, buffer)`
4. 値キャッシュ登録: `m_values[]`に追加
5. 値返却

**エラーハンドリング**:
```mql5
double buffer[];
if (CopyBuffer(handle, 0, index, 1, buffer) <= 0) {
    Print("ERROR: CopyBuffer failed - handle=", handle, " index=", index);
    return 0.0;  // 安全側: 0.0を返却（ブロック側でFAIL判定）
}
```

#### 5.4.6 GetBBHandle() / GetBBValue()

**処理内容**: GetMAHandle/GetMAValueと同様の仕組み

**BBバッファインデックス**:
- 0: middle（移動平均）
- 1: upper（上限）
- 2: lower（下限）

#### 5.4.7 CopyBufferSafe()

**目的**: 汎用的なCopyBuffer実行とエラーハンドリング

**シグネチャ**:
```mql5
bool CopyBufferSafe(int handle, int bufferIndex, int startPos, int count,
                   double &buffer[])
```

**処理内容**:
```mql5
bool IndicatorCache::CopyBufferSafe(int handle, int bufferIndex, int startPos,
                                   int count, double &buffer[]) {
    if (handle == INVALID_HANDLE) {
        Print("ERROR: Invalid handle in CopyBufferSafe");
        return false;
    }

    ArrayResize(buffer, count);
    int copied = CopyBuffer(handle, bufferIndex, startPos, count, buffer);

    if (copied <= 0) {
        Print("ERROR: CopyBuffer failed - handle=", handle,
              " buffer=", bufferIndex, " start=", startPos, " count=", count);
        return false;
    }

    return true;
}
```

### 5.5 メモリ管理とエラーハンドリング

#### 5.5.1 ハンドル解放タイミング

- **OnDeinit時のみ**: Cleanup()で全ハンドルをIndicatorRelease()
- **途中解放なし**: ハンドルは生成後、OnDeinitまで保持

#### 5.5.2 エラー時の挙動

- **ハンドル生成失敗**: INVALID_HANDLEを返却、ログ出力
- **CopyBuffer失敗**: 0.0を返却、ログ出力
- **ブロック側での対応**: INVALID_HANDLEまたは異常値の場合、FAILを返す

---

## 6. OrderExecutor インターフェース

### 6.1 OrderExecutorの役割

発注処理を集約し、同一足再エントリー禁止等のガードを実装します。

### 6.2 設計決定事項（A3）

- **発注モード**: 同期発注（MVP簡素化）
- **リトライロジック**: MVP段階ではリトライなし
- **理由**: エラーハンドリング明確、ログ追跡容易

### 6.3 MQL5定義

```mql5
// 発注リクエスト
struct OrderRequest {
    string symbol;         // シンボル
    int direction;         // LONG or SHORT
    double lot;            // ロット数
    double slPrice;        // SL価格（0.0の場合はslPipsを使用）
    double tpPrice;        // TP価格（0.0の場合はtpPipsを使用）
    double slPips;         // SLのpips（slPriceが0.0の場合）
    double tpPips;         // TPのpips（tpPriceが0.0の場合）
    long magic;            // マジックナンバー
    string comment;        // コメント
    datetime barTime;      // 評価対象のバー時刻（同一足禁止用）
};

// 発注結果
struct OrderResult {
    bool success;          // 成功/失敗
    ulong ticket;          // チケット番号（成功時のみ）
    int retcode;           // リターンコード
    string comment;        // コメント
    string rejectReason;   // 拒否理由（失敗時）
};

class OrderExecutor {
private:
    StateStore* m_stateStore;  // 状態管理（lastEntryBarTime等）
    Logger* m_logger;          // ログ出力

public:
    OrderExecutor(StateStore* stateStore, Logger* logger);
    ~OrderExecutor();

    // 発注実行（同期）
    OrderResult Execute(const OrderRequest &request);

private:
    // ブローカー制約検証
    bool ValidateLot(double lot, string &reason);
    bool ValidateSLTP(double price, double sl, double tp, int direction, string &reason);

    // 価格計算
    double CalculateSLPrice(double entryPrice, int direction, double slPips);
    double CalculateTPPrice(double entryPrice, int direction, double tpPips);
};
```

### 6.4 メソッド詳細

#### 6.4.1 Execute()

**シグネチャ**:
```mql5
OrderResult Execute(const OrderRequest &request)
```

**処理フロー**:
1. **同一足再エントリーチェック（第二ガード）**
   ```mql5
   datetime lastEntryBarTime = m_stateStore->GetLastEntryBarTime();
   if (request.barTime == lastEntryBarTime) {
       m_logger->LogOrderReject("SAME_BAR_REENTRY",
                               "Same bar re-entry is prohibited");
       return OrderResult{false, 0, 0, "", "Same bar re-entry"};
   }
   ```

2. **ロット検証**
   ```mql5
   string reason;
   if (!ValidateLot(request.lot, reason)) {
       m_logger->LogOrderReject("INVALID_LOT", reason);
       return OrderResult{false, 0, 0, "", reason};
   }
   ```

3. **SL/TP価格計算**
   ```mql5
   double entryPrice = (request.direction == LONG) ?
                       SymbolInfoDouble(request.symbol, SYMBOL_ASK) :
                       SymbolInfoDouble(request.symbol, SYMBOL_BID);

   double slPrice = (request.slPrice != 0.0) ? request.slPrice :
                    CalculateSLPrice(entryPrice, request.direction, request.slPips);
   double tpPrice = (request.tpPrice != 0.0) ? request.tpPrice :
                    CalculateTPPrice(entryPrice, request.direction, request.tpPips);
   ```

4. **SL/TP検証**
   ```mql5
   if (!ValidateSLTP(entryPrice, slPrice, tpPrice, request.direction, reason)) {
       m_logger->LogOrderReject("INVALID_SLTP", reason);
       return OrderResult{false, 0, 0, "", reason};
   }
   ```

5. **発注実行**
   ```mql5
   MqlTradeRequest mqlRequest = {};
   MqlTradeResult mqlResult = {};

   mqlRequest.action = TRADE_ACTION_DEAL;
   mqlRequest.symbol = request.symbol;
   mqlRequest.volume = request.lot;
   mqlRequest.type = (request.direction == LONG) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   mqlRequest.price = entryPrice;
   mqlRequest.sl = slPrice;
   mqlRequest.tp = tpPrice;
   mqlRequest.deviation = 5;
   mqlRequest.magic = request.magic;
   mqlRequest.comment = request.comment;

   bool success = OrderSend(mqlRequest, mqlResult);
   ```

6. **結果処理**
   ```mql5
   if (success && mqlResult.retcode == TRADE_RETCODE_DONE) {
       // 成功：lastEntryBarTime更新
       m_stateStore->SetLastEntryBarTime(request.barTime);
       m_logger->LogOrderResult(true, mqlResult.order, "");
       return OrderResult{true, mqlResult.order, mqlResult.retcode, "", ""};
   } else {
       // 失敗：理由ログ
       string failReason = "RetCode: " + IntegerToString(mqlResult.retcode) +
                          ", Comment: " + mqlResult.comment;
       m_logger->LogOrderResult(false, 0, failReason);
       return OrderResult{false, 0, mqlResult.retcode, mqlResult.comment, failReason};
   }
   ```

#### 6.4.2 ValidateLot()

**処理内容**:
```mql5
bool OrderExecutor::ValidateLot(double lot, string &reason) {
    double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

    if (lot < minLot) {
        reason = "Lot too small: " + DoubleToString(lot) +
                " (min=" + DoubleToString(minLot) + ")";
        return false;
    }

    if (lot > maxLot) {
        reason = "Lot too large: " + DoubleToString(lot) +
                " (max=" + DoubleToString(maxLot) + ")";
        return false;
    }

    // ロットステップ検証
    double remainder = fmod(lot - minLot, lotStep);
    if (remainder > 0.0000001) {  // 浮動小数点誤差考慮
        reason = "Lot step violation: " + DoubleToString(lot) +
                " (step=" + DoubleToString(lotStep) + ")";
        return false;
    }

    return true;
}
```

#### 6.4.3 ValidateSLTP()

**処理内容**:
```mql5
bool OrderExecutor::ValidateSLTP(double price, double sl, double tp,
                                int direction, string &reason) {
    int stopsLevel = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double minDistance = stopsLevel * point;

    // SL距離チェック
    if (sl != 0.0 && MathAbs(price - sl) < minDistance) {
        reason = "SL too close: " + DoubleToString(sl) +
                " (min distance=" + DoubleToString(minDistance) + ")";
        return false;
    }

    // TP距離チェック
    if (tp != 0.0 && MathAbs(price - tp) < minDistance) {
        reason = "TP too close: " + DoubleToString(tp) +
                " (min distance=" + DoubleToString(minDistance) + ")";
        return false;
    }

    // SL方向チェック
    if (direction == LONG && sl != 0.0 && sl >= price) {
        reason = "Invalid SL for LONG: SL=" + DoubleToString(sl) +
                " >= Entry=" + DoubleToString(price);
        return false;
    }

    if (direction == SHORT && sl != 0.0 && sl <= price) {
        reason = "Invalid SL for SHORT: SL=" + DoubleToString(sl) +
                " <= Entry=" + DoubleToString(price);
        return false;
    }

    return true;
}
```

### 6.5 マジックナンバー付与方法

**MVP方針**: 全Strategyで単一のマジックナンバーを使用

**実装**:
```mql5
#define MAGIC_NUMBER 20260122  // Strategy Bricks固有のマジック
```

**将来拡張**: Strategy別にマジックナンバーを割り当てる場合：
```mql5
long magic = BASE_MAGIC_NUMBER + strategyIndex;
```

---

## 7. PositionManager インターフェース

### 7.1 PositionManagerの役割

ポジション管理処理（トレール、建値、決済等）を集約します。

### 7.2 設計決定事項（A1）

- **評価タイミング**: 新バーのみ（M1新バー時のみ評価）
- **理由**: エントリー評価と統一、ログ量削減、再現性向上

### 7.3 MQL5定義

```mql5
class PositionManager {
private:
    Config* m_config;          // 設定
    Logger* m_logger;          // ログ出力
    StateStore* m_stateStore;  // 状態管理

public:
    PositionManager(Config* config, Logger* logger, StateStore* stateStore);
    ~PositionManager();

    // ポジション管理（新バー時のみ呼出）
    void ManagePositions();

private:
    // ExitModel適用
    void ApplyExitModel(ulong ticket, const Strategy &strategy);

    // トレーリング
    void ApplyTrailing(ulong ticket, double trailPips);

    // 建値移動
    void ApplyBreakeven(ulong ticket, double triggerPips, double offsetPips);

    // 平均利益決済
    void ApplyAvgProfit(ulong ticket, double targetProfit);

    // 週末決済
    void ApplyWeekendClose(ulong ticket, int closeHourFriday);

    // NanpinModel適用（Phase 4で実装）
    void ApplyNanpinModel(ulong ticket, const Strategy &strategy);

    // Strategyを特定
    const Strategy* GetStrategyByTicket(ulong ticket);
};
```

### 7.4 メソッド詳細

#### 7.4.1 ManagePositions()

**呼出タイミング**: M1新バー時のみ（OnTick内でNewBarDetector判定後）

**処理フロー**:
```mql5
void PositionManager::ManagePositions() {
    for (int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) continue;

        // マジックナンバーチェック
        if (PositionGetInteger(POSITION_MAGIC) != MAGIC_NUMBER) continue;

        // Strategyを特定
        const Strategy* strategy = GetStrategyByTicket(ticket);
        if (strategy == NULL) continue;

        // ExitModel適用
        ApplyExitModel(ticket, *strategy);

        // NanpinModel適用（Phase 4）
        // if (strategy->nanpinModel.type != "nanpin.off") {
        //     ApplyNanpinModel(ticket, *strategy);
        // }
    }
}
```

#### 7.4.2 ApplyExitModel()

**処理内容**:
```mql5
void PositionManager::ApplyExitModel(ulong ticket, const Strategy &strategy) {
    if (strategy.exitModel.type == "exit.none") {
        // 何もしない
        return;
    }

    if (strategy.exitModel.type == "exit.trailing") {
        double trailPips = strategy.exitModel.params["trailPips"];
        ApplyTrailing(ticket, trailPips);
    }
    else if (strategy.exitModel.type == "exit.breakeven") {
        double triggerPips = strategy.exitModel.params["triggerPips"];
        double offsetPips = strategy.exitModel.params["offsetPips"];
        ApplyBreakeven(ticket, triggerPips, offsetPips);
    }
    else if (strategy.exitModel.type == "exit.weekend") {
        int closeHour = (int)strategy.exitModel.params["closeHourFriday"];
        ApplyWeekendClose(ticket, closeHour);
    }
    // 他のexitModel実装...
}
```

### 7.5 ポジション管理の状態追跡

**lastEntryBarTime**: OrderExecutorで更新、StateStoreで管理
**nanpinCount**: NanpinModel実装時に追加（Phase 4）

---

## 8. StateStore インターフェース

### 8.1 StateStoreの役割

EA内の状態（lastEntryBarTime、nanpinCount等）を一元管理し、永続化します。

### 8.2 MQL5定義

```mql5
class StateStore {
private:
    datetime m_lastEntryBarTime;  // 最後にエントリーしたバー時刻
    int m_nanpinCount;            // 現在のナンピン段数（Phase 4）

    // 永続化用のプレフィックス
    static const string GLOBAL_VAR_PREFIX;  // "StrategyBricks_"

public:
    StateStore();
    ~StateStore();

    // 初期化（OnInit時に呼出、グローバル変数から復元）
    void Initialize();

    // 永続化（定期的に呼出）
    void Persist();

    // lastEntryBarTime管理
    datetime GetLastEntryBarTime() const;
    void SetLastEntryBarTime(datetime barTime);

    // nanpinCount管理（Phase 4）
    int GetNanpinCount() const;
    void SetNanpinCount(int count);
    void IncrementNanpinCount();
    void ResetNanpinCount();
};
```

### 8.3 メソッド詳細

#### 8.3.1 Initialize()

**処理内容**:
```mql5
void StateStore::Initialize() {
    // グローバル変数から復元
    string varName = GLOBAL_VAR_PREFIX + "lastEntryBarTime";

    if (GlobalVariableCheck(varName)) {
        m_lastEntryBarTime = (datetime)GlobalVariableGet(varName);
    } else {
        m_lastEntryBarTime = 0;
    }

    // nanpinCount復元（Phase 4）
    // varName = GLOBAL_VAR_PREFIX + "nanpinCount";
    // if (GlobalVariableCheck(varName)) {
    //     m_nanpinCount = (int)GlobalVariableGet(varName);
    // } else {
    //     m_nanpinCount = 0;
    // }
}
```

#### 8.3.2 Persist()

**呼出タイミング**: OnTick内で定期的（または状態変更時）

**処理内容**:
```mql5
void StateStore::Persist() {
    string varName = GLOBAL_VAR_PREFIX + "lastEntryBarTime";
    GlobalVariableSet(varName, (double)m_lastEntryBarTime);

    // nanpinCount永続化（Phase 4）
    // varName = GLOBAL_VAR_PREFIX + "nanpinCount";
    // GlobalVariableSet(varName, (double)m_nanpinCount);
}
```

#### 8.3.3 GetLastEntryBarTime() / SetLastEntryBarTime()

**使用例**:
```mql5
// OrderExecutor内で発注成功時
m_stateStore->SetLastEntryBarTime(request.barTime);
m_stateStore->Persist();

// OrderExecutor内で同一足チェック
datetime lastEntryBarTime = m_stateStore->GetLastEntryBarTime();
if (request.barTime == lastEntryBarTime) {
    // 拒否
}
```

---

## 9. Logger インターフェース

### 9.1 Loggerの役割

すべての判定・発注・拒否理由を構造化ログ（JSONL形式）で出力します。

### 9.2 MQL5定義

```mql5
class Logger {
private:
    int m_fileHandle;          // ログファイルハンドル
    string m_logPath;          // ログファイルパス
    bool m_initialized;        // 初期化済みフラグ

public:
    Logger();
    ~Logger();

    // 初期化（OnInit時に呼出）
    bool Initialize(string logPathPrefix);

    // クリーンアップ（OnDeinit時に呼出）
    void Cleanup();

    // ログ出力メソッド
    void LogConfigLoaded(bool success, string version, int strategyCount, int blockCount);
    void LogBarEvalStart(datetime barTime);
    void LogStrategyEval(string strategyId, bool adopted, string reason);
    void LogRuleGroupEval(string ruleGroupId, bool matched);
    void LogBlockEval(string blockId, const BlockResult &result);
    void LogOrderAttempt(const OrderRequest &request);
    void LogOrderResult(bool success, ulong ticket, string reason);
    void LogOrderReject(string rejectType, string reason);
    void LogManagementAction(string actionType, ulong ticket, string detail);
    void LogNanpinAction(string actionType, ulong ticket, int count, string detail);

    // 汎用ログ
    void LogInfo(string event, string message);
    void LogError(string event, string message);

private:
    // JSONL行出力
    void WriteLine(string line);

    // JSON文字列エスケープ
    string EscapeJSON(string str);
};
```

### 9.3 ログ出力形式（JSONL）

**ファイルパス**: `MQL5/Files/strategy/logs/strategy_YYYYMMDD.jsonl`

**例**:
```jsonl
{"ts":"2026-01-22 10:00:00","event":"CONFIG_LOADED","success":true,"version":"1.0","strategyCount":1,"blockCount":4}
{"ts":"2026-01-22 10:01:00","event":"BAR_EVAL_START","symbol":"USDJPY","barTimeM1":"2026-01-22 10:01:00"}
{"ts":"2026-01-22 10:01:00","event":"STRATEGY_EVAL","strategyId":"S1","adopted":true,"reason":"matched"}
{"ts":"2026-01-22 10:01:00","event":"BLOCK_EVAL","blockId":"filter.spreadMax#1","typeId":"filter.spreadMax","status":"PASS","reason":"Spread=1.5 pips (max=2.0)"}
{"ts":"2026-01-22 10:01:00","event":"ORDER_RESULT","success":true,"ticket":12345,"reason":""}
```

### 9.4 メソッド詳細

#### 9.4.1 Initialize()

**処理内容**:
```mql5
bool Logger::Initialize(string logPathPrefix) {
    // 日次ローテーション
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string date = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);
    m_logPath = logPathPrefix + date + ".jsonl";

    // ファイルオープン（追記モード）
    m_fileHandle = FileOpen(m_logPath, FILE_WRITE|FILE_READ|FILE_TXT);
    if (m_fileHandle == INVALID_HANDLE) {
        Print("ERROR: Cannot open log file: ", m_logPath);
        m_initialized = false;
        return false;
    }

    FileSeek(m_fileHandle, 0, SEEK_END);
    m_initialized = true;
    return true;
}
```

#### 9.4.2 LogBlockEval()

**処理内容**:
```mql5
void Logger::LogBlockEval(string blockId, const BlockResult &result) {
    string statusStr = (result.status == PASS) ? "PASS" :
                      (result.status == FAIL) ? "FAIL" : "NEUTRAL";

    string json = "{" +
        "\"ts\":\"" + TimeToString(TimeCurrent()) + "\"," +
        "\"event\":\"BLOCK_EVAL\"," +
        "\"blockId\":\"" + blockId + "\"," +
        "\"status\":\"" + statusStr + "\"," +
        "\"reason\":\"" + EscapeJSON(result.reason) + "\"";

    // directionが有効な場合のみ追加
    if (result.direction != NEUTRAL) {
        string dirStr = (result.direction == LONG) ? "LONG" : "SHORT";
        json += ",\"direction\":\"" + dirStr + "\"";
    }

    // scoreが有効な場合のみ追加
    if (result.score != 0.0) {
        json += ",\"score\":" + DoubleToString(result.score, 2);
    }

    json += "}";
    WriteLine(json);
}
```

---

## 10. エラーハンドリング統一規約

### 10.1 エラー時の基本方針

**安全側動作**: エラー時はエントリー見送り、ポジション管理のみ継続

### 10.2 エラー種別と対応

| エラー種別 | 発生場所 | 対応 | ログイベント |
|-----------|---------|------|-------------|
| formatVersion非互換 | ConfigLoader | INIT_FAILED | CONFIG_ERROR |
| スキーマ検証失敗 | Validator | INIT_FAILED | CONFIG_ERROR |
| ブロック参照切れ | Validator | INIT_FAILED | CONFIG_ERROR |
| ハンドル生成失敗 | IndicatorCache | INVALID_HANDLE返却 | INDICATOR_ERROR |
| CopyBuffer失敗 | IndicatorCache | 0.0返却 | INDICATOR_ERROR |
| ブロック評価失敗 | Block::Evaluate | FAIL返却 | BLOCK_EVAL |
| ロット検証失敗 | OrderExecutor | 発注拒否 | ORDER_REJECT |
| SL/TP検証失敗 | OrderExecutor | 発注拒否 | ORDER_REJECT |
| 同一足再エントリー | OrderExecutor | 発注拒否 | ORDER_REJECT |
| OrderSend失敗 | OrderExecutor | 失敗ログ | ORDER_RESULT |

### 10.3 エラーハンドリングコード例

```mql5
// IndicatorCache: ハンドル生成失敗
int handle = iMA(...);
if (handle == INVALID_HANDLE) {
    Print("ERROR: iMA failed - ", symbol, " ", period);
    return INVALID_HANDLE;  // 呼出側でチェック
}

// Block: ハンドル失敗時の安全側動作
if (m_handle == INVALID_HANDLE) {
    return BlockResult(FAIL, NEUTRAL, "Indicator handle unavailable");
}

// OrderExecutor: 検証失敗時の拒否
if (!ValidateLot(request.lot, reason)) {
    m_logger->LogOrderReject("INVALID_LOT", reason);
    return OrderResult{false, 0, 0, "", reason};
}
```

---

## 11. 参照ドキュメント

本インターフェース契約書は以下のドキュメントを基に作成されています：

- `docs/00_overview.md` - 合意事項・前提条件
- `docs/03_design/20_architecture.md` - アーキテクチャ設計
- `docs/03_design/30_config_spec.md` - strategy_config.json仕様
- `docs/03_design/40_block_catalog_spec.md` - block_catalog.json仕様
- `docs/03_design/50_ea_runtime_design.md` - EA Runtime詳細設計
- `docs/04_operations/90_observability_and_testing.md` - 観測性とテスト

---

## 12. 実装時の確認事項

### 12.1 インターフェース一致の検証

- Context構造体の全フィールドが実装されているか
- IBlock::Evaluate()のシグネチャが一致しているか
- BlockResult構造体の全フィールドが実装されているか
- IndicatorCacheの全メソッドが実装されているか
- OrderExecutorの全メソッドが実装されているか

### 12.2 エラーハンドリングの検証

- すべてのINVALID_HANDLEチェックが実装されているか
- すべてのCopyBuffer失敗チェックが実装されているか
- すべての検証失敗時にログが出力されるか

### 12.3 ログ出力の検証

- すべてのログイベントが実装されているか
- reason文字列が適切に設定されているか
- JSONL形式が正しいか

---

## 13. 変更履歴

| 版 | 日付 | 変更内容 |
|----|------|---------|
| v1.0 | 2026-01-22 | 初版作成、未決事項A1-A5の決定を反映 |

---
