//+------------------------------------------------------------------+
//|                                                   JsonParser.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                              JSON解析ユーティリティ                 |
//+------------------------------------------------------------------+
#ifndef JSONPARSER_MQH
#define JSONPARSER_MQH

//+------------------------------------------------------------------+
//| JSON値構造体                                                       |
//+------------------------------------------------------------------+
struct JsonValue {
    string stringValue;
    double numberValue;
    bool   boolValue;
    bool   isNull;
    bool   isString;
    bool   isNumber;
    bool   isBool;
    bool   isArray;
    bool   isObject;

    void Reset() {
        stringValue = "";
        numberValue = 0;
        boolValue = false;
        isNull = false;
        isString = false;
        isNumber = false;
        isBool = false;
        isArray = false;
        isObject = false;
    }
};

//+------------------------------------------------------------------+
//| JSONパーサークラス                                                  |
//| シンプルな実装（strategy_config.jsonの解析に特化）                    |
//+------------------------------------------------------------------+
class CJsonParser {
private:
    string m_json;
    int    m_pos;
    int    m_len;

    //--- 空白スキップ
    void SkipWhitespace() {
        while (m_pos < m_len) {
            ushort c = StringGetCharacter(m_json, m_pos);
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                m_pos++;
            } else {
                break;
            }
        }
    }

    //--- 現在の文字を取得
    ushort CurrentChar() {
        if (m_pos >= m_len) return 0;
        return StringGetCharacter(m_json, m_pos);
    }

    //--- 文字列の解析
    string ParseString() {
        if (CurrentChar() != '"') return "";
        m_pos++;  // skip opening quote

        string result = "";
        bool escaped = false;

        while (m_pos < m_len) {
            ushort c = StringGetCharacter(m_json, m_pos);

            if (escaped) {
                switch (c) {
                    case 'n': result += "\n"; break;
                    case 'r': result += "\r"; break;
                    case 't': result += "\t"; break;
                    case '"': result += "\""; break;
                    case '\\': result += "\\"; break;
                    default: result += CharToString((uchar)c); break;
                }
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                m_pos++;  // skip closing quote
                return result;
            } else {
                result += CharToString((uchar)c);
            }
            m_pos++;
        }
        return result;
    }

    //--- 数値の解析
    double ParseNumber() {
        int start = m_pos;
        bool hasDecimal = false;

        while (m_pos < m_len) {
            ushort c = CurrentChar();
            if (c >= '0' && c <= '9') {
                m_pos++;
            } else if (c == '.' && !hasDecimal) {
                hasDecimal = true;
                m_pos++;
            } else if (c == '-' || c == '+') {
                m_pos++;
            } else if (c == 'e' || c == 'E') {
                m_pos++;
            } else {
                break;
            }
        }

        string numStr = StringSubstr(m_json, start, m_pos - start);
        return StringToDouble(numStr);
    }

    //--- 真偽値の解析
    bool ParseBool() {
        if (StringSubstr(m_json, m_pos, 4) == "true") {
            m_pos += 4;
            return true;
        }
        if (StringSubstr(m_json, m_pos, 5) == "false") {
            m_pos += 5;
            return false;
        }
        return false;
    }

    //--- nullの解析
    bool ParseNull() {
        if (StringSubstr(m_json, m_pos, 4) == "null") {
            m_pos += 4;
            return true;
        }
        return false;
    }

