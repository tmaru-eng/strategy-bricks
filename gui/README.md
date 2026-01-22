# GUI Builder（Electron）

ブロック（レゴ）を組み合わせて戦略を構築するためのGUIアプリケーションです。

## ディレクトリ構造

```
gui/
├── src/                    # ソースコード
│   ├── main/               # Electronメインプロセス
│   ├── renderer/           # Electronレンダラープロセス
│   │   ├── components/     # Reactコンポーネント
│   │   │   ├── Palette/    # ブロックパレット
│   │   │   ├── Canvas/     # ノードベースエディタ
│   │   │   ├── Property/   # プロパティパネル
│   │   │   └── Validator/  # バリデーションパネル
│   │   ├── models/         # データモデル
│   │   ├── services/       # ビジネスロジック
│   │   └── utils/          # ユーティリティ
│   └── types/              # TypeScript型定義
├── public/                 # 静的ファイル
├── package.json            # npm設定
└── tsconfig.json           # TypeScript設定
```

## 実装状況

**現在の状態**: 未実装（Phase 0完了後に開始予定）

**次のステップ**:
1. GUI技術検証（Phase 0）
2. Palette/Canvas/Property実装（Phase 2）

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

**セットアップ**（将来）:
```bash
cd gui
npm install
npm run dev
```

**ビルド**（将来）:
```bash
npm run build
```

## 技術スタック（予定）

- **フレームワーク**: Electron
- **UIライブラリ**: React + TypeScript
- **ノードエディタ**: React Flow
- **状態管理**: Redux または Context API
- **スタイリング**: Tailwind CSS または styled-components

## 主要機能

### 1. Palette（パレット）
- block_catalog.jsonからブロック一覧を表示
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

**最終更新**: 2026-01-22
