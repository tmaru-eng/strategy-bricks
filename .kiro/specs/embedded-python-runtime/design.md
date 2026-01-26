# Design Document: Embedded Python Runtime

## Overview

This design implements a self-contained Python runtime bundled with the Electron application, eliminating the need for users to install Python separately. The solution uses Python's official Embeddable Package for Windows, includes all required dependencies (MetaTrader5, numpy), and provides intelligent fallback to system Python for development scenarios.

The design modifies two key components:
1. **EnvironmentChecker** - Enhanced to detect and validate bundled Python with priority over system Python
2. **BacktestProcessManager** - Updated to use the detected Python runtime for spawning backtest processes

The bundled Python runtime is packaged in the `resources/python/` directory and includes a minimal Python distribution with only the necessary packages to keep the bundle size under 50MB.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Electron Application                      │
│                                                              │
│  ┌────────────────────┐         ┌──────────────────────┐   │
│  │ Environment        │         │ Backtest Process     │   │
│  │ Checker            │────────▶│ Manager              │   │
│  │                    │         │                      │   │
│  │ - Detect Python    │         │ - Spawn Python       │   │
│  │ - Validate Deps    │         │ - Execute Backtest   │   │
│  └────────────────────┘         └──────────────────────┘   │
│           │                              │                  │
│           │                              │                  │
│           ▼                              ▼                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Python Runtime Resolution                    │   │
│  │                                                      │   │
│  │  Priority 1: Bundled Python (resources/python/)     │   │
│  │  Priority 2: System Python (PATH)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│           │                              │                  │
└───────────┼──────────────────────────────┼──────────────────┘
            │                              │
            ▼                              ▼
   ┌─────────────────┐          ┌──────────────────┐
   │ Bundled Python  │          │ System Python    │
   │ (resources/     │          │ (C:\Python3x\)   │
   │  python/)       │          │                  │
   │                 │          │                  │
   │ - python.exe    │          │ - python.exe     │
   │ - Lib/          │          │ - site-packages/ │
   │ - site-packages/│          │                  │
   └─────────────────┘          └──────────────────┘
```

### Path Resolution Strategy

The application uses different paths for development and production:

**Development Mode** (app.isPackaged = false):
- Bundled Python: `<project-root>/resources/python/python.exe`
- Falls back to system Python if bundled not found

**Production Mode** (app.isPackaged = true):
- Bundled Python: `<app-path>/resources/python/python.exe`
- Falls back to system Python if bundled not found

### Detection Flow

```
Start
  │
  ▼
Determine Mode (dev/prod)
  │
  ▼
Check Bundled Python Path
  │
  ├─ Exists? ──Yes──▶ Validate Version (≥3.8)
  │                        │
  │                        ├─ Valid? ──Yes──▶ Check Dependencies
  │                        │                       │
  │                        │                       ├─ Complete? ──Yes──▶ Use Bundled Python
  │                        │                       │
  │                        │                       └─ No ──▶ Log Warning, Try System Python
  │                        │
  │                        └─ No ──▶ Try System Python
  │
  └─ No ──▶ Try System Python
                │
                ▼
          Check System Python
                │
                ├─ Found? ──Yes──▶ Validate Version & Dependencies
                │                       │
                │                       ├─ Valid? ──Yes──▶ Use System Python
                │                       │
                │                       └─ No ──▶ Return Error
                │
                └─ No ──▶ Return Error (No Python Found)
```

## Components and Interfaces

### 1. PythonRuntimeResolver

A new utility module responsible for locating and validating Python runtimes.

```typescript
interface PythonRuntime {
  executablePath: string;
  version: string;
  type: 'bundled' | 'system';
  hasDependencies: boolean;
  missingDependencies?: string[];
}

interface PythonRuntimeResolver {
  /**
   * Resolves the Python runtime to use, checking bundled first, then system
   * @returns PythonRuntime if found and valid, null otherwise
   */
  resolvePythonRuntime(): Promise<PythonRuntime | null>;
  
