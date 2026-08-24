import 'dart:typed_data';

import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // These tests cover the pure-Dart preset table and the batch scheduler.
  // Anything that reaches the native library needs a device, so the batch
  // cases here stay on the paths that short-circuit before the first resize.

  group('NormalizationPreset - input sizes', () {
    test('classification presets use the 224px ImageNet input', () {
      expect(NormalizationPreset.mobileNet.inputSize, equals(224));
      expect(NormalizationPreset.resNet.inputSize, equals(224));
      expect(NormalizationPreset.efficientNet.inputSize, equals(224));
      expect(NormalizationPreset.openClip.inputSize, equals(224));
    });

    test('yolo uses the 640px detection input', () {
      expect(NormalizationPreset.yolo.inputSize, equals(640));
    });

    test('every preset has a positive input size', () {
      for (final preset in NormalizationPreset.values) {
        expect(preset.inputSize, greaterThan(0), reason: preset.label);
      }
    });

    test('tensorLength is inputSize squared times three RGB channels', () {
      expect(
        NormalizationPreset.mobileNet.tensorLength,
        equals(224 * 224 * 3),
      );
      expect(NormalizationPreset.yolo.tensorLength, equals(640 * 640 * 3));
    });
  });

  group('NormalizationPreset - normalization formulas', () {
    test('mobileNet centers pixels into [-1, 1]', () {
      expect(
        NormalizationPreset.mobileNet.normalization,
        equals(NormalizationType.centered),
      );
    });

    test('resNet and efficientNet use ImageNet mean/std', () {
      expect(
        NormalizationPreset.resNet.normalization,
        equals(NormalizationType.imageNet),
      );
      expect(
        NormalizationPreset.efficientNet.normalization,
        equals(NormalizationType.imageNet),
      );
    });

    test('yolo scales pixels into [0, 1]', () {
      expect(
        NormalizationPreset.yolo.normalization,
        equals(NormalizationType.simple),
      );
    });

    test('openClip carries its own mean/std as a custom normalization', () {
      expect(
        NormalizationPreset.openClip.normalization,
        equals(NormalizationType.custom),
      );
      expect(
        NormalizationPreset.openClip.mean,
        equals([0.48145466, 0.4578275, 0.40821073]),
      );
      expect(
        NormalizationPreset.openClip.std,
        equals([0.26862954, 0.26130258, 0.27577711]),
      );
    });

    test('ImageNet presets expose the canonical mean/std triples', () {
      expect(NormalizationPreset.resNet.mean, equals([0.485, 0.456, 0.406]));
      expect(NormalizationPreset.resNet.std, equals([0.229, 0.224, 0.225]));
    });

    test('mean and std always have one entry per RGB channel', () {
      for (final preset in NormalizationPreset.values) {
        expect(preset.mean, hasLength(3), reason: preset.label);
        expect(preset.std, hasLength(3), reason: preset.label);
      }
    });

    test('no preset has a zero std, which would divide by zero', () {
      for (final preset in NormalizationPreset.values) {
        for (final value in preset.std) {
          expect(value, isNot(equals(0.0)), reason: preset.label);
        }
      }
    });
  });

  group('NormalizationPreset - tensor layout and channel order', () {
    test('TensorFlow-family MobileNet reads HWC', () {
      expect(NormalizationPreset.mobileNet.layout, equals(TensorLayout.hwc));
    });

    test('PyTorch-family presets read CHW', () {
      expect(NormalizationPreset.resNet.layout, equals(TensorLayout.chw));
      expect(
        NormalizationPreset.efficientNet.layout,
        equals(TensorLayout.chw),
      );
      expect(NormalizationPreset.yolo.layout, equals(TensorLayout.chw));
      expect(NormalizationPreset.openClip.layout, equals(TensorLayout.chw));
    });

    test('every preset expects RGB channel order', () {
      for (final preset in NormalizationPreset.values) {
        expect(preset.channelOrder, equals(ChannelOrder.rgb));
      }
    });

    test('every preset has a non-empty label', () {
      for (final preset in NormalizationPreset.values) {
        expect(preset.label, isNotEmpty);
      }
    });
  });

  group('resizeForModelPreset - input size overrides', () {
    final bytes = Uint8List(0);

    test('rejects a width override without a matching height', () {
      expect(
        () => BicubicResizer.resizeForModelPreset(
          bytes: bytes,
          preset: NormalizationPreset.efficientNet,
          outputWidth: 380,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a height override without a matching width', () {
      expect(
        () => BicubicResizer.resizeForModelPreset(
          bytes: bytes,
          preset: NormalizationPreset.efficientNet,
          outputHeight: 380,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-positive override', () {
      expect(
        () => BicubicResizer.resizeForModelPreset(
          bytes: bytes,
          preset: NormalizationPreset.resNet,
          outputWidth: 0,
          outputHeight: 224,
        ),
        throwsArgumentError,
      );
      expect(
        () => BicubicResizer.resizeForModelPreset(
          bytes: bytes,
          preset: NormalizationPreset.resNet,
          outputWidth: 224,
          outputHeight: -1,
        ),
        throwsArgumentError,
      );
    });

    test('async variant validates on the calling isolate', () {
      expect(
        () => BicubicResizer.resizeForModelPresetAsync(
          bytes: bytes,
          preset: NormalizationPreset.resNet,
          outputWidth: 224,
        ),
        throwsArgumentError,
      );
    });

    test('batch variant validates before scheduling any isolate', () {
      expect(
        () => BicubicResizer.resizeForModelPresetBatch(
          images: [bytes],
          preset: NormalizationPreset.yolo,
          outputHeight: 640,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Batch scheduling', () {
    test('defaultBatchConcurrency leaves a core for the caller', () {
      expect(BicubicResizer.defaultBatchConcurrency, greaterThanOrEqualTo(1));
    });

    test('an empty batch resolves to an empty list without any work', () async {
      final resized = await BicubicResizer.resizeBatch(
        images: const [],
        outputWidth: 224,
        outputHeight: 224,
      );
      expect(resized, isEmpty);
    });

    test('an empty model batch resolves to an empty list', () async {
      final tensors = await BicubicResizer.resizeForModelBatch(
        images: const [],
        outputWidth: 224,
        outputHeight: 224,
      );
      expect(tensors, isEmpty);
    });

    test('an empty preset batch resolves to an empty list', () async {
      final tensors = await BicubicResizer.resizeForModelPresetBatch(
        images: const [],
        preset: NormalizationPreset.mobileNet,
      );
      expect(tensors, isEmpty);
    });

    test('rejects a non-positive concurrency', () {
      expect(
        () => BicubicResizer.resizeBatch(
          images: const [],
          outputWidth: 224,
          outputHeight: 224,
          concurrency: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => BicubicResizer.resizeForModelBatch(
          images: const [],
          outputWidth: 224,
          outputHeight: 224,
          concurrency: -4,
        ),
        throwsArgumentError,
      );
    });

    test('concurrency is rejected before the empty-batch shortcut', () {
      // Guards against a caller silently getting away with a bad concurrency
      // value just because this particular batch happened to be empty.
      expect(
        () => BicubicResizer.resizeBatch(
          images: const [],
          outputWidth: 1,
          outputHeight: 1,
          concurrency: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Batch method signatures', () {
    test('resizeBatch exists', () {
      expect(BicubicResizer.resizeBatch, isA<Function>());
    });

    test('resizeForModelBatch exists', () {
      expect(BicubicResizer.resizeForModelBatch, isA<Function>());
    });

    test('resizeForModelPresetBatch exists', () {
      expect(BicubicResizer.resizeForModelPresetBatch, isA<Function>());
    });

    test('resizeForModelPreset exists', () {
      expect(BicubicResizer.resizeForModelPreset, isA<Function>());
    });

    test('resizeForModelPresetAsync exists', () {
      expect(BicubicResizer.resizeForModelPresetAsync, isA<Function>());
    });
  });
}
