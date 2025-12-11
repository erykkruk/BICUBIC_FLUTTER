import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;

import 'native_bindings.dart';
import 'resize_isolate.dart';

class BicubicResizer {
  /// Resize raw RGB bytes using bicubic interpolation
  ///
  /// [input] - Raw RGB pixel data (3 bytes per pixel)
  /// [inputWidth] - Width of input image in pixels
  /// [inputHeight] - Height of input image in pixels
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  ///
  /// Returns resized RGB pixel data
  static Uint8List resizeRgb({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
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
  ///
  /// Returns resized RGBA pixel data
  static Uint8List resizeRgba({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
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

  /// Resize JPEG image bytes using bicubic interpolation
  ///
  /// [jpegBytes] - JPEG encoded image data
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  /// [quality] - JPEG output quality (0-100, default 95)
  ///
  /// Returns resized JPEG encoded data
  static Future<Uint8List> resizeJpeg({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
  }) async {
    return ResizeIsolate.resizeJpeg(
      jpegBytes: jpegBytes,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      quality: quality,
    );
  }

  /// Resize PNG image bytes using bicubic interpolation
  ///
  /// [pngBytes] - PNG encoded image data
  /// [outputWidth] - Desired output width
  /// [outputHeight] - Desired output height
  ///
  /// Returns resized PNG encoded data
  static Future<Uint8List> resizePng({
    required Uint8List pngBytes,
    required int outputWidth,
    required int outputHeight,
  }) async {
    return ResizeIsolate.resizePng(
      pngBytes: pngBytes,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
    );
  }

  /// Synchronous version of resizeJpeg (blocks UI thread - use with caution)
  static Uint8List resizeJpegSync({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
  }) {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) {
      throw Exception('Failed to decode JPEG');
    }

    final rgbBytes = _imageToRgb(decoded);
    final resizedRgb = resizeRgb(
      input: rgbBytes,
      inputWidth: decoded.width,
      inputHeight: decoded.height,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
    );

    final resizedImage = img.Image(
      width: outputWidth,
      height: outputHeight,
      numChannels: 3,
    );
    _rgbToImage(resizedRgb, resizedImage);

    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
  }

  /// Synchronous version of resizePng (blocks UI thread - use with caution)
  static Uint8List resizePngSync({
    required Uint8List pngBytes,
    required int outputWidth,
    required int outputHeight,
  }) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw Exception('Failed to decode PNG');
    }

    final hasAlpha = decoded.numChannels == 4;

    if (hasAlpha) {
      final rgbaBytes = _imageToRgba(decoded);
      final resizedRgba = resizeRgba(
        input: rgbaBytes,
        inputWidth: decoded.width,
        inputHeight: decoded.height,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
      );

      final resizedImage = img.Image(
        width: outputWidth,
        height: outputHeight,
        numChannels: 4,
      );
      _rgbaToImage(resizedRgba, resizedImage);

      return Uint8List.fromList(img.encodePng(resizedImage));
    } else {
      final rgbBytes = _imageToRgb(decoded);
      final resizedRgb = resizeRgb(
        input: rgbBytes,
        inputWidth: decoded.width,
        inputHeight: decoded.height,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
      );

      final resizedImage = img.Image(
        width: outputWidth,
        height: outputHeight,
        numChannels: 3,
      );
      _rgbToImage(resizedRgb, resizedImage);

      return Uint8List.fromList(img.encodePng(resizedImage));
    }
  }

  /// Convert img.Image to raw RGB bytes
  static Uint8List _imageToRgb(img.Image image) {
    final bytes = Uint8List(image.width * image.height * 3);
    var i = 0;
    for (final pixel in image) {
      bytes[i++] = pixel.r.toInt();
      bytes[i++] = pixel.g.toInt();
      bytes[i++] = pixel.b.toInt();
    }
    return bytes;
  }

  /// Convert img.Image to raw RGBA bytes
  static Uint8List _imageToRgba(img.Image image) {
    final bytes = Uint8List(image.width * image.height * 4);
    var i = 0;
    for (final pixel in image) {
      bytes[i++] = pixel.r.toInt();
      bytes[i++] = pixel.g.toInt();
      bytes[i++] = pixel.b.toInt();
      bytes[i++] = pixel.a.toInt();
    }
    return bytes;
  }

  /// Convert raw RGB bytes to img.Image
  static void _rgbToImage(Uint8List rgb, img.Image image) {
    var i = 0;
    for (final pixel in image) {
      pixel.r = rgb[i++];
      pixel.g = rgb[i++];
      pixel.b = rgb[i++];
    }
  }

  /// Convert raw RGBA bytes to img.Image
  static void _rgbaToImage(Uint8List rgba, img.Image image) {
    var i = 0;
    for (final pixel in image) {
      pixel.r = rgba[i++];
      pixel.g = rgba[i++];
      pixel.b = rgba[i++];
      pixel.a = rgba[i++];
    }
  }
}
