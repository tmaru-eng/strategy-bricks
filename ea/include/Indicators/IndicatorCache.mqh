//+------------------------------------------------------------------+
//|                                              IndicatorCache.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                  インジケータハンドル共有・値キャッシュ                |
//+------------------------------------------------------------------+
#ifndef INDICATORCACHE_MQH
#define INDICATORCACHE_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Support/Logger.mqh"

//+------------------------------------------------------------------+
//| ハンドルキャッシュエントリ                                            |
//+------------------------------------------------------------------+
struct HandleCacheEntry {
    string key;         // ユニークキー（例: "MA_USDJPY_M1_200_EMA"）
    int    handle;      // インジケータハンドル
};

//+------------------------------------------------------------------+
//| 値キャッシュエントリ                                                 |
//+------------------------------------------------------------------+
struct ValueCacheEntry {
    string   key;       // ユニークキー（例: "MA_handle_1_barTime"）
    datetime barTime;   // バー時刻
    double   value;     // キャッシュされた値
};

//+------------------------------------------------------------------+
//| IndicatorCacheクラス                                               |
//| インジケータハンドルの共有と値のキャッシュを管理                         |
//+------------------------------------------------------------------+
class CIndicatorCache {
private:
    HandleCacheEntry m_handles[];       // ハンドルキャッシュ
    ValueCacheEntry  m_values[];        // 値キャッシュ
    int              m_handleCount;     // ハンドル数
    int              m_valueCount;      // 値キャッシュ数
    CLogger*         m_logger;          // ロガー

    //+------------------------------------------------------------------+
    //| ハンドルキャッシュからキーで検索                                     |
    //+------------------------------------------------------------------+
    int FindHandleByKey(string key) {
        for (int i = 0; i < m_handleCount; i++) {
            if (m_handles[i].key == key) {
                return m_handles[i].handle;
            }
        }
        return INVALID_HANDLE;
    }

    //+------------------------------------------------------------------+
    //| ハンドルキャッシュに登録                                           |
    //+------------------------------------------------------------------+
    void AddHandle(string key, int handle) {
        ArrayResize(m_handles, m_handleCount + 1);
        m_handles[m_handleCount].key = key;
        m_handles[m_handleCount].handle = handle;
        m_handleCount++;
    }

    //+------------------------------------------------------------------+
    //| 値キャッシュからキーとバー時刻で検索                                 |
    //+------------------------------------------------------------------+
    bool FindValueByKey(string key, datetime barTime, double &value) {
        for (int i = 0; i < m_valueCount; i++) {
            if (m_values[i].key == key && m_values[i].barTime == barTime) {
                value = m_values[i].value;
                return true;
            }
        }
        return false;
    }

    //+------------------------------------------------------------------+
    //| 値キャッシュに登録                                                 |
    //+------------------------------------------------------------------+
    void AddValue(string key, datetime barTime, double value) {
        ArrayResize(m_values, m_valueCount + 1);
        m_values[m_valueCount].key = key;
        m_values[m_valueCount].barTime = barTime;
        m_values[m_valueCount].value = value;
        m_valueCount++;
    }

public:
    //--- コンストラクタ
    CIndicatorCache() {
        m_handleCount = 0;
        m_valueCount = 0;
        m_logger = NULL;
    }

    //--- デストラクタ
    ~CIndicatorCache() {
        Cleanup();
    }

    //--- ロガー設定
    void SetLogger(CLogger *logger) {
        m_logger = logger;
    }

    //+------------------------------------------------------------------+
    //| 初期化（OnInit時に呼出）                                           |
    //+------------------------------------------------------------------+
    void Initialize() {
        ArrayResize(m_handles, INITIAL_ARRAY_SIZE);
        ArrayResize(m_values, INITIAL_ARRAY_SIZE);
        m_handleCount = 0;
        m_valueCount = 0;
        Print("IndicatorCache: Initialized");
    }

