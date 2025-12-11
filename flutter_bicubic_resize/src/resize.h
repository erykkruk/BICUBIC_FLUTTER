#ifndef FLUTTER_BICUBIC_RESIZE_H
#define FLUTTER_BICUBIC_RESIZE_H

#include <stdint.h>

#if defined(_WIN32)
#define FFI_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Raw pixel data resize functions
// ============================================================================

// Resize RGB image using Bicubic interpolation
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_rgb(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height
);

// Resize RGBA image using Bicubic interpolation
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_rgba(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height
);

// ============================================================================
// JPEG resize functions (decode -> resize -> encode)
// ============================================================================

// Resize JPEG image using Bicubic interpolation
// input_data: JPEG file bytes
// input_size: size of input JPEG in bytes
// output_width, output_height: target dimensions
// quality: JPEG quality 1-100
// output_data: pointer to receive allocated output buffer (caller must free with free_buffer)
// output_size: pointer to receive output size
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_jpeg(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    int quality,
    uint8_t** output_data,
    int* output_size
);

// ============================================================================
// PNG resize functions (decode -> resize -> encode)
// ============================================================================

// Resize PNG image using Bicubic interpolation
// input_data: PNG file bytes
// input_size: size of input PNG in bytes
// output_width, output_height: target dimensions
// output_data: pointer to receive allocated output buffer (caller must free with free_buffer)
// output_size: pointer to receive output size
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_png(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    uint8_t** output_data,
    int* output_size
);

// ============================================================================
// Memory management
// ============================================================================

// Free buffer allocated by resize functions
FFI_EXPORT void free_buffer(uint8_t* buffer);

#ifdef __cplusplus
}
#endif

#endif
