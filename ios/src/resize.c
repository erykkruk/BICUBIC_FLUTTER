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
// EXIF Orientation parsing
// ============================================================================

// EXIF orientation values:
// 1 = Normal
// 2 = Flip horizontal
// 3 = Rotate 180
// 4 = Flip vertical
// 5 = Transpose (rotate 90 CW + flip horizontal)
// 6 = Rotate 90 CW
// 7 = Transverse (rotate 90 CCW + flip horizontal)
// 8 = Rotate 90 CCW

static int parse_exif_orientation(const uint8_t* data, int size) {
    if (size < 12) return 1;

    // Check for JPEG SOI marker
    if (data[0] != 0xFF || data[1] != 0xD8) return 1;

    int offset = 2;
    while (offset + 4 < size) {
        if (data[offset] != 0xFF) return 1;

        uint8_t marker = data[offset + 1];

        // Skip padding bytes
        if (marker == 0xFF) {
            offset++;
            continue;
        }

        // APP1 marker (EXIF)
        if (marker == 0xE1) {
            int segment_length = (data[offset + 2] << 8) | data[offset + 3];
            int segment_start = offset + 4;

            // Check for "Exif\0\0" identifier
            if (segment_start + 6 > size) return 1;
            if (data[segment_start] != 'E' || data[segment_start + 1] != 'x' ||
                data[segment_start + 2] != 'i' || data[segment_start + 3] != 'f' ||
                data[segment_start + 4] != 0 || data[segment_start + 5] != 0) {
                return 1;
            }

            int tiff_start = segment_start + 6;
            if (tiff_start + 8 > size) return 1;

            // Check byte order (II = little endian, MM = big endian)
            int little_endian = (data[tiff_start] == 'I' && data[tiff_start + 1] == 'I');
            int big_endian = (data[tiff_start] == 'M' && data[tiff_start + 1] == 'M');
            if (!little_endian && !big_endian) return 1;

            // Read IFD0 offset
            uint32_t ifd_offset;
            if (little_endian) {
                ifd_offset = data[tiff_start + 4] | (data[tiff_start + 5] << 8) |
                            (data[tiff_start + 6] << 16) | (data[tiff_start + 7] << 24);
            } else {
                ifd_offset = (data[tiff_start + 4] << 24) | (data[tiff_start + 5] << 16) |
                            (data[tiff_start + 6] << 8) | data[tiff_start + 7];
            }

            int ifd_start = tiff_start + ifd_offset;
            if (ifd_start + 2 > size) return 1;

            // Read number of directory entries
            uint16_t num_entries;
            if (little_endian) {
                num_entries = data[ifd_start] | (data[ifd_start + 1] << 8);
            } else {
                num_entries = (data[ifd_start] << 8) | data[ifd_start + 1];
            }

            // Search for orientation tag (0x0112)
            int entry_start = ifd_start + 2;
            for (int i = 0; i < num_entries; i++) {
                int entry_offset = entry_start + i * 12;
                if (entry_offset + 12 > size) return 1;

                uint16_t tag;
                if (little_endian) {
                    tag = data[entry_offset] | (data[entry_offset + 1] << 8);
                } else {
                    tag = (data[entry_offset] << 8) | data[entry_offset + 1];
                }

                if (tag == 0x0112) {  // Orientation tag
                    uint16_t orientation;
                    if (little_endian) {
                        orientation = data[entry_offset + 8] | (data[entry_offset + 9] << 8);
                    } else {
                        orientation = (data[entry_offset + 8] << 8) | data[entry_offset + 9];
                    }
                    return (orientation >= 1 && orientation <= 8) ? orientation : 1;
                }
            }
            return 1;  // No orientation tag found
        }

        // SOS marker - stop searching
        if (marker == 0xDA) return 1;

        // Skip to next segment
        int segment_length = (data[offset + 2] << 8) | data[offset + 3];
        offset += 2 + segment_length;
    }

    return 1;  // No EXIF found
}

