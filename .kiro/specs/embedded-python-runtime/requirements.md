# Requirements Document: Embedded Python Runtime

## Introduction

This feature enables the GUI application to bundle a Python runtime, eliminating the need for users to install Python separately. The embedded runtime will include all necessary dependencies for the backtest feature, providing an out-of-the-box experience while maintaining backward compatibility with system Python installations for development scenarios.

## Glossary

- **Embedded_Python_Runtime**: A minimal, self-contained Python distribution bundled with the application
- **Python_Embeddable_Package**: Microsoft's official minimal Python distribution for Windows
- **Environment_Checker**: The system component responsible for validating Python availability and configuration
- **Backtest_Process_Manager**: The system component that spawns and manages Python backtest processes
- **Bundled_Python**: The Python runtime included in the application package
- **System_Python**: A Python installation present on the user's system PATH
- **Application_Package**: The distributed Electron application bundle
- **Python_Dependencies**: Required Python packages (MetaTrader5, numpy) for backtest functionality

## Requirements

### Requirement 1: Python Runtime Bundling

**User Story:** As a developer, I want to bundle the Python Embeddable Package with the application, so that users receive a complete runtime without external dependencies.

#### Acceptance Criteria

1. THE Application_Package SHALL include Python Embeddable Package version 3.8 or higher
2. THE Application_Package SHALL include the MetaTrader5 Python package in the bundled site-packages
3. THE Application_Package SHALL include the numpy Python package in the bundled site-packages
4. THE Bundled_Python SHALL be located in the resources/python directory within the Application_Package
5. THE Application_Package SHALL maintain a total Python runtime size under 50MB

### Requirement 2: Python Runtime Detection

**User Story:** As a user, I want the application to automatically use the bundled Python, so that I don't need to configure anything manually.

#### Acceptance Criteria

1. WHEN the application starts, THE Environment_Checker SHALL detect the presence of Bundled_Python before checking System_Python
2. WHEN Bundled_Python is available, THE Environment_Checker SHALL validate that it includes all required Python_Dependencies
3. IF Bundled_Python is not available, THEN THE Environment_Checker SHALL attempt to use System_Python
4. WHEN validating Python availability, THE Environment_Checker SHALL verify the Python version is 3.8 or higher
5. IF neither Bundled_Python nor System_Python is available, THEN THE Environment_Checker SHALL return an error indicating Python is not found

### Requirement 3: Backtest Process Execution

**User Story:** As a user, I want the backtest feature to use the bundled Python automatically, so that backtests run without additional setup.

#### Acceptance Criteria

1. WHEN spawning a backtest process, THE Backtest_Process_Manager SHALL use Bundled_Python if available
2. WHEN Bundled_Python is not available, THE Backtest_Process_Manager SHALL use System_Python as a fallback
3. WHEN executing a backtest, THE Backtest_Process_Manager SHALL pass the correct Python executable path to the spawn command
4. WHEN a backtest process starts, THE Backtest_Process_Manager SHALL verify the Python process launched successfully
5. IF the Python process fails to launch, THEN THE Backtest_Process_Manager SHALL return a descriptive error message

### Requirement 4: Development and Production Mode Support

**User Story:** As a developer, I want the application to work in both development and production modes, so that I can test changes without rebuilding the package.

#### Acceptance Criteria

1. WHEN running in development mode, THE Environment_Checker SHALL check for Bundled_Python in the development resources path
2. WHEN running in production mode, THE Environment_Checker SHALL check for Bundled_Python in the packaged resources path
3. WHEN Bundled_Python is not found in development mode, THE Environment_Checker SHALL fall back to System_Python without error
4. THE Environment_Checker SHALL determine the correct resources path based on the Electron app.isPackaged property
5. THE Backtest_Process_Manager SHALL use the same path resolution logic as Environment_Checker

### Requirement 5: Build Configuration

**User Story:** As a developer, I want the build process to automatically include the Python runtime, so that the packaged application is complete.

#### Acceptance Criteria

1. WHEN building the application, THE electron-builder configuration SHALL copy the Python runtime to the resources directory
2. WHEN building the application, THE electron-builder configuration SHALL include all Python_Dependencies in the bundle
3. THE electron-builder configuration SHALL preserve the directory structure of the Python Embeddable Package
4. THE electron-builder configuration SHALL exclude unnecessary Python files to minimize bundle size
5. WHEN the build completes, THE Application_Package SHALL contain a functional Python runtime in resources/python

### Requirement 6: Error Handling and Diagnostics

**User Story:** As a user, I want clear error messages when Python issues occur, so that I can understand and resolve problems.

#### Acceptance Criteria

1. WHEN Python is not found, THE Environment_Checker SHALL provide an error message indicating no Python runtime is available
2. WHEN Python_Dependencies are missing, THE Environment_Checker SHALL list which packages are missing
3. WHEN the Python version is incompatible, THE Environment_Checker SHALL indicate the required version and detected version
4. WHEN a backtest process fails to start, THE Backtest_Process_Manager SHALL log the Python executable path and error details
5. THE Environment_Checker SHALL log the Python detection process including paths checked and results

### Requirement 7: Backward Compatibility

**User Story:** As a developer with Python installed, I want the application to continue working with my system Python, so that my development workflow is not disrupted.

#### Acceptance Criteria

1. WHEN System_Python is available and Bundled_Python is not, THE application SHALL function normally using System_Python
2. WHEN both Bundled_Python and System_Python are available, THE application SHALL prefer Bundled_Python
3. THE application SHALL support the same Python operations with both Bundled_Python and System_Python
4. WHEN using System_Python, THE Environment_Checker SHALL verify all Python_Dependencies are installed
5. THE application SHALL not modify or interfere with System_Python installations
