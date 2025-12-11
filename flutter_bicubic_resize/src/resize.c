#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION

// Disable unused features to reduce binary size
#define STBI_NO_PSD
#define STBI_NO_TGA
#define STBI_NO_GIF
#define STBI_NO_HDR
#define STBI_NO_PIC
#define STBI_NO_PNM

#include "stb_image.h"
#include "stb_image_write.h"
#include "stb_image_resize2.h"
#include "resize.h"

#include <stdlib.h>
#include <string.h>

// ============================================================================
// Raw pixel data resize functions
// ============================================================================

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
        input_width * 3,
        output,
        output_width,
        output_height,
        output_width * 3,
        STBIR_RGB,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CATMULLROM
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
        input_width * 4,
        output,
        output_width,
        output_height,
        output_width * 4,
        STBIR_RGBA,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CATMULLROM
    );

    return 0;
}

// ============================================================================
// Helper for stbi_write to memory
// ============================================================================

typedef struct {
    uint8_t* data;
    int size;
    int capacity;
} WriteContext;

static void write_func(void* context, void* data, int size) {
    WriteContext* ctx = (WriteContext*)context;

    // Grow buffer if needed
    while (ctx->size + size > ctx->capacity) {
        ctx->capacity = ctx->capacity * 2;
        ctx->data = (uint8_t*)realloc(ctx->data, ctx->capacity);
    }

    memcpy(ctx->data + ctx->size, data, size);
    ctx->size += size;
}

// ============================================================================
// JPEG resize
// ============================================================================

FFI_EXPORT int bicubic_resize_jpeg(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    int quality,
    uint8_t** output_data,
    int* output_size
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return -1;
    }
    if (input_size <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }
    if (quality < 1) quality = 1;
    if (quality > 100) quality = 100;

    // Decode JPEG
    int src_width, src_height, src_channels;
    uint8_t* src_pixels = stbi_load_from_memory(
        input_data, input_size,
        &src_width, &src_height, &src_channels,
        3  // Force RGB output
    );

    if (src_pixels == NULL) {
        return -1;
    }

    // Allocate output pixel buffer
    uint8_t* dst_pixels = (uint8_t*)malloc(output_width * output_height * 3);
    if (dst_pixels == NULL) {
        stbi_image_free(src_pixels);
        return -1;
    }

    // Resize using bicubic
    stbir_resize(
        src_pixels,
        src_width,
        src_height,
        src_width * 3,
        dst_pixels,
        output_width,
        output_height,
        output_width * 3,
        STBIR_RGB,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CATMULLROM
    );

    stbi_image_free(src_pixels);

    // Encode to JPEG
    WriteContext ctx;
    ctx.capacity = output_width * output_height * 3;  // Initial estimate
    ctx.size = 0;
    ctx.data = (uint8_t*)malloc(ctx.capacity);

    if (ctx.data == NULL) {
        free(dst_pixels);
        return -1;
    }

    int result = stbi_write_jpg_to_func(
        write_func, &ctx,
        output_width, output_height, 3,
        dst_pixels, quality
    );

    free(dst_pixels);

    if (result == 0) {
        free(ctx.data);
        return -1;
    }

    // Shrink buffer to actual size
    *output_data = (uint8_t*)realloc(ctx.data, ctx.size);
    *output_size = ctx.size;

    return 0;
}

// ============================================================================
// PNG resize
// ============================================================================

FFI_EXPORT int bicubic_resize_png(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    uint8_t** output_data,
    int* output_size
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return -1;
    }
    if (input_size <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    // Decode PNG (preserve alpha if present)
    int src_width, src_height, src_channels;
    uint8_t* src_pixels = stbi_load_from_memory(
        input_data, input_size,
        &src_width, &src_height, &src_channels,
        0  // Keep original channels
    );

    if (src_pixels == NULL) {
        return -1;
    }

    // Use 4 channels (RGBA) for PNG to preserve transparency
    int channels = (src_channels >= 4) ? 4 : 3;

    // If we need to convert to RGBA
    uint8_t* src_rgba = NULL;
    if (src_channels != channels) {
        // Reload with desired channel count
        stbi_image_free(src_pixels);
        src_pixels = stbi_load_from_memory(
            input_data, input_size,
            &src_width, &src_height, &src_channels,
            channels
        );
        if (src_pixels == NULL) {
            return -1;
        }
    }

    // Allocate output pixel buffer
    uint8_t* dst_pixels = (uint8_t*)malloc(output_width * output_height * channels);
    if (dst_pixels == NULL) {
        stbi_image_free(src_pixels);
        return -1;
    }

    // Resize using bicubic
    stbir_resize(
        src_pixels,
        src_width,
        src_height,
        src_width * channels,
        dst_pixels,
        output_width,
        output_height,
        output_width * channels,
        (channels == 4) ? STBIR_RGBA : STBIR_RGB,
        STBIR_TYPE_UINT8,
        STBIR_EDGE_CLAMP,
        STBIR_FILTER_CATMULLROM
    );

    stbi_image_free(src_pixels);

    // Encode to PNG
    WriteContext ctx;
    ctx.capacity = output_width * output_height * channels * 2;  // Initial estimate (PNG is compressed)
    ctx.size = 0;
    ctx.data = (uint8_t*)malloc(ctx.capacity);

    if (ctx.data == NULL) {
        free(dst_pixels);
        return -1;
    }

    int result = stbi_write_png_to_func(
        write_func, &ctx,
        output_width, output_height, channels,
        dst_pixels, output_width * channels
    );

    free(dst_pixels);

    if (result == 0) {
        free(ctx.data);
        return -1;
    }

    // Shrink buffer to actual size
    *output_data = (uint8_t*)realloc(ctx.data, ctx.size);
    *output_size = ctx.size;

    return 0;
}

// ============================================================================
// Memory management
// ============================================================================

FFI_EXPORT void free_buffer(uint8_t* buffer) {
    if (buffer != NULL) {
        free(buffer);
    }
}
