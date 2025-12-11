import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'native_bindings.dart';

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
  ///
  /// Returns resized RGB pixel data
  static Uint8List resizeRgb({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
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
  ///
  /// Returns resized RGBA pixel data
  static Uint8List resizeRgba({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
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
  ///
  /// Returns resized JPEG encoded data
  static Uint8List resizeJpeg({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
    BicubicFilter filter = BicubicFilter.catmullRom,
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
  ///
  /// Returns resized PNG encoded data
  static Uint8List resizePng({
    required Uint8List pngBytes,
    required int outputWidth,
    required int outputHeight,
    BicubicFilter filter = BicubicFilter.catmullRom,
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
}
