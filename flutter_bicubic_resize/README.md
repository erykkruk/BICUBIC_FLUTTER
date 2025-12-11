# flutter_bicubic_resize

Fast, consistent bicubic image resizing for Flutter.

## Features

- Native C performance (stb_image_resize)
- Identical results on iOS and Android
- Bicubic interpolation (Cubic B-Spline)
- RGB and RGBA support
- Runs in isolate (non-blocking)
- Supports JPEG and PNG encoding/decoding

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bicubic_resize:
    git:
      url: https://github.com/YOUR_USERNAME/flutter_bicubic_resize.git
```

## Usage

### Resize JPEG (async, recommended)

```dart
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

final resized = await BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  quality: 95, // optional, default 95
);
```

### Resize PNG (async)

```dart
final resized = await BicubicResizer.resizePng(
  pngBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
);
```

### Resize raw RGB/RGBA bytes (sync)

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

## Why?

Default platform APIs use different algorithms:
- Android: Typically Bilinear
- iOS: Depends on context (Lanczos, Bilinear, etc.)

This package uses the **same C code** on both platforms, ensuring **identical output** for the same input.

## Algorithm

Uses [stb_image_resize2](https://github.com/nothings/stb) with `STBIR_FILTER_CUBICBSPLINE` (standard Bicubic B-Spline interpolation).

## Performance

The native C implementation is significantly faster than pure Dart solutions. The async methods (`resizeJpeg`, `resizePng`) run in an isolate to avoid blocking the UI thread.

## Requirements

- Flutter 3.0+
- Android SDK 21+
- iOS 11.0+

## License

MIT License - see [LICENSE](LICENSE) file.