// Apply EXIF orientation transformation
static uint8_t* apply_orientation(uint8_t* pixels, int* width, int* height, int channels, int orientation) {
    if (orientation == 1) return pixels;  // Normal, no transformation needed

    int w = *width;
    int h = *height;

    uint8_t* result = NULL;
    int new_w = w, new_h = h;

    // Orientations 5,6,7,8 swap width and height
    if (orientation >= 5) {
        new_w = h;
        new_h = w;
    }

    result = (uint8_t*)malloc(new_w * new_h * channels);
    if (!result) return pixels;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int src_idx = (y * w + x) * channels;
            int dst_x, dst_y;

            switch (orientation) {
                case 2:  // Flip horizontal
                    dst_x = w - 1 - x;
                    dst_y = y;
                    break;
                case 3:  // Rotate 180
                    dst_x = w - 1 - x;
                    dst_y = h - 1 - y;
                    break;
                case 4:  // Flip vertical
                    dst_x = x;
                    dst_y = h - 1 - y;
                    break;
                case 5:  // Transpose (rotate 90 CW + flip horizontal)
                    dst_x = y;
                    dst_y = x;
                    break;
                case 6:  // Rotate 90 CW
                    dst_x = h - 1 - y;
                    dst_y = x;
                    break;
                case 7:  // Transverse (rotate 90 CCW + flip horizontal)
                    dst_x = h - 1 - y;
                    dst_y = w - 1 - x;
                    break;
                case 8:  // Rotate 90 CCW
                    dst_x = y;
                    dst_y = w - 1 - x;
                    break;
                default:
                    dst_x = x;
                    dst_y = y;
                    break;
            }

            int dst_idx = (dst_y * new_w + dst_x) * channels;
            for (int c = 0; c < channels; c++) {
                result[dst_idx + c] = pixels[src_idx + c];
            }
        }
    }

    free(pixels);
    *width = new_w;
    *height = new_h;
    return result;
}

// ============================================================================
// Helper: clamp crop value to valid range
// ============================================================================

static float clamp_crop(float crop) {
    if (crop < 0.01f) return 0.01f;  // Minimum 1%
    if (crop > 1.0f) return 1.0f;
    return crop;
}

// ============================================================================
// Helper: convert edge mode enum to stbir edge mode
// ============================================================================

static stbir_edge get_stbir_edge(int edge_mode) {
    switch (edge_mode) {
        case EDGE_WRAP:
            return STBIR_EDGE_WRAP;
        case EDGE_REFLECT:
            return STBIR_EDGE_REFLECT;
        case EDGE_ZERO:
            return STBIR_EDGE_ZERO;
        case EDGE_CLAMP:
        default:
            return STBIR_EDGE_CLAMP;
    }
}

// ============================================================================
// Helper: calculate crop parameters with anchor and aspect ratio support
// ============================================================================