  /**
   * Gets the path to bundled Python based on app mode
   * @returns Path to bundled python.exe or null if not found
   */
  getBundledPythonPath(): string | null;
  
  /**
   * Checks if a Python executable exists and is valid
   * @param pythonPath - Path to python.exe
   * @returns PythonRuntime if valid, null otherwise
   */
  validatePythonRuntime(pythonPath: string): Promise<PythonRuntime | null>;
  
  /**
   * Checks if required Python packages are installed
   * @param pythonPath - Path to python.exe
   * @returns Array of missing package names (empty if all present)
   */
  checkDependencies(pythonPath: string): Promise<string[]>;
}
```

### 2. Enhanced EnvironmentChecker

Modified to use PythonRuntimeResolver for Python detection.

```typescript
interface EnvironmentChecker {
  /**
   * Checks if Python is available and valid
   * Uses PythonRuntimeResolver to find bundled or system Python
   * @returns Object with status and Python runtime details
   */
  checkPython(): Promise<{
    available: boolean;
    runtime?: PythonRuntime;
    error?: string;
  }>;
  
  /**
   * Performs complete environment validation
   * Includes Python check and other environment requirements
   */
  checkEnvironment(): Promise<EnvironmentStatus>;
}
```

### 3. Enhanced BacktestProcessManager

Modified to use the resolved Python runtime from EnvironmentChecker.

```typescript
interface BacktestProcessManager {
  /**
   * Spawns a backtest process using the resolved Python runtime
   * @param pythonRuntime - The Python runtime to use (from EnvironmentChecker)
   * @param scriptPath - Path to the backtest script
   * @param args - Arguments to pass to the script
   * @returns ChildProcess instance
   */
  spawnBacktestProcess(
    pythonRuntime: PythonRuntime,
    scriptPath: string,
    args: string[]
  ): ChildProcess;
  
  /**
   * Executes a backtest with the given parameters
   * Automatically uses the resolved Python runtime
   */
  executeBacktest(params: BacktestParams): Promise<BacktestResult>;
}
```

### 4. Build Configuration (electron-builder)

Configuration to include Python runtime in the packaged application.

```javascript
// electron-builder.config.js additions
{
  extraResources: [
    {
      from: 'resources/python',
      to: 'python',
      filter: ['**/*']
    }
  ],
  files: [
    // ... existing files
    '!resources/python/**/*' // Exclude from asar to keep Python accessible
  ],
  asarUnpack: [
    // Ensure Python runtime is not packed in asar
    'resources/python/**/*'
  ]
}
```

## Data Models

### PythonRuntime

```typescript
interface PythonRuntime {
  // Path to the Python executable
  executablePath: string;
  
  // Python version string (e.g., "3.8.10")
  version: string;
  
  // Type of runtime
  type: 'bundled' | 'system';
  
  // Whether all required dependencies are present
  hasDependencies: boolean;
  
  // List of missing dependencies (if any)
  missingDependencies?: string[];
}
```

### EnvironmentStatus

```typescript
interface EnvironmentStatus {
  // Overall environment validity
  valid: boolean;
  
  // Python runtime information
  python: {
    available: boolean;
    runtime?: PythonRuntime;
    error?: string;
  };
  
  // Other environment checks
  // ... existing fields
}
```

### PythonValidationResult

```typescript
interface PythonValidationResult {
  // Whether the Python executable is valid
  valid: boolean;
  
  // Python version if valid
  version?: string;
  
