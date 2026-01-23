//+------------------------------------------------------------------+
//|                                          ObjectNameManager.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|                                   チャートオブジェクト名管理       |
//+------------------------------------------------------------------+
#ifndef OBJECTNAMEMANAGER_MQH
#define OBJECTNAMEMANAGER_MQH

//+------------------------------------------------------------------+
//| オブジェクト名プレフィックス                                        |
//+------------------------------------------------------------------+
#define VIS_PREFIX           "SB_VIS_"
#define VIS_ARROW_PREFIX     "SB_VIS_ARROW_"
#define VIS_LABEL_PREFIX     "SB_VIS_LABEL_"
#define VIS_LINE_PREFIX      "SB_VIS_LINE_"
#define VIS_PANEL_PREFIX     "SB_VIS_PANEL_"

//+------------------------------------------------------------------+
//| ObjectNameManagerクラス                                           |
//| チャートオブジェクト名の生成・管理                                   |
//+------------------------------------------------------------------+
class CObjectNameManager {
public:
    //--- コンストラクタ
    CObjectNameManager() {
    }

    //+------------------------------------------------------------------+
    //| シグナル矢印名生成                                                 |
    //+------------------------------------------------------------------+
    string GetArrowName(datetime time, bool isBuy) {
        string dir = isBuy ? "BUY" : "SELL";
        return VIS_ARROW_PREFIX + dir + "_" + IntegerToString((long)time);
    }

    //+------------------------------------------------------------------+
    //| ブロックラベル名生成                                               |
    //+------------------------------------------------------------------+
    string GetBlockLabelName(int index) {
        return VIS_LABEL_PREFIX + "BLOCK_" + IntegerToString(index);
    }

    //+------------------------------------------------------------------+
    //| 状態パネルラベル名生成                                             |
    //+------------------------------------------------------------------+
    string GetStatusLabelName(int row) {
        return VIS_PANEL_PREFIX + "STATUS_" + IntegerToString(row);
    }

    //+------------------------------------------------------------------+
    //| MAライン名生成                                                     |
    //+------------------------------------------------------------------+
    string GetMALineName(int period, string maType) {
        return VIS_LINE_PREFIX + "MA_" + IntegerToString(period) + "_" + maType;
    }

    //+------------------------------------------------------------------+
    //| BBライン名生成（上中下バンド）                                      |
    //+------------------------------------------------------------------+
    string GetBBLineName(int period, double deviation, string band) {
        return VIS_LINE_PREFIX + "BB_" + IntegerToString(period) + "_" +
               DoubleToString(deviation, 1) + "_" + band;
    }

    //+------------------------------------------------------------------+
    //| プレフィックス指定でオブジェクトを一括削除                           |
    //+------------------------------------------------------------------+
    int DeleteObjectsByPrefix(long chartId, string prefix) {
        int deleted = 0;
        int total = ObjectsTotal(chartId);

        // 後ろから削除（インデックスずれ防止）
        for (int i = total - 1; i >= 0; i--) {
            string name = ObjectName(chartId, i);
            if (StringFind(name, prefix) == 0) {
                if (ObjectDelete(chartId, name)) {
                    deleted++;
                }
            }
        }
        return deleted;
    }

    //+------------------------------------------------------------------+
    //| 全ての可視化オブジェクトを削除                                      |
    //+------------------------------------------------------------------+
    int DeleteAllVisualizationObjects(long chartId) {
        return DeleteObjectsByPrefix(chartId, VIS_PREFIX);
    }

    //+------------------------------------------------------------------+
    //| シグナル矢印のみ削除                                               |
    //+------------------------------------------------------------------+
    int DeleteAllArrows(long chartId) {
        return DeleteObjectsByPrefix(chartId, VIS_ARROW_PREFIX);
    }

    //+------------------------------------------------------------------+
    //| ラベルのみ削除                                                     |
    //+------------------------------------------------------------------+
    int DeleteAllLabels(long chartId) {
        return DeleteObjectsByPrefix(chartId, VIS_LABEL_PREFIX);
    }

    //+------------------------------------------------------------------+
    //| ラインのみ削除                                                     |
    //+------------------------------------------------------------------+
    int DeleteAllLines(long chartId) {
        return DeleteObjectsByPrefix(chartId, VIS_LINE_PREFIX);
    }

    //+------------------------------------------------------------------+
    //| パネルのみ削除                                                     |
    //+------------------------------------------------------------------+
    int DeleteAllPanels(long chartId) {
        return DeleteObjectsByPrefix(chartId, VIS_PANEL_PREFIX);
    }

    //+------------------------------------------------------------------+
    //| 矢印名から時刻を抽出                                                |
    //+------------------------------------------------------------------+
    long ExtractTimeFromArrowName(string name) {
        // フォーマット: SB_VIS_ARROW_BUY_<timestamp> または SB_VIS_ARROW_SELL_<timestamp>
        int lastUnderscorePos = -1;
        for (int i = StringLen(name) - 1; i >= 0; i--) {
            if (StringGetCharacter(name, i) == '_') {
                lastUnderscorePos = i;
                break;
            }
        }
        if (lastUnderscorePos < 0) return 0;

        string timeStr = StringSubstr(name, lastUnderscorePos + 1);
        return StringToInteger(timeStr);
    }

    //+------------------------------------------------------------------+
    //| 古い矢印を削除（最大数を超えた分）                                   |
    //+------------------------------------------------------------------+
    int TrimOldArrows(long chartId, int maxCount) {
        // 矢印オブジェクトのみ収集
        string arrows[];
        long arrowTimes[];
        int arrowCount = 0;
        int total = ObjectsTotal(chartId);

        ArrayResize(arrows, total);
        ArrayResize(arrowTimes, total);

        for (int i = 0; i < total; i++) {
            string name = ObjectName(chartId, i);
            if (StringFind(name, VIS_ARROW_PREFIX) == 0) {
                arrows[arrowCount] = name;
                arrowTimes[arrowCount] = ExtractTimeFromArrowName(name);
                arrowCount++;
            }
        }

        ArrayResize(arrows, arrowCount);
        ArrayResize(arrowTimes, arrowCount);

        // 最大数を超えていれば古いものから削除
        int deleted = 0;
        if (arrowCount > maxCount) {
            // 時刻でソート（バブルソート、昇順 = 古い順）
            for (int i = 0; i < arrowCount - 1; i++) {
                for (int j = 0; j < arrowCount - 1 - i; j++) {
                    if (arrowTimes[j] > arrowTimes[j + 1]) {
                        // スワップ
                        long tempTime = arrowTimes[j];
                        arrowTimes[j] = arrowTimes[j + 1];
                        arrowTimes[j + 1] = tempTime;

                        string tempName = arrows[j];
                        arrows[j] = arrows[j + 1];
                        arrows[j + 1] = tempName;
                    }
                }
            }

            // 古い順から削除
            int toDelete = arrowCount - maxCount;
            for (int i = 0; i < toDelete && i < arrowCount; i++) {
                if (ObjectDelete(chartId, arrows[i])) {
                    deleted++;
                }
            }
        }

        return deleted;
    }
};

#endif // OBJECTNAMEMANAGER_MQH
