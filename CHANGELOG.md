# Changelog

## [2.0.3] - 2025-01-26

### Changed
- Simplified core assignment to use round-robin approach
- Reduced complexity in process management
- Improved error handling and recovery
- Streamlined logging system
- Updated installation and uninstallation process

### Added
- Basic state tracking for process assignments
- Clear error messages in logs
- Simple CPU threshold monitoring
- Proper log directory permissions

### Removed
- Complex CoreOptimizer class structure
- Unnecessary NUMA architecture handling
- Complex logging queue system
- Log backup during uninstallation

### Fixed
- Process affinity reset during uninstall
- Log directory permissions
- Registry cleanup on uninstall
- Error handling in main loop

## [2.0.2] - Previous Version

Initial version with complex architecture.
