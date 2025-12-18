import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'native_bindings.dart';

/// Supported image formats for resize operations
enum ImageFormat {
  /// JPEG format
  jpeg,

  /// PNG format
  png,
}

/// Exception thrown when an unsupported image format is detected.
///
/// This library only supports JPEG and PNG formats.
/// Other formats like HEIC, WebP, GIF, BMP, etc. are not supported.
class UnsupportedImageFormatException implements Exception {
  /// The raw bytes that were passed to the resize method
  final Uint8List bytes;

  /// Human-readable message describing the error
  final String message;

  UnsupportedImageFormatException({
    required this.bytes,
    this.message = 'Unsupported image format. Only JPEG and PNG are supported.',
  });

  @override
  String toString() => 'UnsupportedImageFormatException: $message';
}

/// Available bicubic filter types
enum BicubicFilter {
  /// Catmull-Rom spline (same as OpenCV INTER_CUBIC, PIL BICUBIC)
  /// Best for ML preprocessing. Default.
  catmullRom(0),

  /// Cubic B-Spline (smoother, more blurry)
  cubicBSpline(1),

  /// Mitchell-Netravali (balanced between sharp and smooth)
  mitchell(2);

  final int value;
  const BicubicFilter(this.value);
}

/// Edge handling modes for resize operations
enum EdgeMode {
  /// Repeat edge pixels (default)
  clamp(0),

  /// Wrap around (tile/repeat image)
  wrap(1),

  /// Mirror reflection at edges
  reflect(2),

  /// Black/transparent pixels outside bounds
  zero(3);

  final int value;
  const EdgeMode(this.value);
}

/// Crop anchor positions
enum CropAnchor {
  /// Center of the image (default)
  center(0),

  /// Top-left corner
  topLeft(1),

  /// Top center
  topCenter(2),

  /// Top-right corner
  topRight(3),

  /// Center left
  centerLeft(4),

  /// Center right
  centerRight(5),

  /// Bottom-left corner
  bottomLeft(6),

  /// Bottom center
  bottomCenter(7),

  /// Bottom-right corner
  bottomRight(8);

  final int value;
  const CropAnchor(this.value);
}

/// Crop aspect ratio modes
enum CropAspectRatio {
  /// 1:1 square crop (default) - crops to the largest square that fits
  square(0),

  /// Keep original aspect ratio - scales proportionally
  original(1),

  /// Custom aspect ratio - use [aspectRatioWidth] and [aspectRatioHeight]
  custom(2);

  final int value;
  const CropAspectRatio(this.value);
}

class BicubicResizer {
  // ============================================================================
  // Raw pixel resize (sync)
  // ============================================================================

