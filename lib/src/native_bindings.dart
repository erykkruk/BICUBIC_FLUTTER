import 'dart:ffi';
import 'dart:io';

// ============================================================================
// C function signatures - Raw pixel resize
// ============================================================================

typedef BicubicResizeRgbNative = Int32 Function(
  Pointer<Uint8> input,
  Int32 inputWidth,
  Int32 inputHeight,
  Pointer<Uint8> output,
  Int32 outputWidth,
  Int32 outputHeight,
  Int32 filter,
  Float crop,
);

typedef BicubicResizeRgbDart = int Function(
  Pointer<Uint8> input,
  int inputWidth,
  int inputHeight,
  Pointer<Uint8> output,
  int outputWidth,
  int outputHeight,
  int filter,
  double crop,
);

typedef BicubicResizeRgbaNative = Int32 Function(
  Pointer<Uint8> input,
  Int32 inputWidth,
  Int32 inputHeight,
  Pointer<Uint8> output,
  Int32 outputWidth,
  Int32 outputHeight,
  Int32 filter,
  Float crop,
);

typedef BicubicResizeRgbaDart = int Function(
  Pointer<Uint8> input,
  int inputWidth,
  int inputHeight,
  Pointer<Uint8> output,
  int outputWidth,
  int outputHeight,
  int filter,
  double crop,
);

// ============================================================================
// C function signatures - JPEG/PNG resize
// ============================================================================

typedef BicubicResizeJpegNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Int32 outputWidth,
  Int32 outputHeight,
  Int32 quality,
  Int32 filter,
  Float crop,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
);

typedef BicubicResizeJpegDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  int outputWidth,
  int outputHeight,
  int quality,
  int filter,
  double crop,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
);

typedef BicubicResizePngNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Int32 outputWidth,
  Int32 outputHeight,
  Int32 filter,
  Float crop,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
);

typedef BicubicResizePngDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  int outputWidth,
  int outputHeight,
  int filter,
  double crop,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
);

// ============================================================================
// C function signatures - Memory management
// ============================================================================

typedef FreeBufferNative = Void Function(Pointer<Uint8> buffer);
typedef FreeBufferDart = void Function(Pointer<Uint8> buffer);

// ============================================================================
// Native bindings class
// ============================================================================

class NativeBindings {
  static NativeBindings? _instance;
  static NativeBindings get instance => _instance ??= NativeBindings._();

  late final DynamicLibrary _library;

  // Raw pixel resize
  late final BicubicResizeRgbDart bicubicResizeRgb;
  late final BicubicResizeRgbaDart bicubicResizeRgba;

  // JPEG/PNG resize
  late final BicubicResizeJpegDart bicubicResizeJpeg;
  late final BicubicResizePngDart bicubicResizePng;

  // Memory management
  late final FreeBufferDart freeBuffer;

  NativeBindings._() {
    _library = _loadLibrary();
    _bindFunctions();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libflutter_bicubic_resize.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libflutter_bicubic_resize.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('flutter_bicubic_resize.dll');
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  void _bindFunctions() {
    // Raw pixel resize
    bicubicResizeRgb = _library
        .lookup<NativeFunction<BicubicResizeRgbNative>>('bicubic_resize_rgb')
        .asFunction<BicubicResizeRgbDart>();

    bicubicResizeRgba = _library
        .lookup<NativeFunction<BicubicResizeRgbaNative>>('bicubic_resize_rgba')
        .asFunction<BicubicResizeRgbaDart>();

    // JPEG/PNG resize
    bicubicResizeJpeg = _library
        .lookup<NativeFunction<BicubicResizeJpegNative>>('bicubic_resize_jpeg')
        .asFunction<BicubicResizeJpegDart>();

    bicubicResizePng = _library
        .lookup<NativeFunction<BicubicResizePngNative>>('bicubic_resize_png')
        .asFunction<BicubicResizePngDart>();

    // Memory management
    freeBuffer = _library
        .lookup<NativeFunction<FreeBufferNative>>('free_buffer')
        .asFunction<FreeBufferDart>();
  }
}
