import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'bicubic_resizer.dart';

class ResizeIsolate {
  /// Resize JPEG in isolate to avoid blocking UI thread
  static Future<Uint8List> resizeJpeg({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
  }) async {
    return compute(
      _resizeJpegInIsolate,
      _JpegResizeParams(
        jpegBytes: jpegBytes,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
        quality: quality,
      ),
    );
  }

  /// Resize PNG in isolate to avoid blocking UI thread
  static Future<Uint8List> resizePng({
    required Uint8List pngBytes,
    required int outputWidth,
    required int outputHeight,
  }) async {
    return compute(
      _resizePngInIsolate,
      _PngResizeParams(
        pngBytes: pngBytes,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
      ),
    );
  }
}

class _JpegResizeParams {
  final Uint8List jpegBytes;
  final int outputWidth;
  final int outputHeight;
  final int quality;

  _JpegResizeParams({
    required this.jpegBytes,
    required this.outputWidth,
    required this.outputHeight,
    required this.quality,
  });
}

class _PngResizeParams {
  final Uint8List pngBytes;
  final int outputWidth;
  final int outputHeight;

  _PngResizeParams({
    required this.pngBytes,
    required this.outputWidth,
    required this.outputHeight,
  });
}

Uint8List _resizeJpegInIsolate(_JpegResizeParams params) {
  final decoded = img.decodeJpg(params.jpegBytes);
  if (decoded == null) {
    throw Exception('Failed to decode JPEG');
  }

  final rgbBytes = _imageToRgb(decoded);
  final resizedRgb = BicubicResizer.resizeRgb(
    input: rgbBytes,
    inputWidth: decoded.width,
    inputHeight: decoded.height,
    outputWidth: params.outputWidth,
    outputHeight: params.outputHeight,
  );

  final resizedImage = img.Image(
    width: params.outputWidth,
    height: params.outputHeight,
    numChannels: 3,
  );
  _rgbToImage(resizedRgb, resizedImage);

  return Uint8List.fromList(img.encodeJpg(resizedImage, quality: params.quality));
}

Uint8List _resizePngInIsolate(_PngResizeParams params) {
  final decoded = img.decodePng(params.pngBytes);
  if (decoded == null) {
    throw Exception('Failed to decode PNG');
  }

  final hasAlpha = decoded.numChannels == 4;

  if (hasAlpha) {
    final rgbaBytes = _imageToRgba(decoded);
    final resizedRgba = BicubicResizer.resizeRgba(
      input: rgbaBytes,
      inputWidth: decoded.width,
      inputHeight: decoded.height,
      outputWidth: params.outputWidth,
      outputHeight: params.outputHeight,
    );

    final resizedImage = img.Image(
      width: params.outputWidth,
      height: params.outputHeight,
      numChannels: 4,
    );
    _rgbaToImage(resizedRgba, resizedImage);

    return Uint8List.fromList(img.encodePng(resizedImage));
  } else {
    final rgbBytes = _imageToRgb(decoded);
    final resizedRgb = BicubicResizer.resizeRgb(
      input: rgbBytes,
      inputWidth: decoded.width,
      inputHeight: decoded.height,
      outputWidth: params.outputWidth,
      outputHeight: params.outputHeight,
    );

    final resizedImage = img.Image(
      width: params.outputWidth,
      height: params.outputHeight,
      numChannels: 3,
    );
    _rgbToImage(resizedRgb, resizedImage);

    return Uint8List.fromList(img.encodePng(resizedImage));
  }
}

Uint8List _imageToRgb(img.Image image) {
  final bytes = Uint8List(image.width * image.height * 3);
  var i = 0;
  for (final pixel in image) {
    bytes[i++] = pixel.r.toInt();
    bytes[i++] = pixel.g.toInt();
    bytes[i++] = pixel.b.toInt();
  }
  return bytes;
}

Uint8List _imageToRgba(img.Image image) {
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

void _rgbToImage(Uint8List rgb, img.Image image) {
  var i = 0;
  for (final pixel in image) {
    pixel.r = rgb[i++];
    pixel.g = rgb[i++];
    pixel.b = rgb[i++];
  }
}

void _rgbaToImage(Uint8List rgba, img.Image image) {
  var i = 0;
  for (final pixel in image) {
    pixel.r = rgba[i++];
    pixel.g = rgba[i++];
    pixel.b = rgba[i++];
    pixel.a = rgba[i++];
  }
}
