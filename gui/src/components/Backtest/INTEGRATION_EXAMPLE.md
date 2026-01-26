# BacktestProgressIndicator Integration Example

This document demonstrates how to integrate the `BacktestProgressIndicator` component with the IPC handler to enable cancel functionality.

## Overview

The `BacktestProgressIndicator` component displays the progress of a running backtest and provides a cancel button. When the user clicks the cancel button, it calls the `onCancel` callback prop, which should invoke `window.backtestAPI.cancelBacktest()` to send a cancel request to the Electron main process.

## Integration Pattern

Here's a complete example of how to use the backtest components together:

```typescript
import React, { useState, useEffect } from 'react'
import {
  BacktestConfigDialog,
  BacktestProgressIndicator,
  BacktestResultsView
} from './components/Backtest'
import type { BacktestConfig, BacktestResults } from './types/backtest'

export const BacktestPage: React.FC = () => {
  // State management
  const [isConfigDialogOpen, setIsConfigDialogOpen] = useState(false)
  const [isRunning, setIsRunning] = useState(false)
  const [elapsedTime, setElapsedTime] = useState(0)
  const [results, setResults] = useState<BacktestResults | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Timer for elapsed time
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null

    if (isRunning) {
      interval = setInterval(() => {
        setElapsedTime(prev => prev + 1)
      }, 1000)
    } else {
      setElapsedTime(0)
    }

    return () => {
      if (interval) {
        clearInterval(interval)
      }
    }
  }, [isRunning])

  // Register IPC event listeners
  useEffect(() => {
    if (!window.backtestAPI) {
      return
    }

    // Listen for backtest completion
    window.backtestAPI.onBacktestComplete((backtestResults) => {
      setIsRunning(false)
      setResults(backtestResults)
      setError(null)
    })

    // Listen for backtest errors
    window.backtestAPI.onBacktestError((backtestError) => {
      setIsRunning(false)
      setError(backtestError.message)
      setResults(null)
    })
  }, [])

  // Handle backtest start
  const handleStartBacktest = async (config: BacktestConfig) => {
    if (!window.backtestAPI) {
      setError('Backtest API is not available')
      return
    }

    try {
      // Export current strategy configuration
      const strategyPath = await exportStrategyConfig()

      // Start backtest
      setIsRunning(true)
      setError(null)
      setResults(null)
      setIsConfigDialogOpen(false)

      await window.backtestAPI.startBacktest(config, strategyPath)
    } catch (err) {
      setIsRunning(false)
      setError(err instanceof Error ? err.message : 'Unknown error')
    }
  }

  // Handle backtest cancel
  const handleCancelBacktest = async () => {
    if (!window.backtestAPI) {
      return
    }

    try {
      await window.backtestAPI.cancelBacktest()
      setIsRunning(false)
      setError('Backtest was canceled by user')
    } catch (err) {
      console.error('Failed to cancel backtest:', err)
    }
  }

  // Handle results export
  const handleExportResults = async () => {
    // Export functionality is already implemented in BacktestResultsView
  }

  // Placeholder for strategy config export
  const exportStrategyConfig = async (): Promise<string> => {
    // TODO: Implement strategy config export
    // This should serialize the current strategy to JSON and save it
    return '/path/to/strategy.json'
  }

  return (
    <div className="backtest-page">
      {/* Header with start button */}
      <div className="header">
        <h1>Backtest</h1>
        <button
          onClick={() => setIsConfigDialogOpen(true)}
          disabled={isRunning}
        >
          Run Backtest
        </button>
      </div>

      {/* Config Dialog */}
      <BacktestConfigDialog
        isOpen={isConfigDialogOpen}
        onClose={() => setIsConfigDialogOpen(false)}
        onSubmit={handleStartBacktest}
      />

      {/* Progress Indicator */}
      <BacktestProgressIndicator
        isRunning={isRunning}
        elapsedTime={elapsedTime}
        onCancel={handleCancelBacktest}
      />

      {/* Results View */}
      <BacktestResultsView
        results={results}
        error={error}
        onExport={handleExportResults}
      />
    </div>
  )
}
```

## Key Integration Points

### 1. Cancel Handler

The `onCancel` prop of `BacktestProgressIndicator` should call `window.backtestAPI.cancelBacktest()`:

```typescript
const handleCancelBacktest = async () => {
  if (!window.backtestAPI) {
    return
  }

  try {
    await window.backtestAPI.cancelBacktest()
    setIsRunning(false)
    setError('Backtest was canceled by user')
  } catch (err) {
    console.error('Failed to cancel backtest:', err)
  }
}
```

### 2. IPC Event Listeners

Register listeners for backtest completion and errors:

```typescript
useEffect(() => {
  if (!window.backtestAPI) {
    return
  }

  window.backtestAPI.onBacktestComplete((results) => {
    setIsRunning(false)
    setResults(results)
  })

  window.backtestAPI.onBacktestError((error) => {
    setIsRunning(false)
    setError(error.message)
  })
}, [])
```

### 3. Elapsed Time Timer

Track elapsed time with a timer that runs while the backtest is active:

```typescript
useEffect(() => {
  let interval: NodeJS.Timeout | null = null

  if (isRunning) {
    interval = setInterval(() => {
      setElapsedTime(prev => prev + 1)
    }, 1000)
  } else {
    setElapsedTime(0)
  }

  return () => {
    if (interval) {
      clearInterval(interval)
    }
  }
}, [isRunning])
```

## Requirements Validation

This integration satisfies the following requirements:

- **Requirement 8.3**: When the user cancels a running backtest, the IPC Handler terminates the Python process and cleans up temporary files
  - The `handleCancelBacktest` function calls `window.backtestAPI.cancelBacktest()`, which sends an IPC message to the main process
  - The main process handles the `backtest:cancel` event and terminates the Python process

## Testing

To test the cancel functionality:

1. Start a backtest with a long date range (e.g., 1 year)
2. Click the "Cancel" button while the backtest is running
3. Verify that:
   - The button changes to "Canceling..." and becomes disabled
   - The backtest process is terminated
   - The progress indicator is hidden
   - An appropriate message is displayed

## Notes

- The `BacktestProgressIndicator` component is already fully implemented with all UI functionality
- The component handles its own internal state (canceling state)
- The parent component only needs to provide the `onCancel` callback that calls the IPC API
- The IPC handler in the main process is responsible for actually terminating the Python process
