# flutter_bicubic_resize

Fast, consistent bicubic image resizing for Flutter.

## Features

- 100% Native C performance (stb_image + stb_image_resize + stb_image_write)
- Identical results on iOS and Android
- Bicubic interpolation (Catmull-Rom, same as OpenCV)
- Full native pipeline: decode -> resize -> encode (no Dart image libraries)
- RGB and RGBA support
- JPEG and PNG support with alpha channel preservation
- Zero external Dart dependencies (only `ffi`)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bicubic_resize:
    git:
      url: https://github.com/erykkruk/flutter_bicubic_resize.git
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

## Why?

Default platform APIs use different algorithms:
- Android: Typically Bilinear
- iOS: Depends on context (Lanczos, Bilinear, etc.)

This package uses the **same C code** on both platforms, ensuring **identical output** for the same input.

## Architecture

The entire image processing pipeline runs in native C code:

1. **Decode** - stb_image decodes JPEG/PNG to raw pixels
2. **Resize** - stb_image_resize2 applies bicubic interpolation
3. **Encode** - stb_image_write encodes back to JPEG/PNG

This means:
- No Dart image libraries needed
- Minimal memory overhead
- Maximum performance
- Consistent results across platforms

## Algorithm

Uses [stb_image_resize2](https://github.com/nothings/stb) with `STBIR_FILTER_CATMULLROM` (Catmull-Rom spline).

This is the same algorithm used by:
- OpenCV `cv2.INTER_CUBIC`
- PIL/Pillow `Image.BICUBIC`

Perfect for ML preprocessing (OpenCLIP, ResNet, etc.) where consistent results with training pipeline matter.

## Performance

The entire pipeline is native C, making it significantly faster than pure Dart solutions. Operations are synchronous but very fast due to native performance.

## Requirements

- Flutter 3.0+
- Android SDK 21+
- iOS 11.0+

## License

MIT License - see [LICENSE](LICENSE) file.