static void calc_crop(
    int src_width, int src_height, float crop,
    int crop_anchor, int aspect_mode, float aspect_w, float aspect_h,
    int* out_x, int* out_y, int* out_width, int* out_height
) {
    crop = clamp_crop(crop);

    int crop_w, crop_h;

    // Calculate crop dimensions based on aspect mode
    if (aspect_mode == ASPECT_ORIGINAL) {
        // Keep original aspect ratio
        crop_w = (int)(src_width * crop);
        crop_h = (int)(src_height * crop);
    } else if (aspect_mode == ASPECT_CUSTOM && aspect_w > 0 && aspect_h > 0) {
        // Custom aspect ratio
        float target_ratio = aspect_w / aspect_h;
        float src_ratio = (float)src_width / (float)src_height;

        if (src_ratio > target_ratio) {
            // Source is wider - height constrains
            crop_h = (int)(src_height * crop);
            crop_w = (int)(crop_h * target_ratio);
        } else {
            // Source is taller - width constrains
            crop_w = (int)(src_width * crop);
            crop_h = (int)(crop_w / target_ratio);
        }
    } else {
        // ASPECT_SQUARE (default) - 1:1 aspect ratio
        int min_dim = (src_width < src_height) ? src_width : src_height;
        int crop_size = (int)(min_dim * crop);
        crop_w = crop_size;
        crop_h = crop_size;
    }

    // Ensure at least 1x1
    if (crop_w < 1) crop_w = 1;
    if (crop_h < 1) crop_h = 1;

    // Ensure doesn't exceed source dimensions
    if (crop_w > src_width) crop_w = src_width;
    if (crop_h > src_height) crop_h = src_height;

    // Calculate position based on anchor
    int x = 0, y = 0;
    int remaining_x = src_width - crop_w;
    int remaining_y = src_height - crop_h;

    switch (crop_anchor) {
        case CROP_TOP_LEFT:
            x = 0;
            y = 0;
            break;
        case CROP_TOP_CENTER:
            x = remaining_x / 2;
            y = 0;
            break;
        case CROP_TOP_RIGHT:
            x = remaining_x;
            y = 0;
            break;
        case CROP_CENTER_LEFT:
            x = 0;
            y = remaining_y / 2;
            break;
        case CROP_CENTER_RIGHT:
            x = remaining_x;
            y = remaining_y / 2;
            break;
        case CROP_BOTTOM_LEFT:
            x = 0;
            y = remaining_y;
            break;
        case CROP_BOTTOM_CENTER:
            x = remaining_x / 2;
            y = remaining_y;
            break;
        case CROP_BOTTOM_RIGHT:
            x = remaining_x;
            y = remaining_y;
            break;
        case CROP_CENTER:
        default:
            x = remaining_x / 2;
            y = remaining_y / 2;
            break;
    }

    *out_x = x;
    *out_y = y;
    *out_width = crop_w;
    *out_height = crop_h;
}

// ============================================================================
// Helper: convert filter enum to stbir filter
// ============================================================================

static stbir_filter get_stbir_filter(int filter) {
    switch (filter) {
        case FILTER_CUBIC_BSPLINE:
            return STBIR_FILTER_CUBICBSPLINE;
        case FILTER_MITCHELL:
            return STBIR_FILTER_MITCHELL;
        case FILTER_CATMULL_ROM:
        default:
            return STBIR_FILTER_CATMULLROM;
    }
}

// ============================================================================
// Raw pixel data resize functions
// ============================================================================

