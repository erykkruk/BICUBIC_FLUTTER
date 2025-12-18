# flutter_bicubic_resize

**Fastest image resize, crop and compress for Flutter.** 3-4x faster than other libraries. Created and supported by [Codigee](https://codigee.com).

## Features

- **3-4x faster** than other Flutter image libraries (pure native C pipeline)
- 100% Native C performance (stb_image + stb_image_resize + stb_image_write)
- Identical results on iOS and Android
- Bicubic interpolation (Catmull-Rom, same as OpenCV)
- Full native pipeline: decode -> resize -> encode (no Dart image libraries)
- RGB and RGBA support
- JPEG and PNG support with alpha channel preservation
- **EXIF orientation support** - automatically rotates JPEG images correctly
- **Flexible crop system** - anchor position, aspect ratio modes, custom ratios
- **Edge handling modes** - clamp, wrap, reflect, zero
- **PNG compression control** - adjustable compression level
- Zero external Dart dependencies (only `ffi`)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bicubic_resize: ^1.2.2
```

Or run:

```bash
flutter pub add flutter_bicubic_resize
```

## Usage

### Resize JPEG

```dart
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

final resized = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  quality: 95, // optional, default 95
);
```

### Resize PNG

```dart
final resized = BicubicResizer.resizePng(
  pngBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  compressionLevel: 6, // optional, 0-9 (default: 6)
);
```

### Resize raw RGB/RGBA bytes

```dart
// RGB (3 bytes per pixel)
final resizedRgb = BicubicResizer.resizeRgb(
  input: rgbBytes,
  inputWidth: 1920,
  inputHeight: 1080,
  outputWidth: 224,
  outputHeight: 224,
);

// RGBA (4 bytes per pixel)
final resizedRgba = BicubicResizer.resizeRgba(
  input: rgbaBytes,
  inputWidth: 1920,
  inputHeight: 1080,
  outputWidth: 224,
  outputHeight: 224,
);
```

### Custom filter selection

```dart
// Use different bicubic filter
final resized = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  filter: BicubicFilter.mitchell, // or .cubicBSpline
);
```

Available filters:
- `BicubicFilter.catmullRom` - Default. Same as OpenCV/PIL. Best for ML.
- `BicubicFilter.cubicBSpline` - Smoother, more blurry.
- `BicubicFilter.mitchell` - Balanced between sharp and smooth.

### Crop with anchor position

Control where the crop is taken from:

```dart
// Crop from top of image (good for portraits)
final portrait = BicubicResizer.resizeJpeg(
  jpegBytes: photoBytes,
  outputWidth: 224,
  outputHeight: 224,
  crop: 0.8,
  cropAnchor: CropAnchor.topCenter,
);
```

Available anchors:
```
┌─────────────────┐
│ TL    TC    TR  │   topLeft, topCenter, topRight
│                 │
│ CL  CENTER  CR  │   centerLeft, center (default), centerRight
│                 │
│ BL    BC    BR  │   bottomLeft, bottomCenter, bottomRight
└─────────────────┘
```

### Crop aspect ratio modes

Control the shape of the crop:

```dart
// Square crop (default) - 1:1 aspect ratio
final square = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  cropAspectRatio: CropAspectRatio.square,
);

// Keep original proportions
final proportional = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 800,
  outputHeight: 600,
  cropAspectRatio: CropAspectRatio.original,
);

// Custom aspect ratio (16:9)
final widescreen = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 1920,
  outputHeight: 1080,
  cropAspectRatio: CropAspectRatio.custom,
  aspectRatioWidth: 16.0,
  aspectRatioHeight: 9.0,
);
```

### Edge handling modes

Control how pixels outside the image bounds are handled:

```dart
// Wrap mode - creates tiled pattern
final tiled = BicubicResizer.resizeJpeg(
  jpegBytes: textureBytes,
  outputWidth: 512,
  outputHeight: 512,
  edgeMode: EdgeMode.wrap,
);
```

Available modes:
- `EdgeMode.clamp` - Default. Repeat edge pixels.
- `EdgeMode.wrap` - Tile/repeat image (wrap around).
- `EdgeMode.reflect` - Mirror reflection at edges.
- `EdgeMode.zero` - Black/transparent pixels outside bounds.

### EXIF orientation control

For JPEG images, EXIF orientation is applied by default. You can disable it:

```dart
// Get raw pixel orientation (ignore EXIF)
final raw = BicubicResizer.resizeJpeg(
  jpegBytes: photoBytes,
  outputWidth: 224,
  outputHeight: 224,
  applyExifOrientation: false,
);
```

### Complete example with all options

```dart
final result = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 1920,
  outputHeight: 1080,
  quality: 90,
  filter: BicubicFilter.catmullRom,
  edgeMode: EdgeMode.clamp,
  crop: 0.9,
  cropAnchor: CropAnchor.center,
  cropAspectRatio: CropAspectRatio.custom,
  aspectRatioWidth: 16.0,
  aspectRatioHeight: 9.0,
  applyExifOrientation: true,
);
```

## Why?

Default platform APIs use different algorithms:
- Android: Typically Bilinear
- iOS: Depends on context (Lanczos, Bilinear, etc.)

This package uses the **same C code** on both platforms, ensuring **identical output** for the same input.

## Architecture

The entire image processing pipeline runs in native C code:

1. **Decode** - stb_image decodes JPEG/PNG to raw pixels
2. **EXIF orientation** - For JPEG: parses EXIF metadata and applies correct rotation/flip (optional)
3. **Crop** - Extracts region based on anchor position and aspect ratio mode
4. **Resize** - stb_image_resize2 applies bicubic interpolation with selected edge mode
5. **Encode** - stb_image_write encodes back to JPEG/PNG

This means:
- No Dart image libraries needed
- Minimal memory overhead
- Maximum performance
- Consistent results across platforms
- Photos from mobile cameras display correctly (no rotation issues)

## Algorithm

Uses [stb_image_resize2](https://github.com/nothings/stb) with `STBIR_FILTER_CATMULLROM` (Catmull-Rom spline).

This is the same algorithm used by:
- OpenCV `cv2.INTER_CUBIC`
- PIL/Pillow `Image.BICUBIC`

Perfect for ML preprocessing (OpenCLIP, ResNet, etc.) where consistent results with training pipeline matter.

## Performance

**3-4x faster than other Flutter image libraries.** The entire pipeline runs in native C code - no Dart image processing overhead. Operations are synchronous but extremely fast:

- Resize 4K JPEG to 224x224: ~15-30ms
- Crop + resize + compress in single pass
- No memory copying between Dart and native (direct FFI)

## Requirements

- Flutter 3.0+
- Android SDK 21+
- iOS 11.0+

## Sponsor

**[CODIGEE.COM](https://codigee.com)**

## Documentation

- [API Reference](doc/api.md) - Complete API documentation
- [Example App](example/) - Working demo application

## License

MIT License - see [LICENSE](LICENSE) file.

---

[![Codigee - Best Flutter Experts](doc/logo.jpeg)](https://codigee.com)
