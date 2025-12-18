# Changelog

## [1.2.3] - 2025-12-18

### Added
- **Format detection and validation** - library now handles unsupported formats
  - `ImageFormat` enum (`jpeg`, `png`) for supported formats
  - `UnsupportedImageFormatException` - thrown for unsupported formats (HEIC, WebP, GIF, etc.)
  - `BicubicResizer.detectFormat(bytes)` - detect image format from bytes
  - `BicubicResizer.resize(bytes: ...)` - generic resize with auto-detection, throws exception for unsupported formats

## [1.2.2] - 2025-12-18

### Added
- **Crop anchor positions** (`CropAnchor`) - crop from any position, not just center
  - `center` (default), `topLeft`, `topCenter`, `topRight`, `centerLeft`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`
- **Crop aspect ratio modes** (`CropAspectRatio`) - control crop shape
  - `square` (default) - 1:1 aspect ratio
  - `original` - keep original image proportions
  - `custom` - use custom aspect ratio with `aspectRatioWidth`/`aspectRatioHeight`
- **Edge handling modes** (`EdgeMode`) - control how pixels outside bounds are handled
  - `clamp` (default) - repeat edge pixels
  - `wrap` - tile/repeat image
  - `reflect` - mirror reflection at edges
  - `zero` - black/transparent pixels outside
- **JPEG EXIF control** (`applyExifOrientation`) - option to disable EXIF orientation correction
- **PNG compression control** (`compressionLevel`) - adjust compression 0-9 (default: 6)

### Changed
- All new parameters are optional with backward-compatible defaults
- Updated API documentation with comprehensive examples
- Expanded README with new features and usage examples

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