  /// Resize raw RGB bytes using bicubic interpolation
  ///
  /// [input] - Raw RGB pixel data (3 bytes per pixel)
  /// [inputWidth] - Width of input image in pixels
  /// [inputHeight] - Height of input image in pixels
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [filter] - Bicubic filter type (default: Catmull-Rom)
  /// [edgeMode] - How to handle pixels outside image bounds (default: clamp)
  /// [crop] - Crop factor (0.0-1.0), 1.0 = no crop, 0.5 = 50%
  /// [cropAnchor] - Position to anchor the crop (default: center)
  /// [cropAspectRatio] - Aspect ratio mode for crop (default: square)
  /// [aspectRatioWidth] - Custom aspect ratio width (only used with CropAspectRatio.custom)
  /// [aspectRatioHeight] - Custom aspect ratio height (only used with CropAspectRatio.custom)
  ///
  /// Returns resized RGB pixel data
  static Uint8List resizeRgb({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
  }) {
    final expectedInputSize = inputWidth * inputHeight * 3;
    if (input.length != expectedInputSize) {
      throw ArgumentError(
        'Input size mismatch: expected $expectedInputSize bytes, got ${input.length}',
      );
    }

    final outputSize = outputWidth * outputHeight * 3;
    final inputPtr = calloc<Uint8>(input.length);
    final outputPtr = calloc<Uint8>(outputSize);

    try {
      inputPtr.asTypedList(input.length).setAll(0, input);

      final result = NativeBindings.instance.bicubicResizeRgb(
        inputPtr,
        inputWidth,
        inputHeight,
        outputPtr,
        outputWidth,
        outputHeight,
        filter.value,
        edgeMode.value,
        crop,
        cropAnchor.value,
        cropAspectRatio.value,
        aspectRatioWidth,
        aspectRatioHeight,
      );

      if (result != 0) {
        throw Exception('Native bicubic resize failed with code: $result');
      }

      return Uint8List.fromList(outputPtr.asTypedList(outputSize));
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputPtr);
    }
  }

  /// Resize raw RGBA bytes using bicubic interpolation
  ///
  /// [input] - Raw RGBA pixel data (4 bytes per pixel)
  /// [inputWidth] - Width of input image in pixels
  /// [inputHeight] - Height of input image in pixels
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [filter] - Bicubic filter type (default: Catmull-Rom)
  /// [edgeMode] - How to handle pixels outside image bounds (default: clamp)
  /// [crop] - Crop factor (0.0-1.0), 1.0 = no crop, 0.5 = 50%
  /// [cropAnchor] - Position to anchor the crop (default: center)
  /// [cropAspectRatio] - Aspect ratio mode for crop (default: square)
  /// [aspectRatioWidth] - Custom aspect ratio width (only used with CropAspectRatio.custom)
  /// [aspectRatioHeight] - Custom aspect ratio height (only used with CropAspectRatio.custom)
  ///
  /// Returns resized RGBA pixel data
  static Uint8List resizeRgba({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
  }) {
    final expectedInputSize = inputWidth * inputHeight * 4;
    if (input.length != expectedInputSize) {
      throw ArgumentError(
        'Input size mismatch: expected $expectedInputSize bytes, got ${input.length}',
      );
    }

    final outputSize = outputWidth * outputHeight * 4;
    final inputPtr = calloc<Uint8>(input.length);
    final outputPtr = calloc<Uint8>(outputSize);

    try {
      inputPtr.asTypedList(input.length).setAll(0, input);

      final result = NativeBindings.instance.bicubicResizeRgba(
        inputPtr,
        inputWidth,
        inputHeight,
        outputPtr,
        outputWidth,
        outputHeight,
        filter.value,
        edgeMode.value,
        crop,
        cropAnchor.value,
        cropAspectRatio.value,
        aspectRatioWidth,
        aspectRatioHeight,
      );

      if (result != 0) {
        throw Exception('Native bicubic resize failed with code: $result');
      }

      return Uint8List.fromList(outputPtr.asTypedList(outputSize));
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputPtr);
    }
  }

  // ============================================================================
  // JPEG resize (full native pipeline)
  // ============================================================================

  /// Resize JPEG image bytes using bicubic interpolation
  ///
  /// Entire pipeline (decode -> resize -> encode) runs in native C code.
  /// This is synchronous but very fast due to native performance.
  ///
  /// [jpegBytes] - JPEG encoded image data
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [quality] - JPEG output quality (1-100, default 95)
  /// [filter] - Bicubic filter type (default: Catmull-Rom)
  /// [edgeMode] - How to handle pixels outside image bounds (default: clamp)
  /// [crop] - Crop factor (0.0-1.0), 1.0 = no crop, 0.5 = 50%
  /// [cropAnchor] - Position to anchor the crop (default: center)
  /// [cropAspectRatio] - Aspect ratio mode for crop (default: square)
  /// [aspectRatioWidth] - Custom aspect ratio width (only used with CropAspectRatio.custom)
  /// [aspectRatioHeight] - Custom aspect ratio height (only used with CropAspectRatio.custom)
  /// [applyExifOrientation] - Whether to apply EXIF orientation (default: true)
  ///
  /// Returns resized JPEG encoded data
  static Uint8List resizeJpeg({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
    bool applyExifOrientation = true,
  }) {
    final inputPtr = calloc<Uint8>(jpegBytes.length);
    final outputDataPtr = calloc<Pointer<Uint8>>();
    final outputSizePtr = calloc<Int32>();

    try {
      inputPtr.asTypedList(jpegBytes.length).setAll(0, jpegBytes);

      final result = NativeBindings.instance.bicubicResizeJpeg(
        inputPtr,
        jpegBytes.length,
        outputWidth,
        outputHeight,
        quality,
        filter.value,
        edgeMode.value,
        crop,
        cropAnchor.value,
        cropAspectRatio.value,
        aspectRatioWidth,
        aspectRatioHeight,
        applyExifOrientation ? 1 : 0,
        outputDataPtr,
        outputSizePtr,
      );

      if (result != 0) {
        throw Exception('Native JPEG resize failed with code: $result');
      }

      final outputData = outputDataPtr.value;
      final outputSize = outputSizePtr.value;

      // Copy data before freeing native buffer
      final resultBytes = Uint8List.fromList(
        outputData.asTypedList(outputSize),
      );

      // Free the native-allocated buffer
      NativeBindings.instance.freeBuffer(outputData);

      return resultBytes;
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputDataPtr);
      calloc.free(outputSizePtr);
    }
  }

  // ============================================================================
  // PNG resize (full native pipeline)
  // ============================================================================

  /// Resize PNG image bytes using bicubic interpolation
  ///
  /// Entire pipeline (decode -> resize -> encode) runs in native C code.
  /// Preserves alpha channel if present.
  /// This is synchronous but very fast due to native performance.
  ///
  /// [pngBytes] - PNG encoded image data
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [filter] - Bicubic filter type (default: Catmull-Rom)
  /// [edgeMode] - How to handle pixels outside image bounds (default: clamp)
  /// [crop] - Crop factor (0.0-1.0), 1.0 = no crop, 0.5 = 50%
  /// [cropAnchor] - Position to anchor the crop (default: center)
  /// [cropAspectRatio] - Aspect ratio mode for crop (default: square)
  /// [aspectRatioWidth] - Custom aspect ratio width (only used with CropAspectRatio.custom)
  /// [aspectRatioHeight] - Custom aspect ratio height (only used with CropAspectRatio.custom)
  /// [compressionLevel] - PNG compression level (0-9, default 6, 0=none, 9=max)
  ///
  /// Returns resized PNG encoded data
  static Uint8List resizePng({
    required Uint8List pngBytes,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
    int compressionLevel = 6,
  }) {
    final inputPtr = calloc<Uint8>(pngBytes.length);
    final outputDataPtr = calloc<Pointer<Uint8>>();
    final outputSizePtr = calloc<Int32>();

    try {
      inputPtr.asTypedList(pngBytes.length).setAll(0, pngBytes);

      final result = NativeBindings.instance.bicubicResizePng(
        inputPtr,
        pngBytes.length,
        outputWidth,
        outputHeight,
        filter.value,
        edgeMode.value,
        crop,
        cropAnchor.value,
        cropAspectRatio.value,
        aspectRatioWidth,
        aspectRatioHeight,
        compressionLevel,
        outputDataPtr,
        outputSizePtr,
      );

      if (result != 0) {
        throw Exception('Native PNG resize failed with code: $result');
      }

      final outputData = outputDataPtr.value;
      final outputSize = outputSizePtr.value;

      // Copy data before freeing native buffer
      final resultBytes = Uint8List.fromList(
        outputData.asTypedList(outputSize),
      );

      // Free the native-allocated buffer
      NativeBindings.instance.freeBuffer(outputData);

      return resultBytes;
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputDataPtr);
      calloc.free(outputSizePtr);
    }
  }

  // ============================================================================
  // Format detection
  // ============================================================================

  /// Detect the image format from raw bytes.
  ///
  /// Returns the detected [ImageFormat] or `null` if the format is not supported.
  ///
  /// Supported formats: JPEG, PNG
  /// Unsupported formats: HEIC, WebP, GIF, BMP, TIFF, etc.
  ///
  /// [bytes] - Raw image data
  static ImageFormat? detectFormat(Uint8List bytes) {
    if (bytes.length < 4) return null;

    // JPEG: starts with FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return ImageFormat.jpeg;
    }

    // PNG: starts with 89 50 4E 47 (PNG magic number)
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ImageFormat.png;
    }

    return null;
  }

  // ============================================================================
  // Generic resize (auto-detect format)
  // ============================================================================

  /// Resize image bytes with automatic format detection.
  ///
  /// This method automatically detects whether the input is JPEG or PNG
  /// and calls the appropriate resize method.
  ///
  /// Throws [UnsupportedImageFormatException] if the format is not supported.
  ///
  /// [bytes] - Image data (JPEG or PNG)
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [quality] - JPEG output quality (1-100, default 95). Ignored for PNG.
  /// [compressionLevel] - PNG compression level (0-9, default 6). Ignored for JPEG.
  /// [filter] - Bicubic filter type (default: Catmull-Rom)
  /// [edgeMode] - How to handle pixels outside image bounds (default: clamp)
  /// [crop] - Crop factor (0.0-1.0), 1.0 = no crop, 0.5 = 50%
  /// [cropAnchor] - Position to anchor the crop (default: center)
  /// [cropAspectRatio] - Aspect ratio mode for crop (default: square)
  /// [aspectRatioWidth] - Custom aspect ratio width (only used with CropAspectRatio.custom)
  /// [aspectRatioHeight] - Custom aspect ratio height (only used with CropAspectRatio.custom)
  /// [applyExifOrientation] - Whether to apply EXIF orientation for JPEG (default: true)
  ///
  /// Returns resized image data in the same format as input
  static Uint8List resize({
    required Uint8List bytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
    int compressionLevel = 6,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
    bool applyExifOrientation = true,
  }) {
    final format = detectFormat(bytes);

    if (format == null) {
      throw UnsupportedImageFormatException(bytes: bytes);
    }

    switch (format) {
      case ImageFormat.jpeg:
        return resizeJpeg(
          jpegBytes: bytes,
          outputWidth: outputWidth,
          outputHeight: outputHeight,
          quality: quality,
          filter: filter,
          edgeMode: edgeMode,
          crop: crop,
          cropAnchor: cropAnchor,
          cropAspectRatio: cropAspectRatio,
          aspectRatioWidth: aspectRatioWidth,
          aspectRatioHeight: aspectRatioHeight,
          applyExifOrientation: applyExifOrientation,
        );
      case ImageFormat.png:
        return resizePng(
          pngBytes: bytes,
          outputWidth: outputWidth,
          outputHeight: outputHeight,
          filter: filter,
          edgeMode: edgeMode,
          crop: crop,
          cropAnchor: cropAnchor,
          cropAspectRatio: cropAspectRatio,
          aspectRatioWidth: aspectRatioWidth,
          aspectRatioHeight: aspectRatioHeight,
          compressionLevel: compressionLevel,
        );
    }
  }
}
