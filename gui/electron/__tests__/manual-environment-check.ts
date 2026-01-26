/**
 * Manual test script for environment checking
 * 
 * This script can be run to manually verify the environment checking functionality.
 * It simulates what happens when the Electron app starts up.
 * 
 * Usage: ts-node gui/electron/__tests__/manual-environment-check.ts
 */

import { spawn } from 'child_process'
import * as os from 'os'

interface EnvironmentCheckResult {
  isWindows: boolean
  pythonAvailable: boolean
  mt5Available: boolean
  backtestEnabled: boolean
  message?: string
}

/**
 * Check if Python is available
 */
async function checkPython(): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      const pythonProcess = spawn('python', ['--version'])
      
      let output = ''
      
      pythonProcess.stdout?.on('data', (data) => {
        output += data.toString()
      })
      
      pythonProcess.stderr?.on('data', (data) => {
        output += data.toString()
      })
      
      pythonProcess.on('close', (code) => {
        if (code === 0 && output.includes('Python')) {
          console.log('✓ Python version:', output.trim())
          resolve(true)
        } else {
          console.log('✗ Python check failed:', { code, output })
          resolve(false)
        }
      })
      
      pythonProcess.on('error', (error) => {
        console.log('✗ Python spawn error:', error.message)
        resolve(false)
      })
      
      setTimeout(() => {
        pythonProcess.kill()
        console.log('✗ Python check timeout')
        resolve(false)
      }, 5000)
    } catch (error) {
      console.log('✗ Python check exception:', error)
      resolve(false)
    }
  })
}

/**
 * Check if MT5 library is available
 */
async function checkMT5Library(): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      const pythonProcess = spawn('python', ['-c', 'import MetaTrader5; print("OK")'])
      
      let output = ''
      let errorOutput = ''
      
      pythonProcess.stdout?.on('data', (data) => {
        output += data.toString()
      })
      
      pythonProcess.stderr?.on('data', (data) => {
        errorOutput += data.toString()
      })
      
      pythonProcess.on('close', (code) => {
        if (code === 0 && output.includes('OK')) {
          console.log('✓ MT5 library available')
          resolve(true)
        } else {
          console.log('✗ MT5 library check failed:', { 
            code, 
            output: output.trim(), 
            error: errorOutput.trim() 
          })
          resolve(false)
        }
      })
      
      pythonProcess.on('error', (error) => {
        console.log('✗ MT5 library spawn error:', error.message)
        resolve(false)
      })
      
      setTimeout(() => {
        pythonProcess.kill()
        console.log('✗ MT5 library check timeout')
        resolve(false)
      }, 5000)
    } catch (error) {
      console.log('✗ MT5 library check exception:', error)
      resolve(false)
    }
  })
}

/**
 * Perform full environment check
 */
async function checkEnvironment(): Promise<EnvironmentCheckResult> {
  console.log('\n=== Environment Check ===\n')
  
  // OS detection
  const platform = os.platform()
  const isWindows = platform === 'win32'
  
  console.log('OS Information:')
  console.log('  Platform:', platform)
  console.log('  Architecture:', os.arch())
  console.log('  Release:', os.release())
  console.log('  Is Windows:', isWindows ? '✓' : '✗')
  console.log()
  
  if (!isWindows) {
    return {
      isWindows: false,
      pythonAvailable: false,
      mt5Available: false,
      backtestEnabled: false,
      message: 'バックテスト機能はWindowsでのみ利用可能です。MetaTrader5はWindows専用のプラットフォームです。'
    }
  }
  
  // Python check
  console.log('Checking Python...')
  const pythonAvailable = await checkPython()
  console.log()
  
  if (!pythonAvailable) {
    return {
      isWindows: true,
      pythonAvailable: false,
      mt5Available: false,
      backtestEnabled: false,
      message: 'Python環境が見つかりません。バックテスト機能を使用するには、Python 3.8以上をインストールしてください。'
    }
  }
  
  // MT5 library check
  console.log('Checking MT5 library...')
  const mt5Available = await checkMT5Library()
  console.log()
  
  if (!mt5Available) {
    return {
      isWindows: true,
      pythonAvailable: true,
      mt5Available: false,
      backtestEnabled: false,
      message: 'MetaTrader5 Pythonライブラリがインストールされていません。\n\nインストール手順:\n1. コマンドプロンプトを開く\n2. 次のコマンドを実行: pip install MetaTrader5\n3. アプリケーションを再起動'
    }
  }
  
  return {
    isWindows: true,
    pythonAvailable: true,
    mt5Available: true,
    backtestEnabled: true,
    message: 'バックテスト機能が利用可能です。'
  }
}

// Run the check
checkEnvironment().then(result => {
  console.log('=== Check Result ===\n')
  console.log('Result:', JSON.stringify(result, null, 2))
  console.log()
  
  if (result.backtestEnabled) {
    console.log('✓ Backtest functionality is ENABLED')
  } else {
    console.log('✗ Backtest functionality is DISABLED')
    console.log('\nReason:', result.message)
  }
  
  process.exit(result.backtestEnabled ? 0 : 1)
}).catch(error => {
  console.error('Error during environment check:', error)
  process.exit(1)
})
