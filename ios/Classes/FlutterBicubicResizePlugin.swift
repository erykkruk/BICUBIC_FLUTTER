import Flutter
import UIKit

public class FlutterBicubicResizePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No method channel needed - this is an FFI plugin
    // This class exists only to ensure the native code is linked into the app

    // CRITICAL: Force symbol retention by actually calling the C functions
    // This prevents the linker from stripping them as "unused"
    // The functions are defined in resize.h and implemented in resize.c
    forceSymbolRetention()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  // This function makes actual calls to C functions to force the linker to keep them
  // It's marked @inline(never) to prevent compiler optimization
  @inline(never)
  private static func forceSymbolRetention() {
    // Create tiny dummy buffers - these calls will fail safely but force linking
    var dummyInput: [UInt8] = [0]
    var dummyOutput: [UInt8] = [0]

    // Call each function with minimal parameters to force symbol inclusion
    // These calls are safe - they return early due to invalid dimensions
    // New API: filter, edge_mode, crop, crop_anchor, aspect_mode, aspect_w, aspect_h
    _ = bicubic_resize_rgb(&dummyInput, 0, 0, &dummyOutput, 0, 0, 0, 0, 1.0, 0, 0, 1.0, 1.0)
    _ = bicubic_resize_rgba(&dummyInput, 0, 0, &dummyOutput, 0, 0, 0, 0, 1.0, 0, 0, 1.0, 1.0)

    var outPtr: UnsafeMutablePointer<UInt8>? = nil
    var outSize: Int32 = 0
    // JPEG: filter, edge_mode, crop, crop_anchor, aspect_mode, aspect_w, aspect_h, apply_exif
    _ = bicubic_resize_jpeg(&dummyInput, 0, 0, 0, 80, 0, 0, 1.0, 0, 0, 1.0, 1.0, 1, &outPtr, &outSize)
    // PNG: filter, edge_mode, crop, crop_anchor, aspect_mode, aspect_w, aspect_h, compression_level
    _ = bicubic_resize_png(&dummyInput, 0, 0, 0, 0, 0, 1.0, 0, 0, 1.0, 1.0, 6, &outPtr, &outSize)

    free_buffer(nil)
  }
}
