# Changelog

## [1.2.1] - 2025-12-14

### Fixed
- **iOS release build crash** - Fixed FFI symbol stripping issue that caused "symbol not found" errors in release/archive builds
- Added proper Xcode build settings to prevent symbol stripping (`STRIP_STYLE=non-global`)
- Added symbol retention mechanism in Swift plugin to ensure C functions are linked

## [1.2.0] - 2025-12-14

### Added
- **EXIF orientation support** for JPEG images - photos from mobile cameras now display correctly
- Automatic rotation/flip based on EXIF metadata (supports all 8 orientation values)

### Changed
- **Breaking:** Crop now produces 1:1 aspect ratio (square) instead of proportional crop
  - `crop: 1.0` on 1920x1080 image now crops to 1080x1080 (not 1920x1080)
  - This prevents stretching when resizing to square output (e.g., 224x224)
- Updated README with new features documentation

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