  // Error message if invalid
  error?: string;
}
```

## Correctness Properties


A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Bundled Python Priority

*For any* application startup where both bundled Python and system Python are available, the Environment_Checker should detect and select the bundled Python runtime before considering system Python.

**Validates: Requirements 2.1, 7.2**

### Property 2: Python Runtime Validation

*For any* Python runtime (bundled or system), when validating it, the Environment_Checker should verify that the version is 3.8 or higher and that all required dependencies (MetaTrader5, numpy) are present.

**Validates: Requirements 2.2, 2.4, 7.4**

### Property 3: Fallback to System Python

*For any* scenario where bundled Python is not available or invalid, the Environment_Checker should attempt to use system Python as a fallback without failing immediately.

**Validates: Requirements 2.3, 3.2, 4.3**

### Property 4: Correct Python Executable Usage

*For any* backtest process spawn, the Backtest_Process_Manager should use the Python executable path from the resolved runtime (bundled or system) that was validated by the Environment_Checker.

**Validates: Requirements 3.1, 3.3**

### Property 5: Path Resolution Based on App Mode

*For any* application mode (development or production), the Environment_Checker should resolve the bundled Python path correctly based on the Electron app.isPackaged property, checking the development resources path when unpacked and the packaged resources path when packed.

**Validates: Requirements 4.1, 4.2, 4.4**

### Property 6: Consistent Path Resolution

*For any* given application state, both Environment_Checker and Backtest_Process_Manager should resolve to the same Python runtime path when queried.

**Validates: Requirements 4.5**

### Property 7: Descriptive Error Messages

*For any* Python validation failure (missing runtime, missing dependencies, incompatible version), the Environment_Checker should return an error message that includes specific details about what is missing or incompatible.

**Validates: Requirements 6.2, 6.3**

### Property 8: Comprehensive Logging

*For any* Python detection or backtest process launch, the system should log the paths checked, the runtime selected, and any errors encountered.

**Validates: Requirements 6.4, 6.5**

### Property 9: Functional Equivalence

*For any* backtest operation, executing it with bundled Python should produce the same result as executing it with system Python (given both have the same version and dependencies).

**Validates: Requirements 7.3**

### Property 10: Process Launch Verification

*For any* backtest process spawn attempt, the Backtest_Process_Manager should verify that the Python process launched successfully and return an error if it failed.

**Validates: Requirements 3.4**

## Error Handling

### Python Not Found

When neither bundled nor system Python is available:
- Return error: "Python runtime not found. Please ensure Python 3.8+ is installed or the application is properly packaged."
- Log all paths checked
- Prevent backtest execution

### Missing Dependencies

When Python is found but dependencies are missing:
- Return error: "Missing required Python packages: [list of packages]. Please install them or use the bundled Python runtime."
- List specific missing packages
- Prevent backtest execution

### Version Incompatibility

When Python version is below 3.8:
- Return error: "Python version {detected} is not compatible. Required: 3.8 or higher."
- Log detected version
- Prevent backtest execution

### Process Launch Failure

When Python process fails to start:
- Return error: "Failed to launch Python process: {error details}"
- Log Python executable path used
- Log spawn error details
- Return error to caller

### Path Resolution Failure

When bundled Python path cannot be determined:
- Log warning: "Could not determine bundled Python path, falling back to system Python"
- Continue with system Python detection
- Do not fail immediately

## Testing Strategy

### Unit Testing

Unit tests will focus on specific scenarios and edge cases:

1. **Path Resolution Tests**
   - Test development mode path resolution
   - Test production mode path resolution
   - Test path resolution with missing directories

2. **Validation Tests**
   - Test Python version validation with various versions (3.7, 3.8, 3.9, 3.10, 3.11)
   - Test dependency checking with missing packages
   - Test dependency checking with all packages present

3. **Error Handling Tests**
   - Test error messages when Python not found
   - Test error messages when dependencies missing
   - Test error messages when version incompatible

4. **Build Configuration Tests**
   - Test that build output includes Python runtime
   - Test that build output includes required packages
   - Test that Python runtime size is under 50MB

### Property-Based Testing

Property-based tests will verify universal behaviors across many inputs. Each test should run a minimum of 100 iterations.

1. **Property Test: Bundled Python Priority** (Property 1)
   - Generate various combinations of bundled/system Python availability
   - Verify bundled Python is always selected when available
   - Tag: **Feature: embedded-python-runtime, Property 1: Bundled Python Priority**

2. **Property Test: Python Runtime Validation** (Property 2)
   - Generate various Python runtime configurations (different versions, different dependency sets)
   - Verify validation correctly identifies valid and invalid runtimes
   - Tag: **Feature: embedded-python-runtime, Property 2: Python Runtime Validation**

3. **Property Test: Fallback to System Python** (Property 3)
   - Generate scenarios where bundled Python is unavailable or invalid
   - Verify system Python is attempted as fallback
   - Tag: **Feature: embedded-python-runtime, Property 3: Fallback to System Python**

4. **Property Test: Correct Python Executable Usage** (Property 4)
   - Generate various backtest scenarios with different Python runtimes
   - Verify the correct executable path is used for spawning
   - Tag: **Feature: embedded-python-runtime, Property 4: Correct Python Executable Usage**

5. **Property Test: Path Resolution Based on App Mode** (Property 5)
   - Generate different app modes (packaged/unpackaged)
   - Verify correct path resolution for each mode
   - Tag: **Feature: embedded-python-runtime, Property 5: Path Resolution Based on App Mode**

6. **Property Test: Consistent Path Resolution** (Property 6)
   - Generate various application states
   - Verify Environment_Checker and Backtest_Process_Manager resolve to same path
   - Tag: **Feature: embedded-python-runtime, Property 6: Consistent Path Resolution**

7. **Property Test: Descriptive Error Messages** (Property 7)
   - Generate various failure scenarios (missing runtime, missing deps, wrong version)
   - Verify error messages contain specific details about the failure
   - Tag: **Feature: embedded-python-runtime, Property 7: Descriptive Error Messages**

8. **Property Test: Comprehensive Logging** (Property 8)
   - Generate various detection and launch scenarios
   - Verify logs contain paths checked, runtime selected, and errors
   - Tag: **Feature: embedded-python-runtime, Property 8: Comprehensive Logging**

9. **Property Test: Functional Equivalence** (Property 9)
   - Generate various backtest operations
   - Execute with both bundled and system Python
   - Verify results are equivalent
   - Tag: **Feature: embedded-python-runtime, Property 9: Functional Equivalence**

10. **Property Test: Process Launch Verification** (Property 10)
    - Generate various process spawn scenarios (successful and failing)
    - Verify launch verification correctly identifies success/failure
    - Tag: **Feature: embedded-python-runtime, Property 10: Process Launch Verification**

### Testing Library

For TypeScript/Node.js, we will use:
- **fast-check** for property-based testing
- **Jest** or **Vitest** for unit testing framework
- **Minimum 100 iterations** per property test

### Integration Testing

Integration tests will verify the complete flow:
1. Application startup → Python detection → Backtest execution
2. Build process → Package verification → Runtime execution
3. Development mode → Production mode transitions

## Implementation Notes

### Python Embeddable Package Setup

1. Download Python Embeddable Package (3.8+) from python.org
2. Extract to `resources/python/`
3. Install pip by running `python get-pip.py`
4. Install required packages: `pip install MetaTrader5 numpy`
5. Remove unnecessary files (tests, docs, tkinter) to reduce size

### Directory Structure

```
resources/
└── python/
    ├── python.exe
    ├── python38.zip (or python3x.zip)
    ├── python38.dll (or python3x.dll)
    ├── Lib/
    │   └── site-packages/
    │       ├── MetaTrader5/
    │       └── numpy/
    └── Scripts/
        └── pip.exe
```

### Size Optimization

To keep bundle under 50MB:
- Remove `test/` directories from packages
- Remove `__pycache__/` directories
- Remove `.pyc` files (will be regenerated)
- Remove documentation files
- Remove tkinter and other unused standard library modules

### Electron Configuration

Ensure Python runtime is not packed in asar:
```javascript
{
  asar: true,
  asarUnpack: [
    'resources/python/**/*'
  ]
}
```

This keeps Python files accessible to the OS for execution.
