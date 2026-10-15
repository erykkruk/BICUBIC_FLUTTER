import 'dart:typed_data';

import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================================
  // Dimension & crop calculation tests (no native library needed)
  // ============================================================================

  group('BicubicResizer - dimension calculations', () {
    test('RGB resize produces correct output size', () {
      const inputWidth = 100;
      const inputHeight = 100;
      const outputWidth = 50;
      const outputHeight = 50;

      const inputSize = inputWidth * inputHeight * 3;
      const expectedOutputSize = outputWidth * outputHeight * 3;

      expect(inputSize, equals(30000));
      expect(expectedOutputSize, equals(7500));
    });

    test('RGBA resize produces correct output size', () {
      const inputWidth = 100;
      const inputHeight = 100;
      const outputWidth = 50;
      const outputHeight = 50;

      const inputSize = inputWidth * inputHeight * 4;
      const expectedOutputSize = outputWidth * outputHeight * 4;

      expect(inputSize, equals(40000));
      expect(expectedOutputSize, equals(10000));
    });

    test('upscale dimensions are valid', () {
      const inputWidth = 50;
      const inputHeight = 50;
      const outputWidth = 200;
      const outputHeight = 200;

      expect(outputWidth > inputWidth, isTrue);
      expect(outputHeight > inputHeight, isTrue);

      const outputSize = outputWidth * outputHeight * 3;
      expect(outputSize, equals(120000));
    });

    test('non-uniform scaling dimensions', () {
      const outputWidth = 224;
      const outputHeight = 112;

      const outputPixels = outputWidth * outputHeight;
      expect(outputPixels, equals(25088));
    });

    test('1x1 minimum output dimensions', () {
      const outputWidth = 1;
      const outputHeight = 1;

      expect(outputWidth * outputHeight * 3, equals(3));
      expect(outputWidth * outputHeight * 4, equals(4));
    });
  });

  group('BicubicResizer - crop calculations', () {
    test('center crop 80%', () {
      const srcWidth = 100;
      const srcHeight = 100;
      const crop = 0.8;

      final cropWidth = (srcWidth * crop).toInt();
      final cropHeight = (srcHeight * crop).toInt();
      final cropX = (srcWidth - cropWidth) ~/ 2;
      final cropY = (srcHeight - cropHeight) ~/ 2;

      expect(cropWidth, equals(80));
      expect(cropHeight, equals(80));
      expect(cropX, equals(10));
      expect(cropY, equals(10));
    });

    test('center crop 50% on non-square image', () {
      const srcWidth = 200;
      const srcHeight = 100;
      const crop = 0.5;

      final cropWidth = (srcWidth * crop).toInt();
      final cropHeight = (srcHeight * crop).toInt();
      final cropX = (srcWidth - cropWidth) ~/ 2;
      final cropY = (srcHeight - cropHeight) ~/ 2;

      expect(cropWidth, equals(100));
      expect(cropHeight, equals(50));
      expect(cropX, equals(50));
      expect(cropY, equals(25));
    });

    test('crop = 1.0 produces full image', () {
      const srcWidth = 300;
      const srcHeight = 200;
      const crop = 1.0;

      final cropWidth = (srcWidth * crop).toInt();
      final cropHeight = (srcHeight * crop).toInt();

      expect(cropWidth, equals(srcWidth));
      expect(cropHeight, equals(srcHeight));
    });

    test('crop value clamping', () {
      double clampCrop(double crop) {
        if (crop < 0.01) return 0.01;
        if (crop > 1.0) return 1.0;
        return crop;
      }

      expect(clampCrop(1.0), equals(1.0));
      expect(clampCrop(0.5), equals(0.5));
      expect(clampCrop(0.01), equals(0.01));
      expect(clampCrop(0.0), equals(0.01));
      expect(clampCrop(-0.5), equals(0.01));
      expect(clampCrop(1.5), equals(1.0));
      expect(clampCrop(100.0), equals(1.0));
    });
  });

  // ============================================================================
  // Input validation tests (throws before FFI call)
  // ============================================================================

  group('BicubicResizer - resizeRgb input validation', () {
    test('throws ArgumentError for input size mismatch', () {
      final wrongInput = Uint8List(100);

      expect(
        () => BicubicResizer.resizeRgb(
          input: wrongInput,
          inputWidth: 10,
          inputHeight: 10,
          outputWidth: 5,
          outputHeight: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError with descriptive message', () {
      final wrongInput = Uint8List(50);

      expect(
        () => BicubicResizer.resizeRgb(
          input: wrongInput,
          inputWidth: 10,
          inputHeight: 10,
          outputWidth: 5,
          outputHeight: 5,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('expected 300 bytes, got 50'),
          ),
        ),
      );
    });

    test('correct input size passes validation (fails at native level)', () {
      const w = 10;
      const h = 10;
      final correctInput = Uint8List(w * h * 3);

      // Correct size passes our validation but fails at native library load.
      // The FFI ArgumentError message contains "lookup symbol", NOT "Input size mismatch".
      expect(
        () => BicubicResizer.resizeRgb(
          input: correctInput,
          inputWidth: w,
          inputHeight: h,
          outputWidth: 5,
          outputHeight: 5,
        ),
        throwsA(
          isNot(
            isA<ArgumentError>().having(
              (e) => e.message?.toString() ?? '',
              'message',
              contains('Input size mismatch'),
            ),
          ),
        ),
      );
    });
  });

  group('BicubicResizer - resizeRgba input validation', () {
    test('throws ArgumentError for input size mismatch', () {
      final wrongInput = Uint8List(100);

      expect(
        () => BicubicResizer.resizeRgba(
          input: wrongInput,
          inputWidth: 10,
          inputHeight: 10,
          outputWidth: 5,
          outputHeight: 5,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError with descriptive message', () {
      final wrongInput = Uint8List(50);

      expect(
        () => BicubicResizer.resizeRgba(
          input: wrongInput,
          inputWidth: 10,
          inputHeight: 10,
          outputWidth: 5,
          outputHeight: 5,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('expected 400 bytes, got 50'),
          ),
        ),
      );
    });
  });

  // ============================================================================
  // resizeForModel custom normalization std validation
  // (throws ArgumentError BEFORE any native call)
  // ============================================================================

  group('BicubicResizer - resizeForModel std validation', () {
    // Dummy JPEG bytes (valid header but corrupt body - validation happens first)
    final dummyJpeg = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      0x00,
      0x10,
      0x4A,
      0x46,
    ]);

    test('throws ArgumentError when stdR is zero with custom normalization',
        () {
      expect(
        () => BicubicResizer.resizeForModel(
          bytes: dummyJpeg,
          outputWidth: 224,
          outputHeight: 224,
          normalization: NormalizationType.custom,
          stdR: 0.0,
          stdG: 1.0,
          stdB: 1.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.name,
            'name',
            equals('stdR'),
          ),
        ),
      );
    });

    test('throws ArgumentError when stdG is zero with custom normalization',
        () {
      expect(
        () => BicubicResizer.resizeForModel(
          bytes: dummyJpeg,
          outputWidth: 224,
          outputHeight: 224,
          normalization: NormalizationType.custom,
          stdR: 1.0,
          stdG: 0.0,
          stdB: 1.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.name,
            'name',
            equals('stdG'),
          ),
        ),
      );
    });

    test('throws ArgumentError when stdB is zero with custom normalization',
        () {
      expect(
        () => BicubicResizer.resizeForModel(
          bytes: dummyJpeg,
          outputWidth: 224,
          outputHeight: 224,
          normalization: NormalizationType.custom,
          stdR: 1.0,
          stdG: 1.0,
          stdB: 0.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.name,
            'name',
            equals('stdB'),
          ),
        ),
      );
    });

    test('throws ArgumentError when all std are zero', () {
      expect(
        () => BicubicResizer.resizeForModel(
          bytes: dummyJpeg,
          outputWidth: 224,
          outputHeight: 224,
          normalization: NormalizationType.custom,
          stdR: 0.0,
          stdG: 0.0,
          stdB: 0.0,
        ),
        throwsArgumentError,
      );
    });

    test(
        'does NOT throw our ArgumentError for non-custom normalization with zero std',
        () {
      // With non-custom normalization, std values are ignored.
      // The call will fail at native level but NOT with our std validation error.
      for (final norm in [
        NormalizationType.none,
        NormalizationType.simple,
        NormalizationType.centered,
        NormalizationType.imageNet,
      ]) {
        expect(
          () => BicubicResizer.resizeForModel(
            bytes: dummyJpeg,
            outputWidth: 224,
            outputHeight: 224,
            normalization: norm,
            stdR: 0.0,
            stdG: 0.0,
            stdB: 0.0,
          ),
          // Should NOT throw ArgumentError about 'stdR/stdG/stdB'
          throwsA(
            isNot(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                anyOf(equals('stdR'), equals('stdG'), equals('stdB')),
              ),
            ),
          ),
          reason: 'Should not validate std for $norm normalization',
        );
      }
    });

    test('does NOT throw std validation error for negative std values', () {
      // Negative std is mathematically valid (just inverts the normalization)
      expect(
        () => BicubicResizer.resizeForModel(
          bytes: dummyJpeg,
          outputWidth: 224,
          outputHeight: 224,
          normalization: NormalizationType.custom,
          stdR: -0.229,
          stdG: -0.224,
          stdB: -0.225,
        ),
        // Should NOT throw ArgumentError about std values
        throwsA(
          isNot(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              anyOf(equals('stdR'), equals('stdG'), equals('stdB')),
            ),
          ),
        ),
      );
    });
  });

  // ============================================================================
  // resize() format validation (throws before FFI call)
  // ============================================================================

  group('BicubicResizer - resize format validation', () {
    test('throws UnsupportedImageFormatException for empty bytes', () {
      expect(
        () => BicubicResizer.resize(
          bytes: Uint8List(0),
          outputWidth: 100,
          outputHeight: 100,
        ),
        throwsA(isA<UnsupportedImageFormatException>()),
      );
    });

    test('throws UnsupportedImageFormatException for unknown format', () {
      final unknown = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);

      expect(
        () => BicubicResizer.resize(
          bytes: unknown,
          outputWidth: 100,
          outputHeight: 100,
        ),
        throwsA(isA<UnsupportedImageFormatException>()),
      );
    });

    test('throws UnsupportedImageFormatException for GIF bytes', () {
      final gif = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);

      expect(
        () => BicubicResizer.resize(
          bytes: gif,
          outputWidth: 100,
          outputHeight: 100,
        ),
        throwsA(isA<UnsupportedImageFormatException>()),
      );
    });

    test('throws UnsupportedImageFormatException for too-short bytes', () {
      final tooShort = Uint8List.fromList([0xFF, 0xD8]);

      expect(
        () => BicubicResizer.resize(
          bytes: tooShort,
          outputWidth: 100,
          outputHeight: 100,
        ),
        throwsA(isA<UnsupportedImageFormatException>()),
      );
    });
  });

  // ============================================================================
  // BicubicNativeError enum
  // ============================================================================

  group('BicubicNativeError', () {
    test('has exactly 6 error codes', () {
      expect(BicubicNativeError.values.length, equals(6));
    });

    test('all error codes have correct values', () {
      expect(BicubicNativeError.nullInput.code, equals(-1));
      expect(BicubicNativeError.invalidDims.code, equals(-2));
      expect(BicubicNativeError.decodeFailed.code, equals(-3));
      expect(BicubicNativeError.allocFailed.code, equals(-4));
      expect(BicubicNativeError.encodeFailed.code, equals(-5));
      expect(BicubicNativeError.formatUnknown.code, equals(-6));
    });

    test('all codes are unique', () {
      final codes = BicubicNativeError.values.map((e) => e.code).toSet();
      expect(codes.length, equals(BicubicNativeError.values.length));
    });

    test('all codes are negative', () {
      for (final error in BicubicNativeError.values) {
        expect(error.code, isNegative);
      }
    });

    test('all error codes have non-empty descriptions', () {
      for (final error in BicubicNativeError.values) {
        expect(error.description, isNotEmpty);
      }
    });

    test('invalidDims description covers oversized buffers', () {
      // Arrange
      const error = BicubicNativeError.invalidDims;

      // Act
      final exception = BicubicResizeException(error.code);

      // Assert
      expect(error.description, contains('too large'));
      expect(exception.toString(), contains('too large'));
    });

    test('fromCode returns correct enum for all known codes', () {
      expect(
        BicubicNativeError.fromCode(-1),
        equals(BicubicNativeError.nullInput),
      );
      expect(
        BicubicNativeError.fromCode(-2),
        equals(BicubicNativeError.invalidDims),
      );
      expect(
        BicubicNativeError.fromCode(-3),
        equals(BicubicNativeError.decodeFailed),
      );
      expect(
        BicubicNativeError.fromCode(-4),
        equals(BicubicNativeError.allocFailed),
      );
      expect(
        BicubicNativeError.fromCode(-5),
        equals(BicubicNativeError.encodeFailed),
      );
      expect(
        BicubicNativeError.fromCode(-6),
        equals(BicubicNativeError.formatUnknown),
      );
    });

    test('fromCode returns null for success code 0', () {
      expect(BicubicNativeError.fromCode(0), isNull);
    });

    test('fromCode returns null for positive codes', () {
      expect(BicubicNativeError.fromCode(1), isNull);
      expect(BicubicNativeError.fromCode(42), isNull);
    });

    test('fromCode returns null for unknown negative codes', () {
      expect(BicubicNativeError.fromCode(-7), isNull);
      expect(BicubicNativeError.fromCode(-99), isNull);
      expect(BicubicNativeError.fromCode(-1000), isNull);
    });

    test('fromCode round-trips correctly for all values', () {
      for (final error in BicubicNativeError.values) {
        expect(BicubicNativeError.fromCode(error.code), equals(error));
      }
    });
  });

  // ============================================================================
  // BicubicResizeException
  // ============================================================================

  group('BicubicResizeException', () {
    test('creates with known error code -1 (nullInput)', () {
      final exception = BicubicResizeException(-1);

      expect(exception.nativeCode, equals(-1));
      expect(exception.error, equals(BicubicNativeError.nullInput));
      expect(
          exception.message, equals(BicubicNativeError.nullInput.description));
    });

    test('creates with known error code -2 (invalidDims)', () {
      final exception = BicubicResizeException(-2);

      expect(exception.nativeCode, equals(-2));
      expect(exception.error, equals(BicubicNativeError.invalidDims));
      expect(exception.message, contains('dimensions'));
    });

    test('creates with known error code -3 (decodeFailed)', () {
      final exception = BicubicResizeException(-3);

      expect(exception.nativeCode, equals(-3));
      expect(exception.error, equals(BicubicNativeError.decodeFailed));
      expect(exception.message, contains('decoding'));
    });

    test('creates with known error code -4 (allocFailed)', () {
      final exception = BicubicResizeException(-4);

      expect(exception.nativeCode, equals(-4));
      expect(exception.error, equals(BicubicNativeError.allocFailed));
      expect(exception.message, contains('allocation'));
    });

    test('creates with known error code -5 (encodeFailed)', () {
      final exception = BicubicResizeException(-5);

      expect(exception.nativeCode, equals(-5));
      expect(exception.error, equals(BicubicNativeError.encodeFailed));
      expect(exception.message, contains('encoding'));
    });

    test('creates with unknown error code', () {
      final exception = BicubicResizeException(-99);

      expect(exception.nativeCode, equals(-99));
      expect(exception.error, isNull);
      expect(exception.message, contains('Unknown'));
      expect(exception.message, contains('-99'));
    });

    test('creates with unknown positive error code', () {
      final exception = BicubicResizeException(42);

      expect(exception.nativeCode, equals(42));
      expect(exception.error, isNull);
      expect(exception.message, contains('Unknown'));
    });

    test('toString format includes class name and code', () {
      final exception = BicubicResizeException(-3);
      final str = exception.toString();

      expect(str, startsWith('BicubicResizeException:'));
      expect(str, contains('-3'));
    });

    test('toString for unknown code includes code number', () {
      final exception = BicubicResizeException(-42);
      final str = exception.toString();

      expect(str, contains('-42'));
    });

    test('implements Exception interface', () {
      final exception = BicubicResizeException(-1);
      expect(exception, isA<Exception>());
    });

    test('can be caught as Exception (backward compatibility)', () {
      Object? caught;
      try {
        throw BicubicResizeException(-3);
      } on Exception catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught, isA<BicubicResizeException>());
    });

    test('can be caught specifically as BicubicResizeException', () {
      late BicubicResizeException caught;
      try {
        throw BicubicResizeException(-5);
      } on BicubicResizeException catch (e) {
        caught = e;
      }

      expect(caught.nativeCode, equals(-5));
      expect(caught.error, equals(BicubicNativeError.encodeFailed));
    });

    test('each known code produces a distinct message', () {
      final messages = <String>{};
      for (int code = -1; code >= -6; code--) {
        final exception = BicubicResizeException(code);
        messages.add(exception.message);
      }
      expect(messages.length, equals(6));
    });
  });

  // ============================================================================
  // UnsupportedImageFormatException
  // ============================================================================

  group('UnsupportedImageFormatException', () {
    test('creates with default message', () {
      final bytes = Uint8List.fromList([0x00, 0x01]);
      final exception = UnsupportedImageFormatException(bytes: bytes);

      expect(exception.bytes, equals(bytes));
      expect(exception.message, contains('Unsupported'));
      expect(exception.message, contains('JPEG'));
      expect(exception.message, contains('PNG'));
    });

    test('creates with custom message', () {
      final bytes = Uint8List(0);
      final exception = UnsupportedImageFormatException(
        bytes: bytes,
        message: 'Custom error',
      );

      expect(exception.message, equals('Custom error'));
    });

    test('toString includes class name and message', () {
      final bytes = Uint8List(0);
      final exception = UnsupportedImageFormatException(bytes: bytes);
      final str = exception.toString();

      expect(str, startsWith('UnsupportedImageFormatException:'));
      expect(str, contains('Unsupported'));
    });

    test('implements Exception interface', () {
      final exception = UnsupportedImageFormatException(bytes: Uint8List(0));
      expect(exception, isA<Exception>());
    });

    test('can be caught as Exception', () {
      Object? caught;
      try {
        throw UnsupportedImageFormatException(bytes: Uint8List(0));
      } on Exception catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught, isA<UnsupportedImageFormatException>());
    });

    test('preserves original bytes reference', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
      final exception = UnsupportedImageFormatException(bytes: bytes);

      expect(identical(exception.bytes, bytes), isTrue);
    });
  });

  // ============================================================================
  // Format detection
  // ============================================================================

  group('BicubicResizer.detectFormat', () {
    test('detects JPEG from FF D8 FF magic bytes', () {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
      expect(BicubicResizer.detectFormat(jpegBytes), equals(ImageFormat.jpeg));
    });

    test('detects JPEG with different APP marker (FF D8 FF E1)', () {
      final jpegExif = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x00]);
      expect(BicubicResizer.detectFormat(jpegExif), equals(ImageFormat.jpeg));
    });

    test('detects PNG from 89 50 4E 47 magic bytes', () {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D]);
      expect(BicubicResizer.detectFormat(pngBytes), equals(ImageFormat.png));
    });

    test('detects format from exactly 4 bytes', () {
      final minJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final minPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

      expect(BicubicResizer.detectFormat(minJpeg), equals(ImageFormat.jpeg));
      expect(BicubicResizer.detectFormat(minPng), equals(ImageFormat.png));
    });

    test('returns null for empty bytes', () {
      expect(BicubicResizer.detectFormat(Uint8List(0)), isNull);
    });

    test('returns null for 1 byte', () {
      expect(BicubicResizer.detectFormat(Uint8List.fromList([0xFF])), isNull);
    });

    test('returns null for 2 bytes', () {
      expect(
        BicubicResizer.detectFormat(Uint8List.fromList([0xFF, 0xD8])),
        isNull,
      );
    });

    test('returns null for 3 bytes (partial JPEG header)', () {
      expect(
        BicubicResizer.detectFormat(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
        isNull,
      );
    });

    test('returns null for all-zero bytes', () {
      expect(BicubicResizer.detectFormat(Uint8List(10)), isNull);
    });

    test('returns null for GIF87a', () {
      // GIF87a = 47 49 46 38 37 61
      final gif87 = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]);
      expect(BicubicResizer.detectFormat(gif87), isNull);
    });

    test('returns null for GIF89a', () {
      final gif89 = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
      expect(BicubicResizer.detectFormat(gif89), isNull);
    });

    test('returns null for BMP', () {
      final bmp = Uint8List.fromList([0x42, 0x4D, 0x00, 0x00, 0x00]);
      expect(BicubicResizer.detectFormat(bmp), isNull);
    });

    test('returns null for WebP', () {
      final webp = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);
      expect(BicubicResizer.detectFormat(webp), isNull);
    });

    test('returns null for TIFF (little-endian)', () {
      final tiffLE = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]);
      expect(BicubicResizer.detectFormat(tiffLE), isNull);
    });

    test('returns null for TIFF (big-endian)', () {
      final tiffBE = Uint8List.fromList([0x4D, 0x4D, 0x00, 0x2A]);
      expect(BicubicResizer.detectFormat(tiffBE), isNull);
    });

    test('returns null for random bytes', () {
      final random = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      expect(BicubicResizer.detectFormat(random), isNull);
    });

    test('JPEG detection requires FF D8 FF prefix', () {
      // FF D8 but wrong third byte
      final almostJpeg = Uint8List.fromList([0xFF, 0xD8, 0x00, 0x00]);
      expect(BicubicResizer.detectFormat(almostJpeg), isNull);
    });

    test('PNG detection requires exact 4-byte prefix', () {
      // 89 50 4E but wrong 4th byte
      final almostPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x00]);
      expect(BicubicResizer.detectFormat(almostPng), isNull);
    });
  });

  // ============================================================================
  // Enum value tests
  // ============================================================================

  group('BicubicFilter enum', () {
    test('catmullRom has value 0', () {
      expect(BicubicFilter.catmullRom.value, equals(0));
    });

    test('cubicBSpline has value 1', () {
      expect(BicubicFilter.cubicBSpline.value, equals(1));
    });

    test('mitchell has value 2', () {
      expect(BicubicFilter.mitchell.value, equals(2));
    });

    test('has exactly 3 values', () {
      expect(BicubicFilter.values.length, equals(3));
    });
  });

  group('EdgeMode enum', () {
    test('correct values', () {
      expect(EdgeMode.clamp.value, equals(0));
      expect(EdgeMode.wrap.value, equals(1));
      expect(EdgeMode.reflect.value, equals(2));
      expect(EdgeMode.zero.value, equals(3));
    });

    test('has exactly 4 values', () {
      expect(EdgeMode.values.length, equals(4));
    });
  });

  group('CropAnchor enum', () {
    test('correct values', () {
      expect(CropAnchor.center.value, equals(0));
      expect(CropAnchor.topLeft.value, equals(1));
      expect(CropAnchor.topCenter.value, equals(2));
      expect(CropAnchor.topRight.value, equals(3));
      expect(CropAnchor.centerLeft.value, equals(4));
      expect(CropAnchor.centerRight.value, equals(5));
      expect(CropAnchor.bottomLeft.value, equals(6));
      expect(CropAnchor.bottomCenter.value, equals(7));
      expect(CropAnchor.bottomRight.value, equals(8));
    });

    test('has exactly 9 values', () {
      expect(CropAnchor.values.length, equals(9));
    });

    test('all values are unique', () {
      final values = CropAnchor.values.map((e) => e.value).toSet();
      expect(values.length, equals(CropAnchor.values.length));
    });
  });

  group('CropAspectRatio enum', () {
    test('correct values', () {
      expect(CropAspectRatio.square.value, equals(0));
      expect(CropAspectRatio.original.value, equals(1));
      expect(CropAspectRatio.custom.value, equals(2));
    });

    test('has exactly 3 values', () {
      expect(CropAspectRatio.values.length, equals(3));
    });
  });

  group('NormalizationType enum', () {
    test('has exactly 5 values', () {
      expect(NormalizationType.values.length, equals(5));
    });

    test('contains all expected values', () {
      expect(NormalizationType.values, contains(NormalizationType.none));
      expect(NormalizationType.values, contains(NormalizationType.simple));
      expect(NormalizationType.values, contains(NormalizationType.centered));
      expect(NormalizationType.values, contains(NormalizationType.imageNet));
      expect(NormalizationType.values, contains(NormalizationType.custom));
    });
  });

  group('ChannelOrder enum', () {
    test('has exactly 2 values', () {
      expect(ChannelOrder.values.length, equals(2));
    });

    test('contains rgb and bgr', () {
      expect(ChannelOrder.values, contains(ChannelOrder.rgb));
      expect(ChannelOrder.values, contains(ChannelOrder.bgr));
    });
  });

  group('TensorLayout enum', () {
    test('has exactly 2 values', () {
      expect(TensorLayout.values.length, equals(2));
    });

    test('contains hwc and chw', () {
      expect(TensorLayout.values, contains(TensorLayout.hwc));
      expect(TensorLayout.values, contains(TensorLayout.chw));
    });
  });

  group('ImageFormat enum', () {
    test('has exactly 2 values', () {
      expect(ImageFormat.values.length, equals(2));
    });

    test('contains jpeg and png', () {
      expect(ImageFormat.values, contains(ImageFormat.jpeg));
      expect(ImageFormat.values, contains(ImageFormat.png));
    });
  });

  // ============================================================================
  // BicubicImageInfo
  // ============================================================================

  group('BicubicImageInfo', () {
    test('creates with all fields', () {
      const info = BicubicImageInfo(
        width: 1920,
        height: 1080,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 1,
      );

      expect(info.width, equals(1920));
      expect(info.height, equals(1080));
      expect(info.channels, equals(3));
      expect(info.format, equals(ImageFormat.jpeg));
      expect(info.exifOrientation, equals(1));
    });

    test('orientedWidth/orientedHeight for normal orientation (1)', () {
      const info = BicubicImageInfo(
        width: 1920,
        height: 1080,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 1,
      );

      expect(info.orientedWidth, equals(1920));
      expect(info.orientedHeight, equals(1080));
    });

    test('orientedWidth/orientedHeight for 90 CW rotation (6)', () {
      const info = BicubicImageInfo(
        width: 1920,
        height: 1080,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 6,
      );

      expect(info.orientedWidth, equals(1080));
      expect(info.orientedHeight, equals(1920));
    });

    test('orientedWidth/orientedHeight for 180 rotation (3)', () {
      const info = BicubicImageInfo(
        width: 1920,
        height: 1080,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 3,
      );

      expect(info.orientedWidth, equals(1920));
      expect(info.orientedHeight, equals(1080));
    });

    test('orientedWidth/orientedHeight for 90 CCW rotation (8)', () {
      const info = BicubicImageInfo(
        width: 1920,
        height: 1080,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 8,
      );

      expect(info.orientedWidth, equals(1080));
      expect(info.orientedHeight, equals(1920));
    });

    test('orientedWidth/orientedHeight for transpose (5)', () {
      const info = BicubicImageInfo(
        width: 800,
        height: 600,
        channels: 3,
        format: ImageFormat.png,
        exifOrientation: 5,
      );

      expect(info.orientedWidth, equals(600));
      expect(info.orientedHeight, equals(800));
    });

    test('orientedWidth/orientedHeight for flip horizontal (2)', () {
      const info = BicubicImageInfo(
        width: 800,
        height: 600,
        channels: 4,
        format: ImageFormat.png,
        exifOrientation: 2,
      );

      expect(info.orientedWidth, equals(800));
      expect(info.orientedHeight, equals(600));
    });

    test('toString contains dimensions and format', () {
      const info = BicubicImageInfo(
        width: 100,
        height: 200,
        channels: 3,
        format: ImageFormat.jpeg,
        exifOrientation: 6,
      );

      final str = info.toString();
      expect(str, contains('100'));
      expect(str, contains('200'));
      expect(str, contains('jpeg'));
      expect(str, contains('6'));
    });
  });

  // ============================================================================
  // BicubicNativeError - formatUnknown
  // ============================================================================

  group('BicubicNativeError - formatUnknown', () {
    test('has exactly 6 error codes', () {
      expect(BicubicNativeError.values.length, equals(6));
    });

    test('formatUnknown has code -6', () {
      expect(BicubicNativeError.formatUnknown.code, equals(-6));
    });

    test('fromCode returns formatUnknown for -6', () {
      expect(
        BicubicNativeError.fromCode(-6),
        equals(BicubicNativeError.formatUnknown),
      );
    });
  });

  // ============================================================================
  // convertFormat validation
  // ============================================================================

  group('BicubicResizer - convertFormat validation', () {
    test('throws UnsupportedImageFormatException for unknown format', () {
      final unknown = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);

      expect(
        () => BicubicResizer.convertFormat(
          bytes: unknown,
          targetFormat: ImageFormat.jpeg,
        ),
        throwsA(isA<UnsupportedImageFormatException>()),
      );
    });

    test('returns same bytes when source matches target (JPEG -> JPEG)', () {
      final jpegHeader =
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

      final result = BicubicResizer.convertFormat(
        bytes: jpegHeader,
        targetFormat: ImageFormat.jpeg,
      );

      expect(identical(result, jpegHeader), isTrue);
    });

    test('returns same bytes when source matches target (PNG -> PNG)', () {
      final pngHeader =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);

      final result = BicubicResizer.convertFormat(
        bytes: pngHeader,
        targetFormat: ImageFormat.png,
      );

      expect(identical(result, pngHeader), isTrue);
    });
  });

  // ============================================================================
  // Async method existence - new methods
  // ============================================================================

  group('New async method signatures', () {
    test('getImageInfoAsync exists', () {
      expect(BicubicResizer.getImageInfoAsync, isA<Function>());
    });

    test('resizeFileAsync exists', () {
      expect(BicubicResizer.resizeFileAsync, isA<Function>());
    });

    test('resizeFileToFileAsync exists', () {
      expect(BicubicResizer.resizeFileToFileAsync, isA<Function>());
    });

    test('jpegToPngAsync exists', () {
      expect(BicubicResizer.jpegToPngAsync, isA<Function>());
    });

    test('pngToJpegAsync exists', () {
      expect(BicubicResizer.pngToJpegAsync, isA<Function>());
    });

    test('convertFormatAsync exists', () {
      expect(BicubicResizer.convertFormatAsync, isA<Function>());
    });
  });

  // ============================================================================
  // Async method existence
  // ============================================================================

  group('Async method signatures', () {
    test('resizeJpegAsync exists', () {
      expect(BicubicResizer.resizeJpegAsync, isA<Function>());
    });

    test('resizePngAsync exists', () {
      expect(BicubicResizer.resizePngAsync, isA<Function>());
    });

    test('resizeRgbAsync exists', () {
      expect(BicubicResizer.resizeRgbAsync, isA<Function>());
    });

    test('resizeRgbaAsync exists', () {
      expect(BicubicResizer.resizeRgbaAsync, isA<Function>());
    });

    test('resizeAsync exists', () {
      expect(BicubicResizer.resizeAsync, isA<Function>());
    });

    test('resizeForModelAsync exists', () {
      expect(BicubicResizer.resizeForModelAsync, isA<Function>());
    });

    test('resizeToFit exists', () {
      expect(BicubicResizer.resizeToFit, isA<Function>());
    });

    test('computeFitDimensions exists', () {
      expect(BicubicResizer.computeFitDimensions, isA<Function>());
    });
  });

  group('BicubicResizer - computeFitDimensions', () {
    test('landscape image fits width, scales height proportionally', () {
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 4000,
        sourceHeight: 3000,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      expect(target.width, equals(1024));
      expect(target.height, equals(768));
    });

    test('portrait image fits height, scales width proportionally', () {
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 3000,
        sourceHeight: 4000,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      expect(target.width, equals(768));
      expect(target.height, equals(1024));
    });

    test('the limiting dimension is the smaller scale factor', () {
      // 2000x1000 into 800x800: width scale 0.4, height scale 0.8 -> use 0.4.
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 2000,
        sourceHeight: 1000,
        maxWidth: 800,
        maxHeight: 800,
      );

      expect(target.width, equals(800));
      expect(target.height, equals(400));
    });

    test('does not upscale by default when image already fits', () {
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 300,
        sourceHeight: 200,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      expect(target.width, equals(300));
      expect(target.height, equals(200));
    });

    test('upscales when allowUpscale is true', () {
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 300,
        sourceHeight: 200,
        maxWidth: 1200,
        maxHeight: 1200,
        allowUpscale: true,
      );

      expect(target.width, equals(1200));
      expect(target.height, equals(800));
    });

    test('preserves aspect ratio for square source and box', () {
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 512,
        sourceHeight: 512,
        maxWidth: 256,
        maxHeight: 256,
      );

      expect(target.width, equals(256));
      expect(target.height, equals(256));
    });

    test('clamps computed dimensions to a minimum of 1', () {
      // Extremely wide source into a tiny box would round height to 0.
      final target = BicubicResizer.computeFitDimensions(
        sourceWidth: 10000,
        sourceHeight: 1,
        maxWidth: 10,
        maxHeight: 10,
      );

      expect(target.width, equals(10));
      expect(target.height, equals(1));
    });

    test('throws ArgumentError for non-positive source dimensions', () {
      expect(
        () => BicubicResizer.computeFitDimensions(
          sourceWidth: 0,
          sourceHeight: 100,
          maxWidth: 50,
          maxHeight: 50,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for non-positive max dimensions', () {
      expect(
        () => BicubicResizer.computeFitDimensions(
          sourceWidth: 100,
          sourceHeight: 100,
          maxWidth: 0,
          maxHeight: 50,
        ),
        throwsArgumentError,
      );
    });
  });

  group('BicubicDimensions', () {
    test('value equality holds for identical dimensions', () {
      const a = BicubicDimensions(width: 640, height: 480);
      const b = BicubicDimensions(width: 640, height: 480);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs when either dimension differs', () {
      const a = BicubicDimensions(width: 640, height: 480);
      const c = BicubicDimensions(width: 640, height: 481);

      expect(a, isNot(equals(c)));
    });

    test('toString includes the WxH format', () {
      const d = BicubicDimensions(width: 800, height: 600);

      expect(d.toString(), contains('800x600'));
    });
  });
}
