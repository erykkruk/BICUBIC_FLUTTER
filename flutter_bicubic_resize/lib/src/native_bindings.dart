import 'dart:ffi';
import 'dart:io';

// C function signatures
typedef BicubicResizeRgbNative = Int32 Function(
  Pointer<Uint8> input,
  Int32 inputWidth,
  Int32 inputHeight,
  Pointer<Uint8> output,
  Int32 outputWidth,
  Int32 outputHeight,
);

typedef BicubicResizeRgbDart = int Function(
  Pointer<Uint8> input,
  int inputWidth,
  int inputHeight,
  Pointer<Uint8> output,
  int outputWidth,
  int outputHeight,
);

typedef BicubicResizeRgbaNative = Int32 Function(
  Pointer<Uint8> input,
  Int32 inputWidth,
  Int32 inputHeight,
  Pointer<Uint8> output,
  Int32 outputWidth,
  Int32 outputHeight,
);

typedef BicubicResizeRgbaDart = int Function(
  Pointer<Uint8> input,
  int inputWidth,
  int inputHeight,
  Pointer<Uint8> output,
  int outputWidth,
  int outputHeight,
);

class NativeBindings {
  static NativeBindings? _instance;
  static NativeBindings get instance => _instance ??= NativeBindings._();

  late final DynamicLibrary _library;
  late final BicubicResizeRgbDart bicubicResizeRgb;
  late final BicubicResizeRgbaDart bicubicResizeRgba;

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
      // For macOS development/testing
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
    bicubicResizeRgb = _library
        .lookup<NativeFunction<BicubicResizeRgbNative>>('bicubic_resize_rgb')
        .asFunction<BicubicResizeRgbDart>();

    bicubicResizeRgba = _library
        .lookup<NativeFunction<BicubicResizeRgbaNative>>('bicubic_resize_rgba')
        .asFunction<BicubicResizeRgbaDart>();
  }
}
