# Changelog

## [1.1.0] - 2025-12-12

### Added
- Optional center crop parameter (`crop`) for all resize methods
- Crop value range: 0.0-1.0 (1.0 = no crop, 0.5 = center 50%)
- Crop is applied before resize for efficient single-pass processing
- Example app now includes crop slider for testing

### Changed
- Updated API documentation with crop parameter
- Updated README with crop usage examples

## [1.0.1] - 2025-12-12

### Fixed
- Fixed GitHub repository links in pubspec.yaml

### Added
- Added API documentation (doc/api.md)
- Added topics for better discoverability on pub.dev
- Added funding link
- Added library documentation comments

## [1.0.0] - 2025-12-12

### Added
- Initial release
- Bicubic resize using native C code (stb_image_resize2)
- RGB and RGBA support
- JPEG and PNG encoding/decoding
- Isolate support for non-blocking operations
- iOS and Android support
