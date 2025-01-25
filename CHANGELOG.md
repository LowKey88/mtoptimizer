# Changelog

All notable changes to the MT4/MT5 Core Optimizer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.5] - 2025-01-25

### Fixed
- Log file access issues with proper mutex-based locking
- CPU core assignment instability
- Random core changes affecting terminal performance

### Added
- Thread-safe logging system with message queuing
- Core history tracking to prevent frequent reassignments
- Hysteresis buffer for core selection stability
- 5-minute cooldown period between core changes

### Changed
- Improved logging system with batched writes
- Enhanced core selection algorithm with stability features
- Separated instance count and CPU usage checks
- Added mutex-based file access control
- Implemented proper file handle management
- Added core assignment history tracking

## [1.2.4] - 2025-01-25

### Fixed
- Critical bug in core assignment logic
- Fixed terminals not being distributed across cores
- Fixed terminals not getting affinity at max capacity
- Improved core selection algorithm

### Added
- New Get-BestCore function for smarter core selection
- Two-pass core selection strategy
- Better load balancing across cores

### Changed
- Core selection now considers both usage and instance count
- Always assigns affinity even at capacity
- Improved core distribution logic

## [1.2.3] - 2025-01-25

### Added
- Log file size limit (10MB) with rotation
- Log retention management (5 files)
- Smart status logging based on changes

### Changed
- Reduced log verbosity
- Only log significant system changes
- Improved log message organization
- Enhanced status reporting format

### Optimized
- Log file space usage
- System status updates
- Core usage reporting
- Terminal count logging

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