public:
    //--- コンストラクタ
    CJsonParser() {
        m_json = "";
        m_pos = 0;
        m_len = 0;
    }

    //--- JSON文字列を設定
    void SetJson(string json) {
        m_json = json;
        m_pos = 0;
        m_len = StringLen(json);
    }

    //--- 位置をリセット
    void Reset() {
        m_pos = 0;
    }

    //+------------------------------------------------------------------+
    //| オブジェクトから文字列値を取得                                      |
    //+------------------------------------------------------------------+
    string GetString(string key, string defaultValue = "") {
        int keyPos = FindKey(key);
        if (keyPos < 0) return defaultValue;

        m_pos = keyPos;
        SkipWhitespace();

        if (CurrentChar() == '"') {
            return ParseString();
        }
        return defaultValue;
    }

    //+------------------------------------------------------------------+
    //| オブジェクトから数値を取得                                         |
    //+------------------------------------------------------------------+
    double GetDouble(string key, double defaultValue = 0.0) {
        int keyPos = FindKey(key);
        if (keyPos < 0) return defaultValue;

        m_pos = keyPos;
        SkipWhitespace();

        ushort c = CurrentChar();
        if ((c >= '0' && c <= '9') || c == '-' || c == '+') {
            return ParseNumber();
        }
        return defaultValue;
    }

    //+------------------------------------------------------------------+
    //| オブジェクトから整数を取得                                         |
    //+------------------------------------------------------------------+
    int GetInt(string key, int defaultValue = 0) {
        return (int)GetDouble(key, (double)defaultValue);
    }

    //+------------------------------------------------------------------+
    //| オブジェクトから真偽値を取得                                        |
    //+------------------------------------------------------------------+
    bool GetBool(string key, bool defaultValue = false) {
        int keyPos = FindKey(key);
        if (keyPos < 0) return defaultValue;

        m_pos = keyPos;
        SkipWhitespace();

        if (StringSubstr(m_json, m_pos, 4) == "true") {
            m_pos += 4;
            return true;
        }
        if (StringSubstr(m_json, m_pos, 5) == "false") {
            m_pos += 5;
            return false;
        }
        return defaultValue;
    }

    //+------------------------------------------------------------------+
    //| キーの位置を検索（値の開始位置を返す）                               |
    //+------------------------------------------------------------------+
    int FindKey(string key) {
        string searchKey = "\"" + key + "\"";
        int pos = StringFind(m_json, searchKey, 0);

        while (pos >= 0) {
            // コロンを探す
            int colonPos = pos + StringLen(searchKey);
            while (colonPos < m_len) {
                ushort c = StringGetCharacter(m_json, colonPos);
                if (c == ':') {
                    return colonPos + 1;  // コロンの次の位置
                } else if (c != ' ' && c != '\t' && c != '\n' && c != '\r') {
                    break;  // コロン以外の文字が来たら不正
                }
                colonPos++;
            }
            // 次のキーを検索
            pos = StringFind(m_json, searchKey, pos + 1);
        }
        return -1;
    }

    //+------------------------------------------------------------------+
    //| オブジェクト文字列を抽出                                           |
    //+------------------------------------------------------------------+
    string ExtractObject(string key) {
        int keyPos = FindKey(key);
        if (keyPos < 0) return "";

        m_pos = keyPos;
        SkipWhitespace();

        if (CurrentChar() != '{') return "";

        int depth = 0;
        int start = m_pos;

        while (m_pos < m_len) {
            ushort c = CurrentChar();
            if (c == '{') depth++;
            else if (c == '}') {
                depth--;
                if (depth == 0) {
                    m_pos++;
                    return StringSubstr(m_json, start, m_pos - start);
                }
            } else if (c == '"') {
                ParseString();  // 文字列をスキップ
                continue;
            }
            m_pos++;
        }
        return "";
    }

    //+------------------------------------------------------------------+
    //| 配列文字列を抽出                                                   |
    //+------------------------------------------------------------------+
    string ExtractArray(string key) {
        int keyPos = FindKey(key);
        if (keyPos < 0) return "";

        m_pos = keyPos;
        SkipWhitespace();

        if (CurrentChar() != '[') return "";

        int depth = 0;
        int start = m_pos;

        while (m_pos < m_len) {
            ushort c = CurrentChar();
            if (c == '[') depth++;
            else if (c == ']') {
                depth--;
                if (depth == 0) {
                    m_pos++;
                    return StringSubstr(m_json, start, m_pos - start);
                }
            } else if (c == '"') {
                ParseString();  // 文字列をスキップ
                continue;
            }
            m_pos++;
        }
        return "";
    }

    //+------------------------------------------------------------------+
    //| 配列からオブジェクトを抽出（インデックス指定）                        |
    //+------------------------------------------------------------------+
    string ExtractArrayElement(string arrayJson, int index) {
        int pos = 1;  // skip '['
        int len = StringLen(arrayJson);
        int currentIndex = 0;

        while (pos < len) {
            // 空白スキップ
            while (pos < len) {
                ushort c = StringGetCharacter(arrayJson, pos);
                if (c != ' ' && c != '\t' && c != '\n' && c != '\r') break;
                pos++;
            }

            if (pos >= len) break;

            ushort c = StringGetCharacter(arrayJson, pos);
            if (c == ']') break;
            if (c == ',') {
                pos++;
                continue;
            }

            // オブジェクトの開始
            if (c == '{') {
                int depth = 0;
                int start = pos;

                while (pos < len) {
                    c = StringGetCharacter(arrayJson, pos);
                    if (c == '{') depth++;
                    else if (c == '}') {
                        depth--;
                        if (depth == 0) {
                            pos++;
                            if (currentIndex == index) {
                                return StringSubstr(arrayJson, start, pos - start);
                            }
                            currentIndex++;
                            break;
                        }
                    } else if (c == '"') {
                        // 文字列をスキップ
                        pos++;
                        while (pos < len) {
                            c = StringGetCharacter(arrayJson, pos);
                            if (c == '"' && StringGetCharacter(arrayJson, pos - 1) != '\\') {
                                break;
                            }
                            pos++;
                        }
                    }
                    pos++;
                }
            } else {
                pos++;
            }
        }
        return "";
    }

    //+------------------------------------------------------------------+
    //| 配列の要素数を取得                                                 |
    //+------------------------------------------------------------------+
    int GetArrayLength(string arrayJson) {
        int count = 0;
        int pos = 1;  // skip '['
        int len = StringLen(arrayJson);
        int depth = 0;

        while (pos < len) {
            ushort c = StringGetCharacter(arrayJson, pos);

            if (c == '{' || c == '[') {
                if (depth == 0 && c == '{') count++;
                depth++;
            } else if (c == '}' || c == ']') {
                depth--;
            } else if (c == '"') {
                // 文字列をスキップ
                pos++;
                while (pos < len) {
                    c = StringGetCharacter(arrayJson, pos);
                    if (c == '"' && StringGetCharacter(arrayJson, pos - 1) != '\\') {
                        break;
                    }
                    pos++;
                }
            }
            pos++;
        }
        return count;
    }
};

