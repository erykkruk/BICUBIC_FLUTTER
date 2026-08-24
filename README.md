# flutter_bicubic_resize

**Fastest image resize, crop and compress for Flutter.** 3-4x faster than other libraries. Created and supported by [Codigee](https://codigee.com).

## Documentation

Full hosted documentation lives on codigee.com:

- **[Overview](https://codigee.com/open-source/flutter-bicubic-resize)** — what the package does, benchmarks, and quick start.
- **[API reference](https://codigee.com/open-source/flutter-bicubic-resize/api)** — every method, parameter, and error code (also available as [markdown source](doc/api.md)).
- **[Advanced usage](https://codigee.com/open-source/flutter-bicubic-resize/advanced)** — crop anchors, edge modes, ML preprocessing, and format conversion.

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
- **ML preprocessing** - tensor normalization (ImageNet, centered, custom), HWC/CHW layouts, RGB/BGR ordering
- **ML model presets** - `mobileNet`, `resNet`, `efficientNet`, `yolo`, `openClip` in one argument
- **Batch processing** - resize whole lists in parallel across isolates, with progress reporting
- **Async wrappers** - all methods available as `*Async()` variants using `Isolate.run()`
- **Specific error codes** - descriptive `BicubicResizeException` with native error mapping
- **Image info** - read dimensions, format, and EXIF orientation without decoding pixels
- **File I/O** - `resizeFile()` and `resizeFileToFile()` for path-based workflows
- **Format conversion** - JPEG↔PNG conversion without resizing
- Zero external Dart dependencies (only `ffi`)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bicubic_resize: ^1.8.1
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

### ML preprocessing with normalization

Prepare images for ML models with proper normalization:

```dart
// For TensorFlow Lite / ImageNet models
final Float32List tensor = BicubicResizer.resizeForModel(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.imageNet,
);

// For MobileNet (centered normalization)
final tensor = BicubicResizer.resizeForModel(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.centered,  // [-1, 1]
);

// For PyTorch (CHW layout)
final tensor = BicubicResizer.resizeForModel(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.imageNet,
  layout: TensorLayout.chw,
);

// Custom normalization
final tensor = BicubicResizer.resizeForModel(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.custom,
  meanR: 0.5, meanG: 0.5, meanB: 0.5,
  stdR: 0.5, stdG: 0.5, stdB: 0.5,
);
```

Available normalizations:
- `NormalizationType.none` - Raw pixel values (0-255) as float (default)
- `NormalizationType.simple` - Divide by 255 → [0, 1]
- `NormalizationType.centered` - (pixel / 127.5) - 1 → [-1, 1]
- `NormalizationType.imageNet` - ImageNet mean/std normalization
- `NormalizationType.custom` - User-defined mean/std

Available layouts:
- `TensorLayout.hwc` - Height, Width, Channels (TensorFlow/TFLite)
- `TensorLayout.chw` - Channels, Height, Width (PyTorch)

### ML model presets

Instead of hand-wiring the normalization, layout and input size for a model
family, pass a preset:

```dart
// MobileNet: 224x224, [-1, 1] centered, RGB, HWC - all from the preset
final Float32List tensor = BicubicResizer.resizeForModelPreset(
  bytes: imageBytes,
  preset: NormalizationPreset.mobileNet,
);

// Off the UI thread
final tensor = await BicubicResizer.resizeForModelPresetAsync(
  bytes: imageBytes,
  preset: NormalizationPreset.openClip,
);

// Model variant trained at another resolution (EfficientNet-B4)
final tensor = BicubicResizer.resizeForModelPreset(
  bytes: imageBytes,
  preset: NormalizationPreset.efficientNet,
  outputWidth: 380,
  outputHeight: 380,
);
```

| Preset | Input | Normalization | Layout |
|---|---|---|---|
| `NormalizationPreset.mobileNet` | 224x224 | centered, [-1, 1] | HWC |
| `NormalizationPreset.resNet` | 224x224 | ImageNet mean/std | CHW |
| `NormalizationPreset.efficientNet` | 224x224 | ImageNet mean/std | CHW |
| `NormalizationPreset.yolo` | 640x640 | simple, [0, 1] | CHW |
| `NormalizationPreset.openClip` | 224x224 | CLIP mean/std | CHW |

Every preset exposes its values, so they can be read without running a resize:

```dart
const preset = NormalizationPreset.yolo;
print(preset.inputSize);     // 640
print(preset.tensorLength);  // 640 * 640 * 3
print(preset.mean);          // [0.0, 0.0, 0.0]
print(preset.label);         // YOLO
```

All presets are RGB. BGR models still need an explicit `channelOrder` on
`resizeForModel`.

### Batch processing

Process a whole list of images in parallel across isolates. Results keep the
input order no matter which image finishes first:

```dart
// Thumbnails, with a progress bar
final List<Uint8List> thumbnails = await BicubicResizer.resizeBatch(
  images: pickedFiles,
  outputWidth: 512,
  outputHeight: 512,
  onProgress: (done, total) => setState(() => _progress = done / total),
);

// A batch of model tensors, straight from a preset
final List<Float32List> tensors =
    await BicubicResizer.resizeForModelPresetBatch(
  images: frames,
  preset: NormalizationPreset.yolo,
);

// Full control over the preprocessing
final tensors = await BicubicResizer.resizeForModelBatch(
  images: frames,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.imageNet,
  layout: TensorLayout.chw,
  concurrency: 4,
);
```

`concurrency` defaults to `BicubicResizer.defaultBatchConcurrency` (one isolate
per CPU core minus one, so the UI isolate keeps a core). Batches are fail-fast:
the first image that fails completes the future with its exception.

### Fit within bounds (preserve aspect ratio)

Resize an image so it fits entirely inside a maximum bounding box without
distortion or cropping. The output dimensions are computed for you from the
image's real size, so you only supply the box:

```dart
// Produce a thumbnail no larger than 512x512, keeping the aspect ratio.
final thumbnail = BicubicResizer.resizeToFit(
  bytes: photoBytes,
  maxWidth: 512,
  maxHeight: 512,
);

// Images smaller than the box are returned untouched by default.
// Pass allowUpscale: true to enlarge them to fill the box instead.
final enlarged = BicubicResizer.resizeToFit(
  bytes: iconBytes,
  maxWidth: 1024,
  maxHeight: 1024,
  allowUpscale: true,
);
```

Need only the target dimensions (e.g. to lay out a UI before resizing)? Use the
pure, decode-free calculation directly:

```dart
final target = BicubicResizer.computeFitDimensions(
  sourceWidth: 4000,
  sourceHeight: 3000,
  maxWidth: 1024,
  maxHeight: 1024,
);
// target == BicubicDimensions(1024x768)
```

### Get image info (without decoding)

Read image dimensions, format, and EXIF orientation without decoding pixel data:

```dart
final info = BicubicResizer.getImageInfo(imageBytes);
print('${info.width}x${info.height}');          // Raw dimensions
print('${info.orientedWidth}x${info.orientedHeight}'); // After EXIF rotation
print('Format: ${info.format}');                 // ImageFormat.jpeg or .png
print('Channels: ${info.channels}');             // 1, 3, or 4
print('EXIF orientation: ${info.exifOrientation}'); // 1-8
```

### Resize from file path

Convenience methods for file-based workflows:

```dart
// Read file, resize, get bytes
final resized = BicubicResizer.resizeFile(
  inputPath: '/path/to/photo.jpg',
  outputWidth: 800,
  outputHeight: 600,
);

// Read file, resize, save to output file
BicubicResizer.resizeFileToFile(
  inputPath: '/path/to/photo.jpg',
  outputPath: '/path/to/thumbnail.jpg',
  outputWidth: 200,
  outputHeight: 200,
);
```

### Format conversion (JPEG ↔ PNG)

Convert between formats without resizing:

```dart
// JPEG to PNG
final pngBytes = BicubicResizer.jpegToPng(jpegBytes: jpegData);

// PNG to JPEG (alpha channel is discarded)
final jpegBytes = BicubicResizer.pngToJpeg(pngBytes: pngData, quality: 90);

// Auto-detect and convert
final converted = BicubicResizer.convertFormat(
  bytes: imageBytes,
  targetFormat: ImageFormat.png,
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

### Async methods

All resize methods have async counterparts that run in a separate isolate, keeping the UI thread free:

```dart
// Non-blocking JPEG resize
final resized = await BicubicResizer.resizeJpegAsync(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
);

// Non-blocking PNG resize
final resizedPng = await BicubicResizer.resizePngAsync(
  pngBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
);

// Non-blocking auto-detect resize
final resized = await BicubicResizer.resizeAsync(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
);

// Non-blocking ML preprocessing
final Float32List tensor = await BicubicResizer.resizeForModelAsync(
  bytes: imageBytes,
  outputWidth: 224,
  outputHeight: 224,
  normalization: NormalizationType.imageNet,
);
```

Available async methods: `resizeJpegAsync`, `resizePngAsync`, `resizeRgbAsync`, `resizeRgbaAsync`, `resizeAsync`, `resizeForModelAsync`, `getImageInfoAsync`, `resizeFileAsync`, `resizeFileToFileAsync`, `jpegToPngAsync`, `pngToJpegAsync`, `convertFormatAsync`.

### Error handling

Native errors return specific codes mapped to `BicubicResizeException`:

```dart
try {
  final resized = BicubicResizer.resizeJpeg(
    jpegBytes: corruptBytes,
    outputWidth: 224,
    outputHeight: 224,
  );
} on BicubicResizeException catch (e) {
  print(e.error);      // BicubicNativeError.decodeFailed
  print(e.nativeCode); // -3
  print(e.message);    // "Image decoding failed (corrupt or unsupported data)"
}
```

| Error | Code | Cause |
|-------|------|-------|
| `nullInput` | -1 | Null pointer passed to native function |
| `invalidDims` | -2 | Width, height, or size <= 0 |
| `decodeFailed` | -3 | Corrupt or unsupported image data |
| `allocFailed` | -4 | Memory allocation failed |
| `encodeFailed` | -5 | JPEG/PNG encoding failed |
| `formatUnknown` | -6 | Unknown or unsupported image format |

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

## Example

- [Example App](example/) - Working demo application. Full API docs are linked in [Documentation](#documentation) above.

## License

MIT License - see [LICENSE](LICENSE) file.

---

[![Codigee - Best Flutter Experts](doc/logo.jpeg)](https://codigee.com)
