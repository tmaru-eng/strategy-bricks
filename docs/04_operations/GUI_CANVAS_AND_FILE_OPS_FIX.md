# GUI Canvas Rendering and File Operations Fix

## Date: 2026-01-26

## Issues Fixed

### 1. Canvas Not Rendering Nodes (Issue #13)

**Problem**: Builder had initial nodes defined in state, but the canvas center area was not displaying them properly.

**Root Cause**: The ReactFlow canvas container (`.node-editor`) didn't have explicit height set, causing it to collapse to 0 height even though parent had `flex: 1`.

**Solution**: Added explicit CSS rules to ensure proper height:

```css
.node-editor {
  width: 100%;
  height: 100%;
  min-height: 500px;
}

.react-flow {
  width: 100%;
  height: 100%;
}

.panel-content {
  /* ... existing styles ... */
  min-height: 0;
  overflow: hidden;
}

.panel-center {
  min-height: 600px;
}
```

**Files Modified**:
- `gui/src/styles/index.css`

---

### 2. File Operation Buttons Not Working (Issue #12)

**Problem**: The "新規" (New), "開く" (Open), and "保存" (Save) buttons had no onClick handlers.

**Solution**: 

#### A. Added Button Handlers in App.tsx

1. **handleNew()**: Resets builder to initial state with confirmation dialog
2. **handleOpen()**: Opens file dialog, reads JSON config (conversion to nodes/edges TODO)
3. **handleSave()**: Shows save dialog, exports current nodes/edges as JSON

#### B. Added IPC Handlers in Electron

**Preload.ts** - Exposed new APIs:
```typescript
dialog: {
  showOpenDialog: async (options: any) => ipcRenderer.invoke('dialog:showOpen', options),
  showSaveDialog: async (options: any) => ipcRenderer.invoke('dialog:showSave', options)
},
fs: {
  readFile: async (filePath: string) => ipcRenderer.invoke('fs:readFile', filePath),
  writeFile: async (filePath: string, content: string) => ipcRenderer.invoke('fs:writeFile', filePath, content)
}
```

**Main.ts** - Added IPC handlers:
- `dialog:showOpen` - Generic open file dialog
- `dialog:showSave` - Generic save file dialog
- `fs:readFile` - Read file content
- `fs:writeFile` - Write file content

**Files Modified**:
- `gui/src/App.tsx`
- `gui/electron/preload.ts`
- `gui/electron/main.ts`

---

## Current Limitations

### File Open Feature
The "開く" (Open) button currently:
- ✅ Shows file dialog
- ✅ Reads JSON file
- ❌ Does NOT convert config format to nodes/edges yet
- Shows "設定ファイルの読み込み機能は実装中です" message

**TODO**: Implement conversion from exported JSON config format to ReactFlow nodes/edges format.

### File Save Feature
The "保存" (Save) button currently:
- ✅ Shows save dialog
- ✅ Exports nodes/edges as JSON
- ✅ Includes version and timestamp
- ❌ Format is internal state format, not strategy config format

**TODO**: Consider if save should export strategy config format instead of internal state format.

---

## Testing

### Canvas Rendering
1. Start GUI in dev mode: `npm run dev` (in gui directory)
2. Switch to "ビルダー" tab
3. Verify initial nodes are visible in canvas center
4. Verify you can zoom/pan the canvas
5. Verify nodes can be dragged

### File Operations

#### New Button
1. Click "新規" button
2. Confirm dialog appears if nodes exist
3. Canvas resets to single strategy node

#### Save Button
1. Build a strategy in canvas
2. Click "保存" button
3. Choose save location
4. Verify JSON file is created with nodes/edges

#### Open Button
1. Click "開く" button
2. Select a JSON file
3. Currently shows "実装中" message (expected)

---

## Next Steps

1. **Complete File Open Feature**:
   - Implement JSON config → nodes/edges conversion
   - Handle different config formats (strategy config vs state format)
   - Add validation for loaded configs

2. **Improve File Save Feature**:
   - Decide on save format (internal state vs strategy config)
   - Add metadata (strategy name, description, etc.)
   - Consider auto-save functionality

3. **Add Recent Files**:
   - Track recently opened/saved files
   - Add "Recent" submenu or quick access

4. **Add Keyboard Shortcuts**:
   - Ctrl+N for New
   - Ctrl+O for Open
   - Ctrl+S for Save
   - Ctrl+E for Export

---

## Related Issues

- Issue #10: Default strategy config when builder is empty (partially addressed)
- Issue #9: Chart visualization for backtest results (not addressed yet)
- Issue #7: Canvas rendering (FIXED)
- Issue #6: File operations (FIXED - basic functionality)
