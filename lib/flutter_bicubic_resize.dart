/// Fast, consistent bicubic image resizing for Flutter.
///
/// This library provides native C-based bicubic image resizing that produces
/// identical results on iOS and Android. Uses Catmull-Rom interpolation
/// (same as OpenCV and PIL/Pillow).
///
/// ## Features
///
/// - 100% Native C performance (stb_image + stb_image_resize2)
/// - Identical results on iOS and Android
/// - Bicubic interpolation with multiple filter options
/// - Full native pipeline: decode -> resize -> encode
/// - RGB and RGBA support
/// - JPEG and PNG support with alpha channel preservation
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
///
/// // Resize JPEG
/// final resized = BicubicResizer.resizeJpeg(
///   jpegBytes: originalBytes,
///   outputWidth: 224,
///   outputHeight: 224,
/// );
///
/// // Resize PNG
/// final resizedPng = BicubicResizer.resizePng(
///   pngBytes: originalBytes,
///   outputWidth: 224,
///   outputHeight: 224,
/// );
/// ```
///
/// ## Available Filters
///
/// - [BicubicFilter.catmullRom] - Default. Same as OpenCV/PIL. Best for ML.
/// - [BicubicFilter.cubicBSpline] - Smoother, more blurry.
/// - [BicubicFilter.mitchell] - Balanced between sharp and smooth.
///
/// See the [API documentation](https://github.com/erykkruk/BICUBIC_FLUTTER/blob/main/doc/api.md)
/// for detailed usage information.
library flutter_bicubic_resize;

export 'src/bicubic_resizer.dart';
