#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"
#include "resize.h"

FFI_EXPORT int bicubic_resize_rgb(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height
) {
    if (input == NULL || output == NULL) {
        return -1;
    }
    if (input_width <= 0 || input_height <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    stbir_resize(
        input,
        input_width,
        input_height,
        input_width * 3,  // input stride (3 channels for RGB)
        output,
        output_width,
        output_height,
        output_width * 3,  // output stride
        STBIR_RGB,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CUBICBSPLINE
    );

    return 0;
}

FFI_EXPORT int bicubic_resize_rgba(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height
) {
    if (input == NULL || output == NULL) {
        return -1;
    }
    if (input_width <= 0 || input_height <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    stbir_resize(
        input,
        input_width,
        input_height,
        input_width * 4,  // input stride (4 channels for RGBA)
        output,
        output_width,
        output_height,
        output_width * 4,  // output stride
        STBIR_RGBA,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CUBICBSPLINE
    );

    return 0;
}
