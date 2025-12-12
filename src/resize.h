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
// Filter types (matching stb_image_resize2 filters)
// ============================================================================

#define FILTER_CATMULL_ROM   0  // OpenCV INTER_CUBIC, PIL BICUBIC (default)
#define FILTER_CUBIC_BSPLINE 1  // Smoother, more blurry
#define FILTER_MITCHELL      2  // Mitchell-Netravali (balanced)

// ============================================================================
// Raw pixel data resize functions
// ============================================================================

// Resize RGB image using specified filter
// filter: 0=Catmull-Rom (default), 1=Cubic B-Spline, 2=Mitchell
// crop: center crop factor (0.0-1.0), 1.0 = no crop, 0.5 = center 50%
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_rgb(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height,
    int filter,
    float crop
);

// Resize RGBA image using specified filter
// filter: 0=Catmull-Rom (default), 1=Cubic B-Spline, 2=Mitchell
// crop: center crop factor (0.0-1.0), 1.0 = no crop, 0.5 = center 50%
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_rgba(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height,
    int filter,
    float crop
);

// ============================================================================
// JPEG resize functions (decode -> resize -> encode)
// ============================================================================

// Resize JPEG image
// filter: 0=Catmull-Rom (default), 1=Cubic B-Spline, 2=Mitchell
// quality: JPEG quality 1-100
// crop: center crop factor (0.0-1.0), 1.0 = no crop, 0.5 = center 50%
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_jpeg(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    int quality,
    int filter,
    float crop,
    uint8_t** output_data,
    int* output_size
);

// ============================================================================
// PNG resize functions (decode -> resize -> encode)
// ============================================================================

// Resize PNG image
// filter: 0=Catmull-Rom (default), 1=Cubic B-Spline, 2=Mitchell
// crop: center crop factor (0.0-1.0), 1.0 = no crop, 0.5 = center 50%
// Returns 0 on success, -1 on error
FFI_EXPORT int bicubic_resize_png(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    int filter,
    float crop,
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
