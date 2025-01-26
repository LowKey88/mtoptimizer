# Changelog

## [2.0.4] - 2025-01-26

### Changed
- Standardized resource allocation across all VPS plans:
  - Set consistent 3 terminals per core for all configurations
  - Unified CPU threshold to 75% for all core counts
  - Optimized for VPS Forex plans (Lite, Pro, Plus, Max)
- Updated default configuration values to match standardized settings
- Improved installation process:
  - Removed automatic old installation cleanup
  - Added proper existing installation check
  - Better separation between install and uninstall scripts
- Improved uninstaller behavior:
  - Removed affinity reset during uninstall
  - Preserves terminal CPU optimizations
  - Added comprehensive uninstallation verification
  - Process and service status checks
  - Installation cleanup verification
  - Detailed status reporting
- Enhanced service management:
   - Added Stop-MTOptimizer.ps1 for reliable service stopping
   - Added Start-MTOptimizer.ps1 for safe service starting
   - Implemented daily log cleanup at midnight
   - Added log cleanup on service startup

## [2.0.3] - 2025-01-26

### Changed
- Simplified core assignment to use round-robin approach
- Reduced complexity in process management
- Improved error handling and recovery
- Enhanced logging system with detailed process tracking
- Updated installation and uninstallation process
- Improved terminal lifecycle monitoring
- Enhanced process cleanup mechanism

### Added
- Basic state tracking for process assignments
- Clear error messages in logs
- Simple CPU threshold monitoring
- Proper log directory permissions
- Explicit terminal termination logging
- Terminal count change tracking
- Detailed core assignment status reporting
- Process-to-core mapping logs
- Active process enumeration
- Terminal lifecycle event tracking

### Removed
- Complex CoreOptimizer class structure
- Unnecessary NUMA architecture handling
- Complex logging queue system
- Log backup during uninstallation

### Fixed
- Process affinity reset during uninstall
- Processor affinity calculation for 2-core systems
- Processor affinity handling for all core configurations with dynamic fallback
- Improved core validation and assignment logic for multi-core systems
- Registry cleanup on uninstall
- Error handling in main loop
- Process termination detection and cleanup

## [2.0.2] - Previous Version

Initial version with complex architecture.
