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

    //+------------------------------------------------------------------+
    //| JSON文字列から数値を取得                                           |
    //+------------------------------------------------------------------+
    double GetParamDouble(string paramsJson, string key, double defaultValue) {
        string searchKey = "\"" + key + "\"";
        int pos = StringFind(paramsJson, searchKey);
        if (pos < 0) return defaultValue;

        // コロンを探す
        pos = StringFind(paramsJson, ":", pos);
        if (pos < 0) return defaultValue;
        pos++;

        // 空白スキップ
        int len = StringLen(paramsJson);
        while (pos < len) {
            ushort c = StringGetCharacter(paramsJson, pos);
            if (c != ' ' && c != '\t') break;
            pos++;
        }

        // 数値の開始位置
        int start = pos;
        while (pos < len) {
            ushort c = StringGetCharacter(paramsJson, pos);
            if ((c >= '0' && c <= '9') || c == '.' || c == '-' || c == '+') {
                pos++;
            } else {
                break;
            }
        }

        string numStr = StringSubstr(paramsJson, start, pos - start);
        return StringToDouble(numStr);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から整数を取得                                           |
    //+------------------------------------------------------------------+
    int GetParamInt(string paramsJson, string key, int defaultValue) {
        return (int)GetParamDouble(paramsJson, key, (double)defaultValue);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から文字列を取得                                          |
    //+------------------------------------------------------------------+
    string GetParamString(string paramsJson, string key, string defaultValue) {
        string searchKey = "\"" + key + "\"";
        int pos = StringFind(paramsJson, searchKey);
        if (pos < 0) return defaultValue;

        // コロンを探す
        pos = StringFind(paramsJson, ":", pos);
        if (pos < 0) return defaultValue;
        pos++;

        // 空白スキップ
        int len = StringLen(paramsJson);
        while (pos < len) {
            ushort c = StringGetCharacter(paramsJson, pos);
            if (c != ' ' && c != '\t') break;
            pos++;
        }

        // ダブルクォートの開始
        if (StringGetCharacter(paramsJson, pos) != '"') return defaultValue;
        pos++;

        // 文字列の終了を探す
        int start = pos;
        while (pos < len) {
            ushort c = StringGetCharacter(paramsJson, pos);
            if (c == '"') break;
            pos++;
        }

        return StringSubstr(paramsJson, start, pos - start);
    }

    //+------------------------------------------------------------------+
    //| JSON文字列から真偽値を取得                                          |
    //+------------------------------------------------------------------+
    bool GetParamBool(string paramsJson, string key, bool defaultValue) {
        string searchKey = "\"" + key + "\"";
        int pos = StringFind(paramsJson, searchKey);
        if (pos < 0) return defaultValue;

        // コロンを探す
        pos = StringFind(paramsJson, ":", pos);
        if (pos < 0) return defaultValue;
        pos++;

        // trueまたはfalseを探す
        int len = StringLen(paramsJson);
        while (pos < len) {
            ushort c = StringGetCharacter(paramsJson, pos);
            if (c != ' ' && c != '\t') break;
            pos++;
        }

        if (StringSubstr(paramsJson, pos, 4) == "true") return true;
        if (StringSubstr(paramsJson, pos, 5) == "false") return false;

        return defaultValue;
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