    //+------------------------------------------------------------------+
    //| クリーンアップ（OnDeinit時に呼出）                                   |
    //+------------------------------------------------------------------+
    void Cleanup() {
        // 全ハンドルを解放
        for (int i = 0; i < m_handleCount; i++) {
            if (m_handles[i].handle != INVALID_HANDLE) {
                IndicatorRelease(m_handles[i].handle);
            }
        }
        ArrayResize(m_handles, 0);
        ArrayResize(m_values, 0);
        m_handleCount = 0;
        m_valueCount = 0;
        Print("IndicatorCache: Cleanup completed");
    }

    //+------------------------------------------------------------------+
    //| 値キャッシュクリア（新バー時に呼出）                                  |
    //+------------------------------------------------------------------+
    void ClearValueCache() {
        ArrayResize(m_values, 0);
        m_valueCount = 0;
    }

    //+------------------------------------------------------------------+
    //| MAハンドル取得（遅延生成・共有）                                     |
    //+------------------------------------------------------------------+
    int GetMAHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                    int shift, ENUM_MA_METHOD maType, ENUM_APPLIED_PRICE appliedPrice) {
        // キー生成
        string key = "MA_" + symbol + "_" + EnumToString(timeframe) + "_" +
                    IntegerToString(period) + "_" + IntegerToString(maType) + "_" +
                    IntegerToString(appliedPrice);

        // キャッシュ検索
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) {
            return handle;
        }

        // 新規ハンドル生成
        handle = iMA(symbol, timeframe, period, shift, maType, appliedPrice);
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "iMA failed: " + symbol + " period=" + IntegerToString(period) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            Print("ERROR: iMA failed - ", symbol, " ", period, " ", maType);
            return INVALID_HANDLE;
        }

        // キャッシュ登録
        AddHandle(key, handle);
        Print("IndicatorCache: Created MA handle - ", key);
        return handle;
    }

    //+------------------------------------------------------------------+
    //| MA値取得（値キャッシュあり）                                        |
    //+------------------------------------------------------------------+
    double GetMAValue(int handle, int index, datetime barTime) {
        if (handle == INVALID_HANDLE) {
            return 0.0;
        }

        // 値キャッシュキー生成
        string key = "MAV_" + IntegerToString(handle) + "_" + IntegerToString(index);

        // 値キャッシュ検索
        double cachedValue;
        if (FindValueByKey(key, barTime, cachedValue)) {
            return cachedValue;
        }

        // CopyBufferで取得
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if (CopyBuffer(handle, 0, index, 1, buffer) <= 0) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "CopyBuffer failed: handle=" + IntegerToString(handle) +
                    " index=" + IntegerToString(index) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            return 0.0;
        }

        double value = buffer[0];

        // 値キャッシュ登録
        AddValue(key, barTime, value);
        return value;
    }

    //+------------------------------------------------------------------+
    //| BBハンドル取得（遅延生成・共有）                                     |
    //+------------------------------------------------------------------+
    int GetBBHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                    int shift, double deviation, ENUM_APPLIED_PRICE appliedPrice) {
        // キー生成
        string key = "BB_" + symbol + "_" + EnumToString(timeframe) + "_" +
                    IntegerToString(period) + "_" + DoubleToString(deviation, 1) + "_" +
                    IntegerToString(appliedPrice);

        // キャッシュ検索
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) {
            return handle;
        }

        // 新規ハンドル生成
        handle = iBands(symbol, timeframe, period, shift, deviation, appliedPrice);
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "iBands failed: " + symbol + " period=" + IntegerToString(period) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            Print("ERROR: iBands failed - ", symbol, " ", period, " ", deviation);
            return INVALID_HANDLE;
        }

        // キャッシュ登録
        AddHandle(key, handle);
        Print("IndicatorCache: Created BB handle - ", key);
        return handle;
    }

    //+------------------------------------------------------------------+
    //| BB値取得（buffer: 0=middle, 1=upper, 2=lower）                     |
    //+------------------------------------------------------------------+
    double GetBBValue(int handle, int bufferIndex, int dataIndex, datetime barTime) {
        if (handle == INVALID_HANDLE) {
            return 0.0;
        }

        // 値キャッシュキー生成
        string key = "BBV_" + IntegerToString(handle) + "_" +
                    IntegerToString(bufferIndex) + "_" + IntegerToString(dataIndex);

        // 値キャッシュ検索
        double cachedValue;
        if (FindValueByKey(key, barTime, cachedValue)) {
            return cachedValue;
        }

        // CopyBufferで取得
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if (CopyBuffer(handle, bufferIndex, dataIndex, 1, buffer) <= 0) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "CopyBuffer failed: handle=" + IntegerToString(handle) +
                    " buffer=" + IntegerToString(bufferIndex) +
                    " index=" + IntegerToString(dataIndex) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            return 0.0;
        }

        double value = buffer[0];

        // 値キャッシュ登録
        AddValue(key, barTime, value);
        return value;
    }

    //+------------------------------------------------------------------+
    //| ATRハンドル取得（遅延生成・共有）                                    |
    //+------------------------------------------------------------------+
    int GetATRHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        // キー生成
        string key = "ATR_" + symbol + "_" + EnumToString(timeframe) + "_" +
                    IntegerToString(period);

        // キャッシュ検索
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) {
            return handle;
        }

        // 新規ハンドル生成
        handle = iATR(symbol, timeframe, period);
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "iATR failed: " + symbol + " period=" + IntegerToString(period) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            Print("ERROR: iATR failed - ", symbol, " ", period);
            return INVALID_HANDLE;
        }

        // キャッシュ登録
        AddHandle(key, handle);
        Print("IndicatorCache: Created ATR handle - ", key);
        return handle;
    }

    //+------------------------------------------------------------------+
    //| ATR値取得（値キャッシュあり）                                       |
    //+------------------------------------------------------------------+
    double GetATRValue(int handle, int index, datetime barTime) {
        if (handle == INVALID_HANDLE) {
            return 0.0;
        }

        // 値キャッシュキー生成
        string key = "ATRV_" + IntegerToString(handle) + "_" + IntegerToString(index);

        // 値キャッシュ検索
        double cachedValue;
        if (FindValueByKey(key, barTime, cachedValue)) {
            return cachedValue;
        }

        // CopyBufferで取得
        double buffer[];
        ArraySetAsSeries(buffer, true);
        if (CopyBuffer(handle, 0, index, 1, buffer) <= 0) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "CopyBuffer failed: handle=" + IntegerToString(handle) +
                    " index=" + IntegerToString(index) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            return 0.0;
        }

        double value = buffer[0];

        // 値キャッシュ登録
        AddValue(key, barTime, value);
        return value;
    }

    //+------------------------------------------------------------------+
    //| 汎用CopyBuffer（他のインジケータ用）                                |
    //+------------------------------------------------------------------+
    bool CopyBufferSafe(int handle, int bufferIndex, int startPos, int count,
                        double &buffer[]) {
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR", "Invalid handle in CopyBufferSafe");
            }
            return false;
        }

        ArrayResize(buffer, count);
        ArraySetAsSeries(buffer, true);
        int copied = CopyBuffer(handle, bufferIndex, startPos, count, buffer);

        if (copied <= 0) {
            if (m_logger != NULL) {
                m_logger.LogError("INDICATOR_ERROR",
                    "CopyBuffer failed: handle=" + IntegerToString(handle) +
                    " buffer=" + IntegerToString(bufferIndex) +
                    " start=" + IntegerToString(startPos) +
                    " count=" + IntegerToString(count) +
                    " Error=" + IntegerToString(GetLastError()));
            }
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| ハンドル数取得                                                     |
    //+------------------------------------------------------------------+
    int GetHandleCount() const {
        return m_handleCount;
    }
};

#endif // INDICATORCACHE_MQH
