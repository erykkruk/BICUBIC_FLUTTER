import 'bicubic_resizer.dart';

/// Ready-to-use preprocessing configurations for common ML model families.
///
/// Every preset bundles the four things a model expects from its input
/// tensor: the square input size, the normalization formula, the channel
/// order and the tensor layout. Passing a preset to
/// [BicubicResizer.resizeForModelPreset] removes the guesswork (and the
/// silent accuracy loss) of hand-wiring those values per model.
///
/// ```dart
/// final tensor = BicubicResizer.resizeForModelPreset(
///   bytes: jpegBytes,
///   preset: NormalizationPreset.mobileNet,
/// );
/// ```
///
/// Read the concrete values through [NormalizationPresetX], for example
/// `NormalizationPreset.yolo.inputSize`.
enum NormalizationPreset {
  /// TensorFlow / Keras MobileNet family (V1, V2, V3).
  ///
  /// `(pixel / 127.5) - 1.0` into `[-1.0, 1.0]`, RGB, HWC, 224x224.
  mobileNet,

  /// PyTorch torchvision ResNet family (ResNet-18 up to ResNet-152).
  ///
  /// ImageNet mean/std, RGB, CHW, 224x224.
  resNet,

  /// PyTorch torchvision EfficientNet family (B0-B7 at their B0 input size).
  ///
  /// ImageNet mean/std, RGB, CHW, 224x224. Larger variants keep the same
  /// normalization but expect a bigger input - override [inputSize] with the
  /// explicit `outputWidth`/`outputHeight` arguments in that case.
  efficientNet,

  /// Ultralytics YOLO detection models (v5 through v11).
  ///
  /// `pixel / 255.0` into `[0.0, 1.0]`, RGB, CHW, 640x640.
  yolo,

  /// OpenAI CLIP / OpenCLIP image encoders.
  ///
  /// CLIP-specific mean/std, RGB, CHW, 224x224.
  openClip,
}

/// The concrete preprocessing values behind each [NormalizationPreset].
extension NormalizationPresetX on NormalizationPreset {
  /// ImageNet channel means, in the `[0.0, 1.0]` scale.
  static const List<double> _imageNetMean = [0.485, 0.456, 0.406];

  /// ImageNet channel standard deviations, in the `[0.0, 1.0]` scale.
  static const List<double> _imageNetStd = [0.229, 0.224, 0.225];

  /// CLIP channel means, in the `[0.0, 1.0]` scale.
  static const List<double> _clipMean = [0.48145466, 0.4578275, 0.40821073];

  /// CLIP channel standard deviations, in the `[0.0, 1.0]` scale.
  static const List<double> _clipStd = [0.26862954, 0.26130258, 0.27577711];

  /// Square input edge length in pixels the model was trained on.
  int get inputSize => switch (this) {
        NormalizationPreset.mobileNet => 224,
        NormalizationPreset.resNet => 224,
        NormalizationPreset.efficientNet => 224,
        NormalizationPreset.yolo => 640,
        NormalizationPreset.openClip => 224,
      };

  /// Normalization formula the model family expects.
  NormalizationType get normalization => switch (this) {
        NormalizationPreset.mobileNet => NormalizationType.centered,
        NormalizationPreset.resNet => NormalizationType.imageNet,
        NormalizationPreset.efficientNet => NormalizationType.imageNet,
        NormalizationPreset.yolo => NormalizationType.simple,
        NormalizationPreset.openClip => NormalizationType.custom,
      };

  /// Channel ordering the model family expects.
  ///
  /// All presets currently ship RGB; BGR models (some OpenCV-exported
  /// pipelines) still need an explicit `channelOrder` argument.
  ChannelOrder get channelOrder => ChannelOrder.rgb;

  /// Tensor layout the model family expects.
  ///
  /// TensorFlow / TFLite graphs read HWC, PyTorch exports read CHW.
  TensorLayout get layout => switch (this) {
        NormalizationPreset.mobileNet => TensorLayout.hwc,
        NormalizationPreset.resNet => TensorLayout.chw,
        NormalizationPreset.efficientNet => TensorLayout.chw,
        NormalizationPreset.yolo => TensorLayout.chw,
        NormalizationPreset.openClip => TensorLayout.chw,
      };

  /// Per-channel means in the `[0.0, 1.0]` scale.
  ///
  /// Only meaningful when [normalization] is [NormalizationType.custom];
  /// the built-in formulas carry their own constants. Returned as
  /// `[red, green, blue]`.
  List<double> get mean => switch (this) {
        NormalizationPreset.resNet => _imageNetMean,
        NormalizationPreset.efficientNet => _imageNetMean,
        NormalizationPreset.openClip => _clipMean,
        NormalizationPreset.mobileNet => const [0.0, 0.0, 0.0],
        NormalizationPreset.yolo => const [0.0, 0.0, 0.0],
      };

  /// Per-channel standard deviations in the `[0.0, 1.0]` scale.
  ///
  /// Only meaningful when [normalization] is [NormalizationType.custom].
  /// Returned as `[red, green, blue]`.
  List<double> get std => switch (this) {
        NormalizationPreset.resNet => _imageNetStd,
        NormalizationPreset.efficientNet => _imageNetStd,
        NormalizationPreset.openClip => _clipStd,
        NormalizationPreset.mobileNet => const [1.0, 1.0, 1.0],
        NormalizationPreset.yolo => const [1.0, 1.0, 1.0],
      };

  /// Number of floats a tensor produced with this preset contains.
  ///
  /// Always `inputSize * inputSize * 3` - presets are square and RGB.
  int get tensorLength => inputSize * inputSize * 3;

  /// Human-readable label, handy for debug overlays and logs.
  String get label => switch (this) {
        NormalizationPreset.mobileNet => 'MobileNet',
        NormalizationPreset.resNet => 'ResNet',
        NormalizationPreset.efficientNet => 'EfficientNet',
        NormalizationPreset.yolo => 'YOLO',
        NormalizationPreset.openClip => 'OpenCLIP',
      };
}