//+------------------------------------------------------------------+
//| JSONオブジェクトパーサー（単一オブジェクト用）                          |
//+------------------------------------------------------------------+
class CJsonObject {
private:
    string m_json;
    CJsonParser m_parser;

public:
    CJsonObject() {
        m_json = "";
    }

    void SetJson(string json) {
        m_json = json;
        m_parser.SetJson(json);
    }

    string GetJson() const {
        return m_json;
    }

    string GetString(string key, string defaultValue = "") {
        m_parser.SetJson(m_json);
        return m_parser.GetString(key, defaultValue);
    }

    double GetDouble(string key, double defaultValue = 0.0) {
        m_parser.SetJson(m_json);
        return m_parser.GetDouble(key, defaultValue);
    }

    int GetInt(string key, int defaultValue = 0) {
        m_parser.SetJson(m_json);
        return m_parser.GetInt(key, defaultValue);
    }

    bool GetBool(string key, bool defaultValue = false) {
        m_parser.SetJson(m_json);
        return m_parser.GetBool(key, defaultValue);
    }

    string ExtractObject(string key) {
        m_parser.SetJson(m_json);
        return m_parser.ExtractObject(key);
    }

    string ExtractArray(string key) {
        m_parser.SetJson(m_json);
        return m_parser.ExtractArray(key);
    }
};

#endif // JSONPARSER_MQH
