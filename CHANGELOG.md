# CHANGELOG

## [0.2.0] - 2025-11-11

### Added
- New `rapicco new` command to create presentation project templates
- PDF up-to-date check: Skip PDF generation if both slide.md and config.yaml are older than the target PDF
- Configuration validation for gem creation with detailed error messages
- README.md validation to ensure proper documentation before gem creation
- Support for `--cols` and `--rows` options in PDF generation
- New constants file (lib/rapicco/constants.rb) for centralized configuration
- GitHub Actions CI workflow for automated testing
- Comprehensive test suite using test-unit framework
- Rakefile for running tests

### Changed
- Renamed configuration file from `config.yml` to `config.yaml`
- Switched test framework from RSpec to test-unit
- Required Ruby version updated from >= 3.0.0 to >= 3.2.0
- Enhanced README.md with detailed usage instructions and examples
- Improved error handling in PDF PageCapturer with better timeout management
- Updated LICENSE copyright owner from PicoRuby to HASUMI Hitoshi
- Enabled `gem push` command for publishing to RubyGems.org

### Removed
- Removed `ffi` dependency from gemspec and Gemfile
- Removed unused exported_pages directory

## [0.1.0] - 2025-11-10
- The first release
