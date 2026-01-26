# バックテスト実行時のエクスポートダイアログ修正

## 日付: 2026-01-26

## 問題

バックテスト実行ボタンを押すと、エクスポート用のファイル保存ダイアログが表示されていた。

## 原因

`BacktestPanel.tsx`で`exportConfig()`関数を呼び出していたため、Electronのファイル保存ダイアログが表示されていた。

```typescript
// 問題のあるコード
const { exportConfig } = await import('../../services/Exporter')
const exportResult = await exportConfig('backtest-temp', nodes, edges)
```

`exportConfig()`は以下の処理を行う：
1. ストラテジー設定を生成
2. **ファイル保存ダイアログを表示** ← これが問題
3. ユーザーが選択したパスにファイルを保存

バックテスト実行時には、ファイル保存ダイアログを表示せずに、内部的にストラテジー設定を生成して一時ファイルに保存する必要がある。

---

## 解決策

### 1. 新しい関数を追加: `buildStrategyConfig()`

`Exporter.ts`に、ファイル保存ダイアログを表示せずにストラテジー設定オブジェクトを返す関数を追加：

```typescript
/**
 * ビルダーの状態からストラテジー設定オブジェクトを生成する（ファイル保存なし）
 * バックテスト用に使用
 */
export const buildStrategyConfig = (
  profileName: string, 
  nodes: Node[], 
  edges: Edge[]
) => {
  const config = buildConfig(nodes, edges, profileName)
  return config
}
```

**特徴**:
- ファイル保存ダイアログを表示しない
- 設定オブジェクトを直接返す
- バックテスト用に最適化

---

### 2. BacktestPanelを修正

`BacktestPanel.tsx`で、`exportConfig()`の代わりに`buildStrategyConfig()`を使用：

**修正前**:
```typescript
const { exportConfig } = await import('../../services/Exporter')
const exportResult = await exportConfig('backtest-temp', nodes, edges)

if (!exportResult.ok) {
  throw new Error('ストラテジー設定のエクスポートに失敗しました')
}

// 暫定的に、ビルダーの状態から直接設定を生成
strategyConfig = {
  meta: { ... },
  globalGuards: { ... },
  strategies: [],
  blocks: []
}
```

**修正後**:
```typescript
const { buildStrategyConfig } = await import('../../services/Exporter')
strategyConfig = buildStrategyConfig('Backtest Strategy', nodes, edges)
```

**改善点**:
- コードが大幅に簡潔になった
- ファイル保存ダイアログが表示されない
- ビルダーの状態から正しくストラテジー設定が生成される

---

## 処理フロー

### 修正前（問題あり）
```
バックテスト実行ボタン
  ↓
exportConfig() 呼び出し
  ↓
ファイル保存ダイアログ表示 ← ユーザーが混乱
  ↓
ユーザーがパスを選択
  ↓
ファイルに保存
  ↓
バックテスト実行
```

### 修正後（正常）
```
バックテスト実行ボタン
  ↓
buildStrategyConfig() 呼び出し
  ↓
ストラテジー設定オブジェクト生成（メモリ内）
  ↓
一時ファイルに保存（内部処理）
  ↓
バックテスト実行
```

---

## 関数の使い分け

### `exportConfig()` - ユーザーがファイルをエクスポートする場合
- **用途**: ユーザーが明示的に設定ファイルをエクスポートしたい場合
- **動作**: ファイル保存ダイアログを表示
- **呼び出し元**: App.tsx の `handleExport()`

### `buildStrategyConfig()` - 内部処理でストラテジー設定が必要な場合
- **用途**: バックテスト実行など、内部処理で設定が必要な場合
- **動作**: ダイアログを表示せず、設定オブジェクトを返す
- **呼び出し元**: BacktestPanel.tsx の `handleStartBacktest()`

---

## テスト方法

### 1. バックテスト実行
1. GUIを起動
2. バックテストタブを開く
3. "バックテスト実行"ボタンをクリック
4. **ファイル保存ダイアログが表示されないことを確認** ✅
5. バックテスト設定ダイアログが表示される
6. 設定を入力して"実行"をクリック
7. バックテストが正常に実行される

### 2. エクスポート機能（既存機能の確認）
1. ビルダータブでストラテジーを作成
2. "エクスポート"ボタンをクリック
3. **ファイル保存ダイアログが表示されることを確認** ✅
4. パスを選択してファイルを保存
5. ファイルが正しく保存される

---

## 変更ファイル

1. `gui/src/services/Exporter.ts` - `buildStrategyConfig()`関数を追加
2. `gui/src/components/Backtest/BacktestPanel.tsx` - `exportConfig()`を`buildStrategyConfig()`に変更

---

## 今後の改善案

1. **検証機能の追加**: `buildStrategyConfig()`でも設定の検証を行う
2. **エラーハンドリング**: ビルダーが空の場合のエラーメッセージを改善
3. **プレビュー機能**: バックテスト実行前に生成される設定をプレビュー表示
4. **設定の保存**: バックテスト用の設定を履歴として保存
