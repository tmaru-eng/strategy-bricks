//+------------------------------------------------------------------+
//|                                                       IBlock.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                           ブロックインターフェース定義                |
//+------------------------------------------------------------------+
#ifndef IBLOCK_MQH
#define IBLOCK_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Indicators/IndicatorCache.mqh"
#include "../Support/JsonParser.mqh"

//+------------------------------------------------------------------+
//| Context構造体（ブロック評価時に渡される完全な情報）                     |
//+------------------------------------------------------------------+
struct Context {
    MarketInfo       market;     // 市場情報
    StateInfo        state;      // 状態情報
    CIndicatorCache* cache;      // インジケータキャッシュ（参照）
    string           paramsJson; // ブロック個別パラメータJSON

    void Reset() {
        market.Reset();
        state.Reset();
        cache = NULL;
        paramsJson = "";
    }
};

//+------------------------------------------------------------------+
//| IBlockクラス（ブロック基底クラス）                                     |
//| すべてのブロック実装が継承する抽象基底クラス                            |
//+------------------------------------------------------------------+
class IBlock {
public:
    //--- 仮想デストラクタ
    virtual ~IBlock() {}

    //--- ブロック評価（純粋仮想関数）
    // 副作用なし、判定・計算のみ
    // shift=1（確定足）のデータを使用
    virtual void Evaluate(const Context &ctx, BlockResult &result) = 0;

    //--- typeId取得（純粋仮想関数）
    virtual string GetTypeId() const = 0;

    //--- ブロックID取得
    virtual string GetBlockId() const = 0;

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) = 0;
};

//+------------------------------------------------------------------+
//| BlockBase（共通機能を持つ基底クラス）                                 |
//+------------------------------------------------------------------+
class CBlockBase : public IBlock {
protected:
    string m_blockId;       // ブロックID
    string m_typeId;        // タイプID
    string m_paramsJson;    // パラメータJSON
    CJsonObject m_jsonObj;  // JSONパーサー

    //+------------------------------------------------------------------+
    //| JSON文字列から数値を取得（CJsonObject使用）                          |
    //+------------------------------------------------------------------+
    double GetParamDouble(string paramsJson, string key, double defaultValue) {
        if (paramsJson == "") return defaultValue;
        m_jsonObj.SetJson(paramsJson);
        return m_jsonObj.GetDouble(key, defaultValue);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から整数を取得（CJsonObject使用）                          |
    //+------------------------------------------------------------------+
    int GetParamInt(string paramsJson, string key, int defaultValue) {
        if (paramsJson == "") return defaultValue;
        m_jsonObj.SetJson(paramsJson);
        return m_jsonObj.GetInt(key, defaultValue);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から文字列を取得（CJsonObject使用）                         |
    //+------------------------------------------------------------------+
    string GetParamString(string paramsJson, string key, string defaultValue) {
        if (paramsJson == "") return defaultValue;
        m_jsonObj.SetJson(paramsJson);
        return m_jsonObj.GetString(key, defaultValue);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から真偽値を取得（CJsonObject使用）                         |
    //+------------------------------------------------------------------+
    bool GetParamBool(string paramsJson, string key, bool defaultValue) {
        if (paramsJson == "") return defaultValue;
        m_jsonObj.SetJson(paramsJson);
        return m_jsonObj.GetBool(key, defaultValue);
    }

public:
    //--- コンストラクタ
    CBlockBase(string blockId, string typeId) {
        m_blockId = blockId;
        m_typeId = typeId;
        m_paramsJson = "";
    }

    //--- デストラクタ
    virtual ~CBlockBase() {}

    //--- typeId取得
    virtual string GetTypeId() const override {
        return m_typeId;
    }

    //--- ブロックID取得
    virtual string GetBlockId() const override {
        return m_blockId;
    }

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        m_paramsJson = paramsJson;
    }
};

#endif // IBLOCK_MQH
