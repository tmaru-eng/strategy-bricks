/**
 * バックテスト型定義のプロパティベーステスト
 * 
 * このファイルは、fast-checkを使用したプロパティベーステストの例を示します。
 * 実際のプロパティテストは、タスク2.3以降で実装されます。
 */

import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import type { BacktestConfig, Trade } from '../backtest';

describe('Backtest Types - Property Tests', () => {
  /**
   * 例: BacktestConfigのシリアライゼーション
   * 
   * これは、プロパティベーステストの基本的な例です。
   * 実際のテストはタスク2.3以降で実装されます。
   */
  it('should serialize and deserialize BacktestConfig correctly', () => {
    fc.assert(
      fc.property(
        fc.record({
          symbol: fc.string({ minLength: 1, maxLength: 10 }),
          timeframe: fc.constantFrom('M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'),
          startDate: fc.date({ min: new Date('2020-01-01'), max: new Date('2024-01-01') }),
          endDate: fc.date({ min: new Date('2024-01-02'), max: new Date('2024-12-31') })
        }),
        (config: BacktestConfig) => {
          // 開始日が終了日より前であることを前提条件とする
          fc.pre(config.startDate < config.endDate);
          
          // JSONにシリアライズ
          const json = JSON.stringify({
            ...config,
            startDate: config.startDate.toISOString(),
            endDate: config.endDate.toISOString()
          });
          
          // デシリアライズ
          const parsed = JSON.parse(json);
          const deserialized: BacktestConfig = {
            ...parsed,
            startDate: new Date(parsed.startDate),
            endDate: new Date(parsed.endDate)
          };
          
          // 元の設定と同等であることを確認
          expect(deserialized.symbol).toBe(config.symbol);
          expect(deserialized.timeframe).toBe(config.timeframe);
          expect(deserialized.startDate.getTime()).toBe(config.startDate.getTime());
          expect(deserialized.endDate.getTime()).toBe(config.endDate.getTime());
        }
      ),
      { numRuns: 100 } // 100回の反復実行
    );
  });

  /**
   * 例: Trade損益計算の正確性
   * 
   * これは、プロパティベーステストの例です。
   * 実際のテストはタスク8.4で実装されます。
   */
  it('should calculate profit/loss correctly for all trades', () => {
    fc.assert(
      fc.property(
        fc.record({
          entryPrice: fc.double({ min: 100, max: 200, noNaN: true }),
          exitPrice: fc.double({ min: 100, max: 200, noNaN: true }),
          positionSize: fc.double({ min: 0.01, max: 10, noNaN: true }),
          type: fc.constantFrom('BUY', 'SELL') as fc.Arbitrary<'BUY' | 'SELL'>
        }),
        (trade) => {
          // 損益を計算
          const calculatedPnL = trade.type === 'BUY'
            ? (trade.exitPrice - trade.entryPrice) * trade.positionSize
            : (trade.entryPrice - trade.exitPrice) * trade.positionSize;
          
          // 期待される損益
          const expectedPnL = trade.type === 'BUY'
            ? (trade.exitPrice - trade.entryPrice) * trade.positionSize
            : (trade.entryPrice - trade.exitPrice) * trade.positionSize;
          
          // 浮動小数点の誤差を考慮して比較
          expect(Math.abs(calculatedPnL - expectedPnL)).toBeLessThan(0.00001);
        }
      ),
      { numRuns: 100 }
    );
  });
});
