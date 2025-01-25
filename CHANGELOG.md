# Changelog

All notable changes to the MT4/MT5 Core Optimizer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2025-01-25

### Added
- Version tracking and display in logs
- Comprehensive cleanup of old installations
- Version file for installation tracking
- Detailed installation status messages

### Enhanced
- Improved process termination handling
- Better affinity reset during updates
- More informative installation feedback
- Cleaner update process

## [1.2.1] - 2025-01-25

### Changed
- Unified MaxPerCore to 3 for all CPU configurations
- Standardized configuration across all core counts
- Improved core assignment documentation
- Updated default configuration to match standard settings

## [1.2.0] - 2025-01-25

### Changed
- Unified CPU threshold to 75% across all core configurations
- Removed instance limits for continuous optimization
- Enhanced core assignment for high instance counts
- Optimized resource utilization for all CPU cores

## [1.1.0] - 2025-01-25

### Changed
- Simplified process detection to focus on terminal.exe
- Enhanced CPU core optimization logic
- Improved logging with detailed status information
- Added comprehensive code documentation
- Optimized script performance and memory usage
- Updated configuration thresholds for different CPU cores
- Enhanced error handling and cleanup procedures

## [1.0.0] - 2025-01-25

### Added
- Initial release of MT4/MT5 Core Optimizer
- Intelligent CPU core allocation system
- Dynamic process monitoring and management
- Adaptive configuration based on CPU cores
- Automatic installation and setup
- Windows Registry integration for auto-start
- Comprehensive logging system
- Safe cleanup procedures
- Administrator privilege handling
- Support for both MT4 and MT5 terminals

### Features
- Core allocation based on CPU usage thresholds
- Configurable instances per core based on system specifications
- Real-time process monitoring and reallocation
- Automatic affinity cleanup on service termination
- Detailed logging for troubleshooting
