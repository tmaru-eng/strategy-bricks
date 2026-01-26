# ブロック候補一覧（調査メモ）

## 0. 目的
block_catalog.json に追加すべきブロック候補を、MQL5公式ドキュメントに基づき整理する。
GUI（paramsSchema）→ EA（IndicatorCache）への実装順序で利用する。

## 1. 前提
- 時間足は M1 固定（`globalGuards.timeframe = "M1"`）。
- 判定は確定足のみ（shift=1）。
- Indicatorパラメータは MQL5 公式 docs の関数シグネチャに準拠する。

## 2. 参照（公式ドキュメント）
- iMA: [ja](https://www.mql5.com/ja/docs/indicators/ima) / [en](https://www.mql5.com/en/docs/indicators/ima)
- iRSI: [ja](https://www.mql5.com/ja/docs/indicators/irsi) / [en](https://www.mql5.com/en/docs/indicators/irsi)
- iCCI: [ja](https://www.mql5.com/ja/docs/indicators/icci) / [en](https://www.mql5.com/en/docs/indicators/icci)
- iBands: [ja](https://www.mql5.com/ja/docs/indicators/ibands) / [en](https://www.mql5.com/en/docs/indicators/ibands)
- iMACD: [ja](https://www.mql5.com/ja/docs/indicators/imacd) / [en](https://www.mql5.com/en/docs/indicators/imacd)
- iStochastic: [ja](https://www.mql5.com/ja/docs/indicators/istochastic) / [en](https://www.mql5.com/en/docs/indicators/istochastic)
- iATR: [ja](https://www.mql5.com/ja/docs/indicators/iatr) / [en](https://www.mql5.com/en/docs/indicators/iatr)
- iADX: [ja](https://www.mql5.com/ja/docs/indicators/iadx) / [en](https://www.mql5.com/en/docs/indicators/iadx)
- iStdDev: [ja](https://www.mql5.com/ja/docs/indicators/istddev) / [en](https://www.mql5.com/en/docs/indicators/istddev)
- iEnvelopes: [ja](https://www.mql5.com/ja/docs/indicators/ienvelopes) / [en](https://www.mql5.com/en/docs/indicators/ienvelopes)
- iMomentum: [ja](https://www.mql5.com/ja/docs/indicators/imomentum) / [en](https://www.mql5.com/en/docs/indicators/imomentum)
- iOsMA: [ja](https://www.mql5.com/ja/docs/indicators/iosma) / [en](https://www.mql5.com/en/docs/indicators/iosma)
- iIchimoku: [ja](https://www.mql5.com/ja/docs/indicators/iichimoku) / [en](https://www.mql5.com/en/docs/indicators/iichimoku)
- iSAR: [ja](https://www.mql5.com/ja/docs/indicators/isar) / [en](https://www.mql5.com/en/docs/indicators/isar)
- iRVI: [ja](https://www.mql5.com/ja/docs/indicators/irvi) / [en](https://www.mql5.com/en/docs/indicators/irvi)
- iWPR: [ja](https://www.mql5.com/ja/docs/indicators/iwpr) / [en](https://www.mql5.com/en/docs/indicators/iwpr)
- iMFI: [ja](https://www.mql5.com/ja/docs/indicators/imfi) / [en](https://www.mql5.com/en/docs/indicators/imfi)
- iOBV: [ja](https://www.mql5.com/ja/docs/indicators/iobv) / [en](https://www.mql5.com/en/docs/indicators/iobv)
- iAlligator: [ja](https://www.mql5.com/ja/docs/indicators/ialligator) / [en](https://www.mql5.com/en/docs/indicators/ialligator)
- iForce: [ja](https://www.mql5.com/ja/docs/indicators/iforce) / [en](https://www.mql5.com/en/docs/indicators/iforce)
- iDeMarker: [ja](https://www.mql5.com/ja/docs/indicators/idemarker) / [en](https://www.mql5.com/en/docs/indicators/idemarker)
- iFractals: [ja](https://www.mql5.com/ja/docs/indicators/ifractals) / [en](https://www.mql5.com/en/docs/indicators/ifractals)
- iBearsPower: [ja](https://www.mql5.com/ja/docs/indicators/ibearspower) / [en](https://www.mql5.com/en/docs/indicators/ibearspower)
- iBullsPower: [ja](https://www.mql5.com/ja/docs/indicators/ibullspower) / [en](https://www.mql5.com/en/docs/indicators/ibullspower)

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
  - params: symbol (string), period (ENUM_TIMEFRAMES), ma_period (int), appliedVolume (ENUM_APPLIED_VOLUME)
  - note: uses threshold and mode for logic
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


## 5. 追加ブロック候補（既存EA機能からの拡張）

### 5.1 lot（ロット管理）
- lot.fixed
  - params: lotSize (number)
  - note: 既存MVP
- lot.riskPercent
  - params: riskPercent (number), useMarginFree (boolean), minLot (number), maxLot (number)
  - note: 口座残高または証拠金の指定割合でロット計算
  - 対応: MoneyManagementType=1（資金割合）
- lot.slRisk
  - params: riskPercent (number), slPips (number), minLot (number), maxLot (number)
  - note: SL距離からの損失割合でロット計算
  - 対応: MoneyManagementType=2（SL損失割合）
- lot.monteCarlo
  - params: ratio (int), maxLot (number), sequence (array)
  - note: モンテカルロ法によるロット調整
  - 対応: useMonteCarloMethod
- lot.martingale
  - params: multiplier (int), maxLot (number), resetOnWin (boolean)
  - note: マーチンゲール（倍々）方式

### 5.2 exit（決済管理）
- exit.none
  - note: 既存MVP（SL/TPのみ）
- exit.trail
  - params: startPips (number), trailPips (number), useAtr (boolean), atrRatio (number)
  - note: トレーリングストップ
  - 対応: TrailSet_Def
- exit.breakEven
  - params: triggerPips (number), offsetPips (number)
  - note: 建値決済（指定pips利益で建値に移動）
  - 対応: isBreakEven
- exit.averageProfit
  - params: profitPips (number), useAtr (boolean), atrRatio (number)
  - note: 平均利益決済（複数ポジションの平均利益が指定値以上で全決済）
  - 対応: isAverageProfit, AverageProfitPips
- exit.partialClose
  - params: limitPositions (int), keepPositions (int), profitThreshold (number)
  - note: 一部ポジション決済（指定数を残して建値決済）
  - 対応: isPartialClose, PositionsToKeep
- exit.oppositeSignal
  - params: enabled (boolean)
  - note: 反対シグナル発生時に決済
  - 対応: isCheckPositionClose
- exit.weekendClose
  - params: dayOfWeek (int), closeTime (string), warningTime (string)
  - note: 週末強制決済
  - 対応: isWeekEndExit, WeekEndExitTime
- exit.weekdayClose
  - params: closeTime (string)
  - note: 平日指定時刻決済
  - 対応: isWeekDayExit, WeekDayExitTime

### 5.3 nanpin（ナンピン管理）
- nanpin.off
  - note: 既存MVP
- nanpin.fixed
  - params: intervalPips (number), maxCount (int), lotAdjustMethod (enum)
  - note: 固定間隔ナンピン
  - 対応: AveragingDownPips_Def, maxAveragingDownCount
- nanpin.atr
  - params: atrRatio (number), maxCount (int), lotAdjustMethod (enum)
  - note: ATRベース間隔ナンピン
  - 対応: isAutoAveragingDownPips, AveragingDownPips_Ratio
- nanpin.lotAdjust
  - params: method (enum: fixed/double/monteCarlo/addInitial), fixedIncrement (number), multiplier (int)
  - note: ナンピン時のロット調整方法
  - 対応: LotSizeAdjustmentMethod, incrementLot_Fixed, incrementLot_Multiplier

### 5.4 risk（リスク管理）
- risk.fixedSLTP
  - note: 既存MVP
- risk.atrBased
  - params: atrPeriod (int), atrTimeframe (enum), atrRatio (number), buyTpRatio (number), buySlRatio (number), sellTpRatio (number), sellSlRatio (number)
  - note: ATRベースのSL/TP設定
  - 対応: isAutoValue, ATR_Period, ATR_Ratio, Buy_Target_Ratio, Buy_Stoploss_Ratio

### 5.5 trend（トレンド判定追加）
- trend.bbSigma
  - params: period (int), deviation (number), minSigma (number), maxSigma (number)
  - note: ボリンジャーバンドの標準偏差（σ）判定
  - 対応: Trend_Judge=2
- trend.bbWidth
  - params: period (int), deviation (number), minWidth (number)
  - note: ボリンジャーバンドの広がり判定
  - 対応: Trend_Judge=3
- trend.maAngle
  - params: period (int), maMethod (enum), appliedPrice (enum), minAngle (number)
  - note: 移動平均線の角度判定
  - 対応: Trend_Judge=6
- trend.ichimokuSanyaku
  - params: tenkan (int), kijun (int), senkouB (int), mode (enum: all/two/one)
  - note: 一目均衡表の三役好転/逆転
  - 対応: Trend_Judge=9

### 5.6 trigger（トリガー追加）
- trigger.bbTouch
  - params: period (int), deviation (number), appliedPrice (enum)
  - note: ボリンジャーバンドのσラインタッチ
  - 対応: Trigger_Judge=1
- trigger.candleEngulfing
  - params: direction (enum: bullish/bearish)
  - note: エンゴルフィンバー
  - 対応: Trigger_Judge=4
- trigger.candleHarami
  - params: direction (enum: bullish/bearish)
  - note: はらみ足
  - 対応: Trigger_Judge=6
- trigger.candleOutside
  - params: direction (enum: bullish/bearish)
  - note: アウトサイドバー
  - 対応: Trigger_Judge=7
- trigger.candlePin
  - params: direction (enum: bullish/bearish), bodyRatio (number), wickRatio (number)
  - note: ピンバー
  - 対応: Trigger_Judge=8
- trigger.rsiReversal
  - params: period (int), upperThreshold (number), lowerThreshold (number)
  - note: RSI反転（70以上から反転売り、30以下から反転買い）
  - 対応: Trigger_Judge=9

### 5.7 filter（フィルタ追加）
- filter.bbSqueeze
  - params: period (int), deviation (number), squeezeThreshold (number)
  - note: ボリンジャーバンドのスクイーズ判定
  - 対応: Band_SqueezeThreshold

## 6. 実装優先度

### 高優先度（MVP拡張）
1. lot.riskPercent - 資金管理の基本
2. exit.trail - トレーリングストップ
3. exit.breakEven - 建値決済
4. exit.weekendClose - 週末決済
5. nanpin.fixed - ナンピン基本機能
6. risk.atrBased - ATRベースリスク管理

### 中優先度（戦略拡張）
7. lot.monteCarlo - モンテカルロ法
8. exit.averageProfit - 平均利益決済
9. exit.partialClose - 一部決済
10. nanpin.atr - ATRベースナンピン
11. trigger.candleEngulfing - ローソク足パターン
12. trigger.bbTouch - BBタッチ

### 低優先度（高度な機能）
13. lot.martingale - マーチンゲール
14. trend.maAngle - MA角度
15. trend.ichimokuSanyaku - 一目三役
16. その他ローソク足パターン

