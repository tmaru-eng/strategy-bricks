#!/usr/bin/env python3
"""
MT5接続テストスクリプト
MT5ターミナルへの接続をテストし、基本情報を表示します。
"""

import sys

try:
    import MetaTrader5 as mt5
except ImportError:
    print("エラー: MetaTrader5ライブラリがインストールされていません")
    print("インストール方法: pip install MetaTrader5")
    sys.exit(1)

print("=== MT5接続テスト ===")
print()

# MT5初期化
print("[1/3] MT5ターミナルに接続中...")
if not mt5.initialize():
    error = mt5.last_error()
    print(f"✗ MT5初期化失敗: {error}")
    print()
    print("MT5ターミナルが起動していることを確認してください。")
    print("MT5がインストールされていない場合は、以下からダウンロードしてください:")
    print("https://www.metatrader5.com/ja/download")
    sys.exit(1)

print("✓ MT5初期化成功")
print()

# ターミナル情報を取得
print("[2/3] ターミナル情報を取得中...")
version = mt5.version()
terminal_info = mt5.terminal_info()

if terminal_info:
    print(f"✓ ターミナル名: {terminal_info.name}")
    print(f"✓ ビルド: {terminal_info.build}")
    print(f"✓ 会社: {terminal_info.company}")
    print(f"✓ パス: {terminal_info.path}")
else:
    print("✓ バージョン情報のみ取得")

print(f"✓ MT5バージョン: {version}")
print()

# アカウント情報を取得
print("[3/3] アカウント情報を取得中...")
account_info = mt5.account_info()

if account_info:
    print(f"✓ ログイン: {account_info.login}")
    print(f"✓ サーバー: {account_info.server}")
    print(f"✓ 残高: {account_info.balance}")
    print(f"✓ 通貨: {account_info.currency}")
else:
    print("⚠ アカウント情報を取得できませんでした")
    print("  MT5にログインしていない可能性があります")

print()

# シンボル情報を取得（テスト用）
print("利用可能なシンボルをテスト中...")
symbols = mt5.symbols_get()

if symbols:
    print(f"✓ 利用可能なシンボル数: {len(symbols)}")
    
    # USDJPYが利用可能かチェック
    usdjpy = mt5.symbol_info("USDJPY")
    if usdjpy:
        print(f"✓ USDJPY: 利用可能")
        print(f"  - Bid: {usdjpy.bid}")
        print(f"  - Ask: {usdjpy.ask}")
        print(f"  - Spread: {usdjpy.spread}")
    else:
        print("⚠ USDJPY: 利用不可")
        print("  他のシンボルを使用してください")
        
        # 最初の5つのシンボルを表示
        print()
        print("利用可能なシンボル（最初の5つ）:")
        for i, symbol in enumerate(symbols[:5]):
            print(f"  - {symbol.name}")
else:
    print("✗ シンボル情報を取得できませんでした")

print()

# クリーンアップ
mt5.shutdown()
print("=== テスト完了 ===")
print()
print("MT5接続は正常に動作しています。")
print("バックテストを実行する準備ができました。")
