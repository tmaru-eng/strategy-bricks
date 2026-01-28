#!/usr/bin/env python3
"""
MT5接続とシンボル確認スクリプト
"""
import MetaTrader5 as mt5
from datetime import datetime, timedelta


def main() -> None:
    print("=== MT5接続テスト ===\n")

    # MT5初期化
    if not mt5.initialize():
        print(f"❌ MT5初期化失敗: {mt5.last_error()}")
        return

    print("✓ MT5初期化成功")
    print(f"  バージョン: {mt5.version()}")
    print(f"  ターミナル情報: {mt5.terminal_info()}")
    print()

    # アカウント情報
    account_info = mt5.account_info()
    if account_info:
        print("✓ アカウント情報:")
        print(f"  ログイン: {account_info.login}")
        print(f"  サーバー: {account_info.server}")
        print(f"  会社: {account_info.company}")
    else:
        print("⚠ アカウント情報取得失敗（デモ口座未ログインの可能性）")
    print()

    # シンボル一覧を取得
    print("=== 利用可能なシンボル（最初の20件） ===")
    symbols = mt5.symbols_get()
    if symbols:
        print(f"✓ 合計 {len(symbols)} シンボル")
        for i, symbol in enumerate(symbols[:20]):
            print(f"  {i + 1}. {symbol.name} - {symbol.description}")
    else:
        print("❌ シンボル取得失敗")
    print()

    # USDJPYを検索
    print("=== USDJPY関連シンボル ===")
    usdjpy_symbols = [s for s in (symbols or []) if 'USDJPY' in s.name.upper()]
    if usdjpy_symbols:
        for symbol in usdjpy_symbols:
            print(f"  ✓ {symbol.name} - {symbol.description}")
            print(f"    パス: {symbol.path}")
            print(f"    可視: {symbol.visible}")
    else:
        print("  ⚠ USDJPY関連シンボルが見つかりません")
    print()

    # データ取得テスト
    print("=== データ取得テスト ===")
    if usdjpy_symbols:
        test_symbol = usdjpy_symbols[0].name
        print(f"テストシンボル: {test_symbol}")

        # 過去1週間のデータを取得
        end_date = datetime.now()
        start_date = end_date - timedelta(days=7)

        print(f"期間: {start_date} - {end_date}")

        rates = mt5.copy_rates_range(test_symbol, mt5.TIMEFRAME_M1, start_date, end_date)

        if rates is not None and len(rates) > 0:
            print(f"✓ データ取得成功: {len(rates)} バー")
            print(f"  最初のバー: {datetime.fromtimestamp(rates[0]['time'])}")
            print(f"  最後のバー: {datetime.fromtimestamp(rates[-1]['time'])}")
        else:
            error = mt5.last_error()
            print(f"❌ データ取得失敗: {error}")
    else:
        print("⚠ テストをスキップ（シンボルが見つかりません）")

    # クリーンアップ
    mt5.shutdown()
    print("\n=== テスト完了 ===")


if __name__ == "__main__":
    main()
