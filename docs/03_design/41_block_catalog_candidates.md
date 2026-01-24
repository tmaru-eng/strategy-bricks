# ブロック候補一覧（調査メモ）

## 0. 目的
block_catalog.json に追加すべきブロック候補を、MQL5公式ドキュメントに基づき整理する。
GUI（paramsSchema）→ EA（IndicatorCache）への実装順序で利用する。

## 1. 前提
- 時間足は M1 固定（`globalGuards.timeframe = "M1"`）。
- 判定は確定足のみ（shift=1）。
- Indicatorパラメータは MQL5 公式 docs の関数シグネチャに準拠する。

## 2. 参照（公式ドキュメント）
- iMA: https://www.mql5.com/ja/docs/indicators/ima / https://www.mql5.com/en/docs/indicators/ima
- iRSI: https://www.mql5.com/ja/docs/indicators/irsi / https://www.mql5.com/en/docs/indicators/irsi
- iCCI: https://www.mql5.com/ja/docs/indicators/icci / https://www.mql5.com/en/docs/indicators/icci
- iBands: https://www.mql5.com/ja/docs/indicators/ibands / https://www.mql5.com/en/docs/indicators/ibands
- iMACD: https://www.mql5.com/ja/docs/indicators/imacd / https://www.mql5.com/en/docs/indicators/imacd
- iStochastic: https://www.mql5.com/ja/docs/indicators/istochastic / https://www.mql5.com/en/docs/indicators/istochastic
- iATR: https://www.mql5.com/ja/docs/indicators/iatr / https://www.mql5.com/en/docs/indicators/iatr
- iADX: https://www.mql5.com/ja/docs/indicators/iadx / https://www.mql5.com/en/docs/indicators/iadx
- iStdDev: https://www.mql5.com/ja/docs/indicators/istddev / https://www.mql5.com/en/docs/indicators/istddev
- iEnvelopes: https://www.mql5.com/ja/docs/indicators/ienvelopes / https://www.mql5.com/en/docs/indicators/ienvelopes
- iMomentum: https://www.mql5.com/ja/docs/indicators/imomentum / https://www.mql5.com/en/docs/indicators/imomentum
- iOsMA: https://www.mql5.com/ja/docs/indicators/iosma / https://www.mql5.com/en/docs/indicators/iosma
- iIchimoku: https://www.mql5.com/ja/docs/indicators/iichimoku / https://www.mql5.com/en/docs/indicators/iichimoku
- iSAR: https://www.mql5.com/ja/docs/indicators/isar / https://www.mql5.com/en/docs/indicators/isar
- iRVI: https://www.mql5.com/ja/docs/indicators/irvi / https://www.mql5.com/en/docs/indicators/irvi
- iWPR: https://www.mql5.com/ja/docs/indicators/iwpr / https://www.mql5.com/en/docs/indicators/iwpr
- iMFI: https://www.mql5.com/ja/docs/indicators/imfi / https://www.mql5.com/en/docs/indicators/imfi
- iOBV: https://www.mql5.com/ja/docs/indicators/iobv / https://www.mql5.com/en/docs/indicators/iobv
- iAlligator: https://www.mql5.com/ja/docs/indicators/ialligator / https://www.mql5.com/en/docs/indicators/ialligator
- iForce: https://www.mql5.com/ja/docs/indicators/iforce / https://www.mql5.com/en/docs/indicators/iforce
- iDeMarker: https://www.mql5.com/ja/docs/indicators/idemarker / https://www.mql5.com/en/docs/indicators/idemarker
- iFractals: https://www.mql5.com/ja/docs/indicators/ifractals / https://www.mql5.com/en/docs/indicators/ifractals
- iBearsPower: https://www.mql5.com/ja/docs/indicators/ibearspower / https://www.mql5.com/en/docs/indicators/ibearspower
- iBullsPower: https://www.mql5.com/ja/docs/indicators/ibullspower / https://www.mql5.com/en/docs/indicators/ibullspower

### 2.1 列挙型
- ENUM_MA_METHOD: https://www.mql5.com/ja/docs/constants/indicatorconstants/enum_ma_method / https://www.mql5.com/en/docs/constants/indicatorconstants/enum_ma_method
- ENUM_APPLIED_PRICE: https://www.mql5.com/ja/docs/constants/indicatorconstants/prices#enum_applied_price_enum / https://www.mql5.com/en/docs/constants/indicatorconstants/prices#enum_applied_price_enum
- ENUM_STO_PRICE: https://www.mql5.com/ja/docs/constants/indicatorconstants/prices#enum_sto_price_enum / https://www.mql5.com/en/docs/constants/indicatorconstants/prices#enum_sto_price_enum
- ENUM_APPLIED_VOLUME: https://www.mql5.com/ja/docs/constants/indicatorconstants/prices#enum_applied_volume_enum / https://www.mql5.com/en/docs/constants/indicatorconstants/prices#enum_applied_volume_enum
- ENUM_TIMEFRAMES: https://www.mql5.com/ja/docs/constants/chartconstants/enum_timeframes / https://www.mql5.com/en/docs/constants/chartconstants/enum_timeframes

