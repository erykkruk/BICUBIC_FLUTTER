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

#ifdef __cplusplus
}
#endif

#endif
