# API Documentation

Complete API reference for `flutter_bicubic_resize`.

## Table of Contents

- [BicubicResizer](#bicubicresizer)
  - [resizeJpeg](#resizejpeg)
  - [resizePng](#resizepng)
  - [resizeRgb](#resizergb)
  - [resizeRgba](#resizergba)
- [BicubicFilter](#bicubicfilter)
- [EXIF Orientation](#exif-orientation)
- [Center Crop (1:1 Aspect Ratio)](#center-crop-11-aspect-ratio)
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
| `crop` | `double` | No | 1.0 | Square center crop factor (0.0-1.0). Uses min dimension for 1:1 aspect ratio. |

**Returns:** `Uint8List` - Resized JPEG encoded data.

**Features:**
- Automatically applies EXIF orientation (rotates photos from mobile cameras correctly)
- Crop produces 1:1 aspect ratio (square) from center

**Example:**

```dart
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

final resized = BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
  quality: 95,
);

// With center crop - for 1920x1080 image, crop=0.8 takes 864x864 square from center
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

## EXIF Orientation

For JPEG images, `resizeJpeg` automatically reads and applies EXIF orientation metadata. This ensures that photos taken with mobile devices are displayed correctly, regardless of how the camera stored the raw pixels.

**Supported orientations:**

| Value | Transformation |
|-------|----------------|
| 1 | Normal (no transformation) |
| 2 | Flip horizontal |
| 3 | Rotate 180° |
| 4 | Flip vertical |
| 5 | Transpose (rotate 90° CW + flip horizontal) |
| 6 | Rotate 90° clockwise |
| 7 | Transverse (rotate 90° CCW + flip horizontal) |
| 8 | Rotate 90° counter-clockwise |

This is applied automatically - no action needed from the developer.

---

## Center Crop (1:1 Aspect Ratio)

The `crop` parameter extracts a **square region** from the center of the image, using the minimum dimension to ensure no stretching.

**How it works:**

For an image with dimensions 1920x1080:
- `crop: 1.0` → crops 1080x1080 square from center
- `crop: 0.8` → crops 864x864 square from center (80% of 1080)
- `crop: 0.5` → crops 540x540 square from center (50% of 1080)

**Example:**

```dart
// For ML models requiring 224x224 square input
final resized = BicubicResizer.resizeJpeg(
  jpegBytes: photoBytes,  // 4032x3024 photo from camera
  outputWidth: 224,
  outputHeight: 224,
  crop: 1.0,  // Takes 3024x3024 square from center, then resizes to 224x224
);
```

This eliminates distortion that would occur from stretching a non-square image into a square output.

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
