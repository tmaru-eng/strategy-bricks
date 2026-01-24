//+------------------------------------------------------------------+
//|                                              JsonFormatter.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                         JSON display formatting helpers          |
//+------------------------------------------------------------------+
#ifndef JSONFORMATTER_MQH
#define JSONFORMATTER_MQH

class CJsonFormatter {
private:
    bool IsWhitespaceChar(const ushort c) {
        return (c == ' ' || c == '\t' || c == '\n' || c == '\r');
    }

    void SkipWhitespace(const string &text, int &pos) {
        int len = StringLen(text);
        while (pos < len && IsWhitespaceChar(StringGetCharacter(text, pos))) {
            pos++;
        }
    }

    bool ParseJsonStringLiteral(const string &text, int &pos, string &out) {
        int len = StringLen(text);
        if (pos >= len || StringGetCharacter(text, pos) != '"') {
            return false;
        }

        pos++;  // skip opening quote
        out = "";
        bool escaped = false;

        while (pos < len) {
            ushort c = StringGetCharacter(text, pos);
            if (escaped) {
                switch (c) {
                    case 'n': out += "\n"; break;
                    case 'r': out += "\r"; break;
                    case 't': out += "\t"; break;
                    case '"': out += "\""; break;
                    case '\\': out += "\\"; break;
                    default: out += CharToString((uchar)c); break;
                }
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                pos++;  // skip closing quote
                return true;
            } else {
                out += CharToString((uchar)c);
            }
            pos++;
        }

        return false;
    }

    string ParseJsonValueLiteral(const string &text, int &pos) {
        int len = StringLen(text);
        SkipWhitespace(text, pos);
        if (pos >= len) return "";

        ushort c = StringGetCharacter(text, pos);
        if (c == '"') {
            string value = "";
            if (ParseJsonStringLiteral(text, pos, value)) {
                return value;
            }
            return "";
        }

        if (c == '{' || c == '[') {
            int start = pos;
            int depth = 0;
            bool inString = false;
            bool escaped = false;

            while (pos < len) {
                c = StringGetCharacter(text, pos);
                if (inString) {
                    if (escaped) {
                        escaped = false;
                    } else if (c == '\\') {
                        escaped = true;
                    } else if (c == '"') {
                        inString = false;
                    }
                } else {
                    if (c == '"') {
                        inString = true;
                    } else if (c == '{' || c == '[') {
                        depth++;
                    } else if (c == '}' || c == ']') {
                        depth--;
                        if (depth == 0) {
                            pos++;
                            break;
                        }
                        if (depth < 0) {
                            break;
                        }
                    }
                }
                pos++;
            }

            string value = StringSubstr(text, start, pos - start);
            StringTrimLeft(value);
            StringTrimRight(value);
            return value;
        }

        int start = pos;
        while (pos < len) {
            c = StringGetCharacter(text, pos);
            if (c == ',' || c == '}') {
                break;
            }
            pos++;
        }
        string value = StringSubstr(text, start, pos - start);
        StringTrimLeft(value);
        StringTrimRight(value);
        return value;
    }

public:
    string FormatParamsJsonForDisplay(const string &json) {
        string trimmed = json;
        StringTrimLeft(trimmed);
        StringTrimRight(trimmed);
        if (trimmed == "") return "";
        if (StringGetCharacter(trimmed, 0) != '{') {
            return trimmed;
        }

        int len = StringLen(trimmed);
        int pos = 1;  // skip '{'
        string result = "";
        int pairCount = 0;

        while (pos < len) {
            SkipWhitespace(trimmed, pos);
            if (pos >= len) break;
            if (StringGetCharacter(trimmed, pos) == '}') break;

            string key = "";
            if (!ParseJsonStringLiteral(trimmed, pos, key)) {
                return trimmed;
            }

            SkipWhitespace(trimmed, pos);
            if (pos >= len || StringGetCharacter(trimmed, pos) != ':') {
                return trimmed;
            }
            pos++;  // skip ':'

            string value = ParseJsonValueLiteral(trimmed, pos);
            if (pairCount > 0) {
                result += "\n";
            }
            result += key + ": " + value;
            pairCount++;

            SkipWhitespace(trimmed, pos);
            if (pos < len && StringGetCharacter(trimmed, pos) == ',') {
                pos++;
                continue;
            }
            if (pos < len && StringGetCharacter(trimmed, pos) == '}') {
                break;
            }
        }

        return result;
    }
};

#endif // JSONFORMATTER_MQH