### 2.2 時間/曜日
- TimeCurrent: https://www.mql5.com/ja/docs/dateandtime/timecurrent / https://www.mql5.com/en/docs/dateandtime/timecurrent
- TimeToStruct: https://www.mql5.com/ja/docs/dateandtime/timetostruct / https://www.mql5.com/en/docs/dateandtime/timetostruct
- MqlDateTime: https://www.mql5.com/ja/docs/constants/structures/mqldatetime / https://www.mql5.com/en/docs/constants/structures/mqldatetime

## 3. ブロック候補（カテゴリ別）

### 3.1 filter（ガード/フィルタ）
- filter.spreadMax
  - params: maxSpreadPips (number)
  - note: 既存MVP
- filter.session.timeWindow
  - params: start (HH:MM), end (HH:MM)
  - note: TimeCurrent + TimeToStruct
- filter.session.daysOfWeek
  - params: days (array of 0..6)
  - note: MqlDateTime.day_of_week
- filter.volatility.atrRange
  - params: period (int), minAtr (number), maxAtr (number)
  - doc: iATR
- filter.volatility.stddevRange
  - params: period (int), maPeriod (int), maShift (int), maMethod (enum), appliedPrice (enum), min (number), max (number)
  - doc: iStdDev

### 3.2 trend（トレンド）
- trend.maRelation
  - params: period (int), maShift (int), maMethod (enum), appliedPrice (enum), relation (above/below)
  - doc: iMA
- trend.maCross
  - params: fastPeriod (int), slowPeriod (int), maMethod (enum), appliedPrice (enum), direction (golden/dead)
  - doc: iMA
- trend.adxThreshold
  - params: period (int), adxPeriod (int), minAdx (number)
  - doc: iADX
- trend.ichimokuCloud
  - params: tenkan (int), kijun (int), senkouB (int), position (above/inside/below)
  - doc: iIchimoku
- trend.alligatorSpread
  - params: jawPeriod, jawShift, teethPeriod, teethShift, lipsPeriod, lipsShift, maMethod (enum), appliedPrice (enum), minSpread (number)
  - doc: iAlligator

### 3.3 trigger（トリガー）
- trigger.bbReentry
  - params: period (int), deviation (number), bandsShift (int), appliedPrice (enum)
  - doc: iBands
- trigger.bbBreakout
  - params: period (int), deviation (number), bandsShift (int), appliedPrice (enum), direction (upper/lower)
  - doc: iBands
- trigger.macdCross
  - params: fastEma (int), slowEma (int), signal (int), appliedPrice (enum), direction (golden/dead)
  - doc: iMACD
- trigger.stochCross
  - params: kPeriod (int), dPeriod (int), slowing (int), maMethod (enum), priceField (enum), direction (golden/dead)
  - doc: iStochastic
- trigger.rsiLevel
  - params: period (int), appliedPrice (enum), threshold (number), mode (overbought/oversold)
  - doc: iRSI
- trigger.cciLevel
  - params: period (int), appliedPrice (enum), threshold (number), mode (overbought/oversold)
  - doc: iCCI
- trigger.wprLevel
  - params: period (int), threshold (number), mode (overbought/oversold)
  - doc: iWPR
- trigger.sarFlip
  - params: step (number), maximum (number)
  - doc: iSAR
- trigger.fractalBreak
  - params: direction (up/down)
  - doc: iFractals
- trigger.rviCross
  - params: period (int), maPeriod (int), direction (golden/dead)
  - doc: iRVI

### 3.4 osc/volume（オシレーター/出来高補助）
- osc.momentum
  - params: period (int), appliedPrice (enum)
  - doc: iMomentum
- osc.osma
  - params: fastEma (int), slowEma (int), signal (int), appliedPrice (enum)
  - doc: iOsMA
- osc.mfiLevel
  - params: period (int), maPeriod (int), appliedVolume (enum), threshold (number), mode (overbought/oversold)
  - doc: iMFI
- osc.obvTrend
  - params: appliedVolume (enum), direction (up/down)
  - doc: iOBV
- osc.forceIndex
  - params: maPeriod (int), maMethod (enum), appliedVolume (enum)
  - doc: iForce
- osc.demarkerLevel
  - params: period (int), maPeriod (int), threshold (number), mode (overbought/oversold)
  - doc: iDeMarker
- osc.bearsPower
  - params: period (int), maPeriod (int)
  - doc: iBearsPower
- osc.bullsPower
  - params: period (int), maPeriod (int)
  - doc: iBullsPower

### 3.5 bar/price（バー条件）
※ 価格系列（Open/High/Low/Close）を使う条件。仕様化は別途。
- bar.closeAboveOpen / bar.closeBelowOpen
- bar.highBreakout / bar.lowBreakout（N本高値/安値）
- bar.rangeMinMax（実体/ヒゲ/全体の範囲）
- bar.engulfing / bar.inside / bar.outside
- bar.closePosition（終値が高値/安値レンジのx%）

## 4. GUI/EA実装方針メモ
- GUI: paramsSchema をこの表に合わせて定義 → Propertyで自動生成。
- EA: IndicatorCache に iXXX ハンドル生成を追加し、shift=1 で参照。
- 追加候補は typeId 先行で定義し、block_catalog.json の段階的拡張を想定。
