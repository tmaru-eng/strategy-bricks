# Environment Check Feature

## Overview

The Environment Check feature validates the system environment to determine if backtest functionality can be enabled. This ensures users have the necessary dependencies installed before attempting to run backtests.

**Validates Requirements:** 9.1, 9.5

## Architecture

### Components

1. **EnvironmentChecker Class** (`gui/electron/main.ts`)
   - Performs OS detection
   - Checks Python availability
   - Checks MT5 library availability
   - Caches results for performance

2. **IPC Handler** (`gui/electron/main.ts`)
   - Exposes `backtest:checkEnvironment` IPC channel
   - Returns environment check results to renderer process

3. **Preload API** (`gui/electron/preload.ts`)
   - Exposes `window.backtestAPI.checkEnvironment()` to renderer
   - Type-safe interface for environment checking

## Environment Check Flow

```
App Startup
    ↓
OS Detection (Requirement 9.1)
    ↓
Is Windows? ──No──> Disable backtest, show platform message (Requirement 9.3)
    ↓ Yes
Python Check (Requirement 9.5)
    ↓
Python Available? ──No──> Disable backtest, show Python install message
    ↓ Yes
MT5 Library Check (Requirement 9.5)
    ↓
MT5 Available? ──No──> Disable backtest, show MT5 install message (Requirement 9.4)
    ↓ Yes
Enable Backtest (Requirement 9.2)
```

## Check Results

The environment check returns an `EnvironmentCheckResult` object:

```typescript
interface EnvironmentCheckResult {
  isWindows: boolean          // OS is Windows
  pythonAvailable: boolean    // Python is installed and accessible
  mt5Available: boolean       // MetaTrader5 library is installed
  backtestEnabled: boolean    // All checks passed, backtest can be enabled
  message?: string            // User-friendly message explaining the status
}
```

## Usage

### From Renderer Process

```typescript
// Check environment on component mount
const checkEnvironment = async () => {
  const result = await window.backtestAPI.checkEnvironment()
  
  if (result.backtestEnabled) {
    // Enable backtest UI
    console.log('Backtest available:', result.message)
  } else {
    // Disable backtest UI and show message
    console.log('Backtest unavailable:', result.message)
  }
}
```

### From Main Process

```typescript
// Check environment on startup
app.whenReady().then(async () => {
  const envCheck = await EnvironmentChecker.checkEnvironment()
  console.log('Environment check result:', envCheck)
})
```

## Check Details

### OS Detection (Requirement 9.1)

- Uses Node.js `os.platform()` to detect operating system
- Checks if platform is `'win32'` (Windows)
- Performed synchronously at startup

### Python Check (Requirement 9.5)

- Spawns `python --version` subprocess
- Validates exit code is 0
- Validates output contains "Python"
- Timeout: 5 seconds
- Handles errors gracefully

### MT5 Library Check (Requirement 9.5)

- Spawns `python -c "import MetaTrader5; print('OK')"` subprocess
- Validates exit code is 0
- Validates output contains "OK"
- Timeout: 5 seconds
- Handles import errors gracefully

## Error Messages

### Non-Windows Platform (Requirement 9.3)

```
バックテスト機能はWindowsでのみ利用可能です。
MetaTrader5はWindows専用のプラットフォームです。
```

### Python Not Available

```
Python環境が見つかりません。
バックテスト機能を使用するには、Python 3.8以上をインストールしてください。
```

### MT5 Library Not Available (Requirement 9.4)

```
MetaTrader5 Pythonライブラリがインストールされていません。

インストール手順:
1. コマンドプロンプトを開く
2. 次のコマンドを実行: pip install MetaTrader5
3. アプリケーションを再起動
```

## Caching

The environment check result is cached after the first check to improve performance:

- First check: Performs all validations (~5-10 seconds)
- Subsequent checks: Returns cached result (instant)
- Cache can be cleared with `EnvironmentChecker.clearCache()` (for testing)

## Testing

### Unit Tests

Run unit tests with:

```bash
cd gui
npm test -- environment-checker.test.ts
```

Tests cover:
- OS detection logic
- Python check scenarios
- MT5 library check scenarios
- Result structure validation
- Error message validation
- Caching behavior

### Manual Testing

Run manual environment check:

```bash
cd gui
npx ts-node electron/__tests__/manual-environment-check.ts
```

This will:
1. Detect your OS
2. Check for Python
3. Check for MT5 library
4. Display detailed results

## Integration with UI

The UI should:

1. Call `window.backtestAPI.checkEnvironment()` on mount
2. Store result in component state
3. Enable/disable backtest features based on `backtestEnabled`
4. Display `message` to user if backtest is disabled

Example React component:

```typescript
const BacktestPanel = () => {
  const [envCheck, setEnvCheck] = useState<EnvironmentCheckResult | null>(null)
  
  useEffect(() => {
    window.backtestAPI.checkEnvironment().then(setEnvCheck)
  }, [])
  
  if (!envCheck) {
    return <div>環境をチェック中...</div>
  }
  
  if (!envCheck.backtestEnabled) {
    return (
      <div className="alert alert-warning">
        <p>{envCheck.message}</p>
      </div>
    )
  }
  
  return (
    <div>
      {/* Backtest UI */}
    </div>
  )
}
```

## Troubleshooting

### Python Not Detected

1. Verify Python is installed: `python --version`
2. Ensure Python is in system PATH
3. Try using `python3` instead of `python`
4. Restart the application after installing Python

### MT5 Library Not Detected

1. Verify MT5 library is installed: `python -c "import MetaTrader5"`
2. Install with: `pip install MetaTrader5`
3. Ensure you're using the correct Python environment
4. Restart the application after installing

### False Negatives

If checks fail but dependencies are installed:
- Check antivirus/firewall settings
- Verify subprocess spawning is not blocked
- Check Python environment variables
- Try running as administrator

## Future Enhancements

Potential improvements:
- Support for `python3` command on systems where `python` is not available
- Virtual environment detection and activation
- Automatic MT5 library installation prompt
- More detailed version checking (Python 3.8+ requirement)
- macOS/Linux support with Wine or alternative solutions
