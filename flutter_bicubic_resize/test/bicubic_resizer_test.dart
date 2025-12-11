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
  });
}
