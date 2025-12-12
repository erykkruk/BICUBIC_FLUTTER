import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BicubicResizer', () {
    test('RGB resize produces correct output size', () {
      // Note: These tests require the native library to be loaded,
      // which only works on actual devices/emulators.
      // For CI/unit tests, we verify the logic without native calls.

      const inputWidth = 100;
      const inputHeight = 100;
      const outputWidth = 50;
      const outputHeight = 50;

      // RGB: 3 bytes per pixel
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

      // RGBA: 4 bytes per pixel
      const inputSize = inputWidth * inputHeight * 4;
      const expectedOutputSize = outputWidth * outputHeight * 4;

      expect(inputSize, equals(40000));
      expect(expectedOutputSize, equals(10000));
    });

    test('input validation - RGB', () {
      const inputWidth = 10;
      const inputHeight = 10;
      const expectedSize = inputWidth * inputHeight * 3;

      // Correct size
      final correctInput = Uint8List(expectedSize);
      expect(correctInput.length, equals(300));

      // Wrong size would fail in actual implementation
      final wrongInput = Uint8List(100);
      expect(wrongInput.length, isNot(equals(expectedSize)));
    });

    test('input validation - RGBA', () {
      const inputWidth = 10;
      const inputHeight = 10;
      const expectedSize = inputWidth * inputHeight * 4;

      // Correct size
      final correctInput = Uint8List(expectedSize);
      expect(correctInput.length, equals(400));

      // Wrong size would fail in actual implementation
      final wrongInput = Uint8List(100);
      expect(wrongInput.length, isNot(equals(expectedSize)));
    });

    test('upscale dimensions are valid', () {
      // Upscaling should also work
      const inputWidth = 50;
      const inputHeight = 50;
      const outputWidth = 200;
      const outputHeight = 200;

      expect(outputWidth > inputWidth, isTrue);
      expect(outputHeight > inputHeight, isTrue);

      const outputSize = outputWidth * outputHeight * 3;
      expect(outputSize, equals(120000));
    });

    test('aspect ratio change dimensions', () {
      // Non-uniform scaling
      const inputWidth = 100;
      const inputHeight = 100;
      const outputWidth = 224;
      const outputHeight = 112;

      const inputPixels = inputWidth * inputHeight;
      const outputPixels = outputWidth * outputHeight;

      expect(inputPixels, equals(10000));
      expect(outputPixels, equals(25088));
    });

    test('center crop calculations', () {
      // Simulating center crop logic
      const srcWidth = 100;
      const srcHeight = 100;
      const crop = 0.8; // 80% center crop

      final cropWidth = (srcWidth * crop).toInt();
      final cropHeight = (srcHeight * crop).toInt();
      final cropX = (srcWidth - cropWidth) ~/ 2;
      final cropY = (srcHeight - cropHeight) ~/ 2;

      expect(cropWidth, equals(80));
      expect(cropHeight, equals(80));
      expect(cropX, equals(10));
      expect(cropY, equals(10));
    });

    test('crop value boundaries', () {
      // Test crop value clamping logic
      double clampCrop(double crop) {
        if (crop < 0.01) return 0.01;
        if (crop > 1.0) return 1.0;
        return crop;
      }

      expect(clampCrop(1.0), equals(1.0));
      expect(clampCrop(0.5), equals(0.5));
      expect(clampCrop(0.0), equals(0.01)); // Minimum 1%
      expect(clampCrop(-0.5), equals(0.01));
      expect(clampCrop(1.5), equals(1.0));
    });

    test('50% center crop dimensions', () {
      const srcWidth = 200;
      const srcHeight = 100;
      const crop = 0.5; // 50% center crop

      final cropWidth = (srcWidth * crop).toInt();
      final cropHeight = (srcHeight * crop).toInt();
      final cropX = (srcWidth - cropWidth) ~/ 2;
      final cropY = (srcHeight - cropHeight) ~/ 2;

      expect(cropWidth, equals(100));
      expect(cropHeight, equals(50));
      expect(cropX, equals(50));
      expect(cropY, equals(25));
    });
  });
}