FFI_EXPORT int bicubic_resize_rgb(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height,
    int filter,
    int edge_mode,
    float crop,
    int crop_anchor,
    int aspect_mode,
    float aspect_w,
    float aspect_h
) {
    if (input == NULL || output == NULL) {
        return -1;
    }
    if (input_width <= 0 || input_height <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    // Calculate crop region
    int crop_x, crop_y, crop_width, crop_height;
    calc_crop(input_width, input_height, crop, crop_anchor, aspect_mode, aspect_w, aspect_h,
              &crop_x, &crop_y, &crop_width, &crop_height);

    // Get pointer to start of cropped region
    const uint8_t* crop_start = input + (crop_y * input_width + crop_x) * 3;

    stbir_resize(
        crop_start,
        crop_width,
        crop_height,
        input_width * 3,  // Original stride (not cropped width)
        output,
        output_width,
        output_height,
        output_width * 3,
        STBIR_RGB,
        STBIR_TYPE_UINT8,
        get_stbir_edge(edge_mode),
        get_stbir_filter(filter)
    );

    return 0;
}

FFI_EXPORT int bicubic_resize_rgba(
    const uint8_t* input,
    int input_width,
    int input_height,
    uint8_t* output,
    int output_width,
    int output_height,
    int filter,
    int edge_mode,
    float crop,
    int crop_anchor,
    int aspect_mode,
    float aspect_w,
    float aspect_h
) {
    if (input == NULL || output == NULL) {
        return -1;
    }
    if (input_width <= 0 || input_height <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    // Calculate crop region
    int crop_x, crop_y, crop_width, crop_height;
    calc_crop(input_width, input_height, crop, crop_anchor, aspect_mode, aspect_w, aspect_h,
              &crop_x, &crop_y, &crop_width, &crop_height);

    // Get pointer to start of cropped region
    const uint8_t* crop_start = input + (crop_y * input_width + crop_x) * 4;

    stbir_resize(
        crop_start,
        crop_width,
        crop_height,
        input_width * 4,  // Original stride (not cropped width)
        output,
        output_width,
        output_height,
        output_width * 4,
        STBIR_RGBA,
        STBIR_TYPE_UINT8,
        get_stbir_edge(edge_mode),
        get_stbir_filter(filter)
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
    int filter,
    int edge_mode,
    float crop,
    int crop_anchor,
    int aspect_mode,
    float aspect_w,
    float aspect_h,
    int apply_exif,
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

    // Parse EXIF orientation before decoding (if enabled)
    int orientation = 1;  // Default: no transformation
    if (apply_exif) {
        orientation = parse_exif_orientation(input_data, input_size);
    }

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

    // Apply EXIF orientation (may swap width/height for 90/270 degree rotations)
    if (apply_exif) {
        src_pixels = apply_orientation(src_pixels, &src_width, &src_height, 3, orientation);
    }

    // Calculate crop region
    int crop_x, crop_y, crop_width, crop_height;
    calc_crop(src_width, src_height, crop, crop_anchor, aspect_mode, aspect_w, aspect_h,
              &crop_x, &crop_y, &crop_width, &crop_height);

    // Get pointer to start of cropped region
    const uint8_t* crop_start = src_pixels + (crop_y * src_width + crop_x) * 3;

    // Allocate output pixel buffer
    uint8_t* dst_pixels = (uint8_t*)malloc(output_width * output_height * 3);
    if (dst_pixels == NULL) {
        free(src_pixels);
        return -1;
    }

    // Resize using selected filter (from cropped region)
    stbir_resize(
        crop_start,
        crop_width,
        crop_height,
        src_width * 3,  // Original stride
        dst_pixels,
        output_width,
        output_height,
        output_width * 3,
        STBIR_RGB,
        STBIR_TYPE_UINT8,
        get_stbir_edge(edge_mode),
        get_stbir_filter(filter)
    );

    free(src_pixels);

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

// External variable from stb_image_write for PNG compression level
extern int stbi_write_png_compression_level;

FFI_EXPORT int bicubic_resize_png(
    const uint8_t* input_data,
    int input_size,
    int output_width,
    int output_height,
    int filter,
    int edge_mode,
    float crop,
    int crop_anchor,
    int aspect_mode,
    float aspect_w,
    float aspect_h,
    int compression_level,
    uint8_t** output_data,
    int* output_size
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return -1;
    }
    if (input_size <= 0 || output_width <= 0 || output_height <= 0) {
        return -1;
    }

    // Clamp compression level to valid range (0-9)
    if (compression_level < 0) compression_level = 0;
    if (compression_level > 9) compression_level = 9;

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

    // Calculate crop region
    int crop_x, crop_y, crop_width, crop_height;
    calc_crop(src_width, src_height, crop, crop_anchor, aspect_mode, aspect_w, aspect_h,
              &crop_x, &crop_y, &crop_width, &crop_height);

    // Get pointer to start of cropped region
    const uint8_t* crop_start = src_pixels + (crop_y * src_width + crop_x) * channels;

    // Allocate output pixel buffer
    uint8_t* dst_pixels = (uint8_t*)malloc(output_width * output_height * channels);
    if (dst_pixels == NULL) {
        stbi_image_free(src_pixels);
        return -1;
    }

    // Resize using selected filter (from cropped region)
    stbir_resize(
        crop_start,
        crop_width,
        crop_height,
        src_width * channels,  // Original stride
        dst_pixels,
        output_width,
        output_height,
        output_width * channels,
        (channels == 4) ? STBIR_RGBA : STBIR_RGB,
        STBIR_TYPE_UINT8,
        get_stbir_edge(edge_mode),
        get_stbir_filter(filter)
    );

    stbi_image_free(src_pixels);

    // Set PNG compression level
    stbi_write_png_compression_level = compression_level;

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
