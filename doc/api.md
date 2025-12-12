# API Documentation

Complete API reference for `flutter_bicubic_resize`.

## Table of Contents

- [BicubicResizer](#bicubicresizer)
  - [resizeJpeg](#resizejpeg)
  - [resizePng](#resizepng)
  - [resizeRgb](#resizergb)
  - [resizeRgba](#resizergba)
- [BicubicFilter](#bicubicfilter)
- [Error Handling](#error-handling)
- [Performance Tips](#performance-tips)

---

## BicubicResizer

Main class providing static methods for image resizing.

### resizeJpeg

Resize JPEG image bytes using bicubic interpolation.

```dart
static Uint8List resizeJpeg({
  required Uint8List jpegBytes,
  required int outputWidth,
  required int outputHeight,
  int quality = 95,
  BicubicFilter filter = BicubicFilter.catmullRom,
  double crop = 1.0,
})
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `jpegBytes` | `Uint8List` | Yes | - | JPEG encoded image data |
| `outputWidth` | `int` | Yes | - | Desired output width in pixels |
| `outputHeight` | `int` | Yes | - | Desired output height in pixels |
| `quality` | `int` | No | 95 | JPEG output quality (1-100) |
| `filter` | `BicubicFilter` | No | `catmullRom` | Bicubic filter type |
| `crop` | `double` | No | 1.0 | Center crop factor (0.0-1.0). 1.0 = no crop, 0.5 = center 50% |

**Returns:** `Uint8List` - Resized JPEG encoded data.

**Example:**

```dart
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

final resized = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  quality: 95,
);

// With center crop - take center 80% before resizing
final cropped = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  crop: 0.8,
);
```

---

### resizePng

Resize PNG image bytes using bicubic interpolation. Preserves alpha channel if present.

```dart
static Uint8List resizePng({
  required Uint8List pngBytes,
  required int outputWidth,
  required int outputHeight,
  BicubicFilter filter = BicubicFilter.catmullRom,
  double crop = 1.0,
})
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `pngBytes` | `Uint8List` | Yes | - | PNG encoded image data |
| `outputWidth` | `int` | Yes | - | Desired output width in pixels |
| `outputHeight` | `int` | Yes | - | Desired output height in pixels |
| `filter` | `BicubicFilter` | No | `catmullRom` | Bicubic filter type |
| `crop` | `double` | No | 1.0 | Center crop factor (0.0-1.0). 1.0 = no crop, 0.5 = center 50% |

**Returns:** `Uint8List` - Resized PNG encoded data.

**Example:**

```dart
final resized = BicubicResizer.resizePng(
  pngBytes: originalBytes,
  outputWidth: 512,
  outputHeight: 512,
);

// With center crop
final cropped = BicubicResizer.resizePng(
  pngBytes: originalBytes,
  outputWidth: 512,
  outputHeight: 512,
  crop: 0.7, // Take center 70%
);
```

---

### resizeRgb

Resize raw RGB bytes (3 bytes per pixel) using bicubic interpolation.

```dart
static Uint8List resizeRgb({
  required Uint8List input,
  required int inputWidth,
  required int inputHeight,
  required int outputWidth,
  required int outputHeight,
  BicubicFilter filter = BicubicFilter.catmullRom,
  double crop = 1.0,
})
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `input` | `Uint8List` | Yes | - | Raw RGB pixel data (3 bytes per pixel) |
| `inputWidth` | `int` | Yes | - | Width of input image in pixels |
| `inputHeight` | `int` | Yes | - | Height of input image in pixels |
| `outputWidth` | `int` | Yes | - | Desired output width |
| `outputHeight` | `int` | Yes | - | Desired output height |
| `filter` | `BicubicFilter` | No | `catmullRom` | Bicubic filter type |
| `crop` | `double` | No | 1.0 | Center crop factor (0.0-1.0). 1.0 = no crop, 0.5 = center 50% |

**Returns:** `Uint8List` - Resized RGB pixel data.

**Throws:** `ArgumentError` if input size doesn't match `inputWidth * inputHeight * 3`.

**Example:**

```dart
final resizedRgb = BicubicResizer.resizeRgb(
  input: rgbBytes,
  inputWidth: 1920,
  inputHeight: 1080,
  outputWidth: 224,
  outputHeight: 224,
  crop: 0.9, // Optional center crop
);
```

---

### resizeRgba

Resize raw RGBA bytes (4 bytes per pixel) using bicubic interpolation.

```dart
static Uint8List resizeRgba({
  required Uint8List input,
  required int inputWidth,
  required int inputHeight,
  required int outputWidth,
  required int outputHeight,
  BicubicFilter filter = BicubicFilter.catmullRom,
  double crop = 1.0,
})
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `input` | `Uint8List` | Yes | - | Raw RGBA pixel data (4 bytes per pixel) |
| `inputWidth` | `int` | Yes | - | Width of input image in pixels |
| `inputHeight` | `int` | Yes | - | Height of input image in pixels |
| `outputWidth` | `int` | Yes | - | Desired output width |
| `outputHeight` | `int` | Yes | - | Desired output height |
| `filter` | `BicubicFilter` | No | `catmullRom` | Bicubic filter type |
| `crop` | `double` | No | 1.0 | Center crop factor (0.0-1.0). 1.0 = no crop, 0.5 = center 50% |

**Returns:** `Uint8List` - Resized RGBA pixel data.

**Throws:** `ArgumentError` if input size doesn't match `inputWidth * inputHeight * 4`.

**Example:**

```dart
final resizedRgba = BicubicResizer.resizeRgba(
  input: rgbaBytes,
  inputWidth: 1920,
  inputHeight: 1080,
  outputWidth: 224,
  outputHeight: 224,
  crop: 0.85, // Optional center crop
);
```

---

## BicubicFilter

Enum defining available bicubic filter types.

```dart
enum BicubicFilter {
  catmullRom,   // value: 0
  cubicBSpline, // value: 1
  mitchell,     // value: 2
}
```

### Filter Comparison

| Filter | Description | Use Case |
|--------|-------------|----------|
| `catmullRom` | Catmull-Rom spline. Same as OpenCV `INTER_CUBIC` and PIL `BICUBIC`. | **Default.** Best for ML preprocessing. Produces sharp results. |
| `cubicBSpline` | Cubic B-Spline interpolation. | Smoother, more blurry results. Good for artistic effects. |
| `mitchell` | Mitchell-Netravali filter. | Balanced between sharp and smooth. Good general-purpose filter. |

**Example:**

```dart
// Use Mitchell filter for balanced results
final resized = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  filter: BicubicFilter.mitchell,
);
```

---

## Error Handling

All methods throw exceptions on failure:

| Exception | Cause |
|-----------|-------|
| `ArgumentError` | Input size mismatch for raw pixel methods |
| `Exception` | Native resize operation failed |

**Example:**

```dart
try {
  final resized = BicubicResizer.resizeJpeg(
    jpegBytes: invalidBytes,
    outputWidth: 224,
    outputHeight: 224,
  );
} catch (e) {
  print('Resize failed: $e');
}
```

---

## Performance Tips

1. **Operations are synchronous** - The native C code is very fast, so operations complete quickly without needing async/await.

2. **Memory efficiency** - The entire pipeline (decode -> resize -> encode) runs in native code, minimizing memory overhead.

3. **For batch processing** - Consider using `compute()` to run resizing in an isolate:

```dart
import 'package:flutter/foundation.dart';

Future<Uint8List> resizeInBackground(Uint8List jpegBytes) {
  return compute(
    (bytes) => BicubicResizer.resizeJpeg(
      jpegBytes: bytes,
      outputWidth: 224,
      outputHeight: 224,
    ),
    jpegBytes,
  );
}
```

4. **Choosing output quality** - For JPEG, quality 85-95 provides good balance between file size and visual quality. Use 95+ for archival or when quality is critical.

---

## See Also

- [README](https://github.com/erykkruk/BICUBIC_FLUTTER/blob/main/README.md) - Quick start guide
- [CHANGELOG](https://github.com/erykkruk/BICUBIC_FLUTTER/blob/main/CHANGELOG.md) - Version history
- [Example app](https://github.com/erykkruk/BICUBIC_FLUTTER/tree/main/example) - Working demo application
