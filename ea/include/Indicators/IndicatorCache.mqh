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
    //| MA                                                               |
    //+------------------------------------------------------------------+
    int GetMAHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period,
                    int shift, ENUM_MA_METHOD maType, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("MA_%s_%d_%d_%d_%d_%d", symbol, timeframe, period, shift, maType, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iMA(symbol, timeframe, period, shift, maType, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        else Print("ERROR: iMA failed");
        return handle;
    }

    double GetMAValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| RSI                                                              |
    //+------------------------------------------------------------------+
    int GetRSIHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("RSI_%s_%d_%d_%d", symbol, timeframe, period, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iRSI(symbol, timeframe, period, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetRSIValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| CCI                                                              |
    //+------------------------------------------------------------------+
    int GetCCIHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("CCI_%s_%d_%d_%d", symbol, timeframe, period, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iCCI(symbol, timeframe, period, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetCCIValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| MACD                                                             |
    //+------------------------------------------------------------------+
    int GetMACDHandle(string symbol, ENUM_TIMEFRAMES timeframe, int fastEma, int slowEma, int signal, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("MACD_%s_%d_%d_%d_%d_%d", symbol, timeframe, fastEma, slowEma, signal, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iMACD(symbol, timeframe, fastEma, slowEma, signal, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=MAIN, 1=SIGNAL
    double GetMACDValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Stochastic                                                       |
    //+------------------------------------------------------------------+
    int GetStochHandle(string symbol, ENUM_TIMEFRAMES timeframe, int kParams, int dParams, int slowing, ENUM_MA_METHOD maType, ENUM_STO_PRICE priceField) {
        string key = StringFormat("STO_%s_%d_%d_%d_%d_%d_%d", symbol, timeframe, kParams, dParams, slowing, maType, priceField);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iStochastic(symbol, timeframe, kParams, dParams, slowing, maType, priceField);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=MAIN, 1=SIGNAL
    double GetStochValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Bollinger Bands                                                  |
    //+------------------------------------------------------------------+
    int GetBBHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift, double deviation, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("BB_%s_%d_%d_%d_%.2f_%d", symbol, timeframe, period, shift, deviation, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iBands(symbol, timeframe, period, shift, deviation, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=BASE, 1=UPPER, 2=LOWER
    double GetBBValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| ADX                                                              |
    //+------------------------------------------------------------------+
    int GetADXHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("ADX_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iADX(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=MAIN, 1=+DI, 2=-DI
    double GetADXValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Ichimoku                                                         |
    //+------------------------------------------------------------------+
    int GetIchimokuHandle(string symbol, ENUM_TIMEFRAMES timeframe, int tenkan, int kijun, int senkou) {
        string key = StringFormat("ICH_%s_%d_%d_%d_%d", symbol, timeframe, tenkan, kijun, senkou);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iIchimoku(symbol, timeframe, tenkan, kijun, senkou);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=TENKAN, 1=KIJUN, 2=SENKOU_A, 3=SENKOU_B, 4=CHIKOU
    double GetIchimokuValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| SAR                                                              |
    //+------------------------------------------------------------------+
    int GetSARHandle(string symbol, ENUM_TIMEFRAMES timeframe, double step, double max) {
        string key = StringFormat("SAR_%s_%d_%.4f_%.4f", symbol, timeframe, step, max);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iSAR(symbol, timeframe, step, max);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetSARValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| ENVELOPEs                                                        |
    //+------------------------------------------------------------------+
    int GetEnvelopesHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift, ENUM_MA_METHOD maMethod, ENUM_APPLIED_PRICE appliedPrice, double deviation) {
        string key = StringFormat("ENV_%s_%d_%d_%d_%d_%d_%.4f", symbol, timeframe, period, shift, maMethod, appliedPrice, deviation);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iEnvelopes(symbol, timeframe, period, shift, maMethod, appliedPrice, deviation);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=UPPER, 1=LOWER
    double GetEnvelopesValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| ATR                                                              |
    //+------------------------------------------------------------------+
    int GetATRHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("ATR_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iATR(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetATRValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Momentum                                                         |
    //+------------------------------------------------------------------+
    int GetMomentumHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("MOM_%s_%d_%d_%d", symbol, timeframe, period, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iMomentum(symbol, timeframe, period, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetMomentumValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| OsMA                                                             |
    //+------------------------------------------------------------------+
    int GetOsMAHandle(string symbol, ENUM_TIMEFRAMES timeframe, int fastEma, int slowEma, int signal, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("OSMA_%s_%d_%d_%d_%d_%d", symbol, timeframe, fastEma, slowEma, signal, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iOsMA(symbol, timeframe, fastEma, slowEma, signal, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetOsMAValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| WPR                                                              |
    //+------------------------------------------------------------------+
    int GetWPRHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("WPR_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iWPR(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetWPRValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| MFI                                                              |
    //+------------------------------------------------------------------+
    int GetMFIHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_APPLIED_VOLUME appliedVolume) {
        string key = StringFormat("MFI_%s_%d_%d_%d", symbol, timeframe, period, appliedVolume);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iMFI(symbol, timeframe, period, appliedVolume);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetMFIValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| OBV                                                              |
    //+------------------------------------------------------------------+
    int GetOBVHandle(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_APPLIED_VOLUME appliedVolume) {
        string key = StringFormat("OBV_%s_%d_%d", symbol, timeframe, appliedVolume);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iOBV(symbol, timeframe, appliedVolume);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetOBVValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Force Index                                                      |
    //+------------------------------------------------------------------+
    int GetForceHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period, ENUM_MA_METHOD maMethod, ENUM_APPLIED_VOLUME appliedVolume) {
        string key = StringFormat("FRC_%s_%d_%d_%d_%d", symbol, timeframe, period, maMethod, appliedVolume);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iForce(symbol, timeframe, period, maMethod, appliedVolume);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetForceValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| DeMarker                                                         |
    //+------------------------------------------------------------------+
    int GetDeMarkerHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("DEM_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iDeMarker(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetDeMarkerValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| BearsPower                                                       |
    //+------------------------------------------------------------------+
    int GetBearsPowerHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("BEARS_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iBearsPower(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetBearsPowerValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| BullsPower                                                       |
    //+------------------------------------------------------------------+
    int GetBullsPowerHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("BULLS_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iBullsPower(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetBullsPowerValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| RVI                                                              |
    //+------------------------------------------------------------------+
    int GetRVIHandle(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
        string key = StringFormat("RVI_%s_%d_%d", symbol, timeframe, period);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iRVI(symbol, timeframe, period);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=MAIN, 1=SIGNAL
    double GetRVIValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| StdDev                                                           |
    //+------------------------------------------------------------------+
    int GetStdDevHandle(string symbol, ENUM_TIMEFRAMES timeframe, int maPeriod, int maShift, ENUM_MA_METHOD maMethod, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("STD_%s_%d_%d_%d_%d_%d", symbol, timeframe, maPeriod, maShift, maMethod, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iStdDev(symbol, timeframe, maPeriod, maShift, maMethod, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    double GetStdDevValue(int handle, int index, datetime barTime) {
        return GetValueCommon(handle, 0, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Fractals                                                         |
    //+------------------------------------------------------------------+
    int GetFractalsHandle(string symbol, ENUM_TIMEFRAMES timeframe) {
        string key = StringFormat("FRAC_%s_%d", symbol, timeframe);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iFractals(symbol, timeframe);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=UPPER, 1=LOWER
    double GetFractalsValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| Alligator                                                        |
    //+------------------------------------------------------------------+
    int GetAlligatorHandle(string symbol, ENUM_TIMEFRAMES timeframe, int jawPeriod, int jawShift, int teethPeriod, int teethShift, int lipsPeriod, int lipsShift, ENUM_MA_METHOD maMethod, ENUM_APPLIED_PRICE appliedPrice) {
        string key = StringFormat("ALLIG_%s_%d_%d_%d_%d_%d_%d_%d_%d_%d", symbol, timeframe, jawPeriod, jawShift, teethPeriod, teethShift, lipsPeriod, lipsShift, maMethod, appliedPrice);
        int handle = FindHandleByKey(key);
        if (handle != INVALID_HANDLE) return handle;

        handle = iAlligator(symbol, timeframe, jawPeriod, jawShift, teethPeriod, teethShift, lipsPeriod, lipsShift, maMethod, appliedPrice);
        if (handle != INVALID_HANDLE) AddHandle(key, handle);
        return handle;
    }

    // buffer: 0=JAW, 1=TEETH, 2=LIPS
    double GetAlligatorValue(int handle, int buffer, int index, datetime barTime) {
        return GetValueCommon(handle, buffer, index, barTime);
    }

    //+------------------------------------------------------------------+
    //| 汎用値取得（キャッシュ付）                                          |
    //+------------------------------------------------------------------+
    //+------------------------------------------------------------------+
    //| 汎用値取得（キャッシュ付き）                                         |
    //| IMPORTANT: barTimeには各バーの実際の時刻を渡す必要があります           |
    //| 履歴データを検索する際は、iTime(Symbol(), EA_TIMEFRAME, index)を使用  |
    //| barTime=0を渡すと、異なるバーのデータが同じキャッシュキーで保存され、   |
    //| キャッシュの不整合や誤動作が発生する可能性があります                    |
    //+------------------------------------------------------------------+
    double GetValueCommon(int handle, int bufferIndex, int index, datetime barTime) {
        if (handle == INVALID_HANDLE) return 0.0;

        string key = StringFormat("V_%d_%d_%d", handle, bufferIndex, index);
        double cachedValue;
        if (FindValueByKey(key, barTime, cachedValue)) {
            return cachedValue;
        }

        double buffer[];
        ArraySetAsSeries(buffer, true);
        if (CopyBuffer(handle, bufferIndex, index, 1, buffer) <= 0) {
            return 0.0; // Error logic managed by caller or specific check
        }

        double value = buffer[0];
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
