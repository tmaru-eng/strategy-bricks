# GUI Builder（Electron）

ブロック（レゴ）を組み合わせて戦略を構築するためのGUIアプリケーションです。

## ディレクトリ構造

```
gui/
├── electron/               # Electronメインプロセス
├── e2e/                    # E2Eシナリオ
├── src/                    # レンダラ（React）と共通コード
│   ├── components/         # UIコンポーネント
│   ├── models/             # データモデル
│   ├── resources/          # デフォルトカタログ等
│   ├── services/           # ビジネスロジック
│   ├── store/              # 状態管理
│   └── types/              # TypeScript型定義
├── package.json            # npm設定
└── vite.config.ts          # Vite設定
```

## 実装状況

**現在の状態**: GUIのMVP導線（Palette/Canvas/Property/Validate/Export）まで実装済み

**次のステップ**:
1. 条件ブロックの拡充（block_catalog.jsonの拡張）
2. Exportの設定詳細（strategies/globalGuards）の実装

## 設計ドキュメント

**必読**:
- `docs/03_design/60_gui_builder_design.md` - GUI Builder詳細設計

**参照**:
- `docs/03_design/30_config_spec.md` - 出力するJSON構造
- `docs/03_design/40_block_catalog_spec.md` - 読み込むカタログ構造

## 開発環境

**必要なツール**:
- Node.js (v18以上推奨)
- npm または yarn

**セットアップ**:
```bash
cd gui
npm install
npm run dev
```

**ビルド**:
```bash
npm run build
```

**テスト**:
```bash
npm run test
```

**E2E**:
```bash
npm run e2e
```

## 技術スタック

- **フレームワーク**: Electron
- **UIライブラリ**: React + TypeScript
- **ノードエディタ**: React Flow
- **状態管理**: Zustand
- **スタイリング**: Tailwind CSS

## 主要機能

### 1. Palette（パレット）
- デフォルトカタログ（`src/resources/block_catalog.default.json`）からブロック一覧を表示
- カテゴリ別に整理（filter/env/trend/trigger/lot/risk/exit/nanpin）
- ドラッグ&ドロップでCanvasに配置

### 2. Canvas（キャンバス）
- ノードベースエディタ（React Flow使用）
- OR/AND制約の実装（枠がOR、内がAND）
- ノード選択・編集・削除

### 3. Property（プロパティパネル）
- paramsSchemaからフォーム自動生成
- 必須パラメータのバリデーション
- リアルタイム更新

### 4. Validator（バリデーター）
- 必須パラメータチェック
- 型チェック
- 範囲チェック
- ブロック参照チェック
- 循環参照チェック

### 5. Export（エクスポート）
- profiles/<name>.json（保存用）
- active.json（EA実行用）
- MT5のMQL5/Files/strategy/に出力

## 重要な実装ルール

1. **OR/AND制約の厳密な実装**
   - 枠（RuleGroup）間はOR
   - 枠内（Condition）はAND
   - 不正な接続は拒否

2. **paramsSchemaに基づくフォーム生成**
   - JSON Schemaに準拠
   - ui.controlヒントを使用

3. **バリデーション二重チェック**
   - GUI側で事前チェック
   - EA側で最終チェック

詳細: `docs/03_design/60_gui_builder_design.md`

---

**最終更新**: 2026-01-24
