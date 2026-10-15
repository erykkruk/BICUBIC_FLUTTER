// Native regression tests for src/resize.c.
//
// The Dart test suite cannot load the FFI library on the host, so the memory
// safety guarantees of the C layer are exercised here instead. Build and run
// with sanitizers so out-of-bounds access fails loudly:
//
//   cc -std=c99 -g -O1 -fsanitize=address,undefined -fno-sanitize-recover=all \
//      -Isrc src/resize.c test/native/resize_test.c -lm -o build/resize_test
//   ./build/resize_test

#include "resize.h"
#include "stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SOURCE_WIDTH 8
#define SOURCE_HEIGHT 4
#define SOURCE_CHANNELS 3
#define JPEG_QUALITY 90
#define PNG_COMPRESSION 6
#define OVERFLOWING_DIM 40000
#define EXIF_ORIENTATION_ROTATE_90_CW 6
#define EXIF_ORIENTATION_NORMAL 1
#define EXIF_IFD_OFFSET_DEFAULT 8u
#define EXIF_IFD_OFFSET_NEGATIVE_AS_INT 0x80000000u
#define EXIF_IFD_OFFSET_WRAPPING 0xFFFFFFF0u
#define MAX_ENCODED_SIZE 4096

static int failures = 0;

#define CHECK(condition, message)                                   \
    do {                                                            \
        if (!(condition)) {                                         \
            fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, \
                    message);                                       \
            failures++;                                             \
        }                                                           \
    } while (0)

typedef struct {
    uint8_t data[MAX_ENCODED_SIZE];
    int size;
} Buffer;

static void buffer_write(void* context, void* data, int size) {
    Buffer* buffer = (Buffer*)context;
    if (buffer->size + size > MAX_ENCODED_SIZE) return;
    memcpy(buffer->data + buffer->size, data, size);
    buffer->size += size;
}

static void fill_gradient(uint8_t* pixels) {
    for (int i = 0; i < SOURCE_WIDTH * SOURCE_HEIGHT * SOURCE_CHANNELS; i++) {
        pixels[i] = (uint8_t)(i * 7);
    }
}

static Buffer make_jpeg(void) {
    uint8_t pixels[SOURCE_WIDTH * SOURCE_HEIGHT * SOURCE_CHANNELS];
    fill_gradient(pixels);
    Buffer jpeg = {{0}, 0};
    stbi_write_jpg_to_func(buffer_write, &jpeg, SOURCE_WIDTH, SOURCE_HEIGHT,
                           SOURCE_CHANNELS, pixels, JPEG_QUALITY);
    return jpeg;
}

static Buffer make_png(void) {
    uint8_t pixels[SOURCE_WIDTH * SOURCE_HEIGHT * SOURCE_CHANNELS];
    fill_gradient(pixels);
    Buffer png = {{0}, 0};
    stbi_write_png_to_func(buffer_write, &png, SOURCE_WIDTH, SOURCE_HEIGHT,
                           SOURCE_CHANNELS, pixels,
                           SOURCE_WIDTH * SOURCE_CHANNELS);
    return png;
}

// Inserts a little-endian EXIF APP1 segment with a single orientation entry
// right after the SOI marker. [ifd_offset] is written verbatim so tests can
// forge hostile offsets.
static Buffer make_jpeg_with_exif(uint32_t ifd_offset, uint16_t orientation) {
    Buffer jpeg = make_jpeg();
    const uint8_t app1[] = {
        0xFF, 0xE1, 0x00, 0x22,              // APP1, length 34
        'E', 'x', 'i', 'f', 0x00, 0x00,      // EXIF identifier
        'I', 'I', 0x2A, 0x00,                // TIFF header, little endian
        (uint8_t)(ifd_offset), (uint8_t)(ifd_offset >> 8),
        (uint8_t)(ifd_offset >> 16), (uint8_t)(ifd_offset >> 24),
        0x01, 0x00,                          // one IFD entry
        0x12, 0x01, 0x03, 0x00,              // tag 0x0112, type SHORT
        0x01, 0x00, 0x00, 0x00,              // count 1
        (uint8_t)(orientation), (uint8_t)(orientation >> 8), 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,              // next IFD offset
    };

    Buffer result = {{0}, 0};
    memcpy(result.data, jpeg.data, 2);
    memcpy(result.data + 2, app1, sizeof(app1));
    memcpy(result.data + 2 + sizeof(app1), jpeg.data + 2, jpeg.size - 2);
    result.size = jpeg.size + (int)sizeof(app1);
    return result;
}

static int read_orientation(const Buffer* jpeg) {
    int width = 0, height = 0, channels = 0, format = 0, orientation = 0;
    int result = bicubic_get_image_info(jpeg->data, jpeg->size, &width,
                                        &height, &channels, &format,
                                        &orientation);
    CHECK(result == BICUBIC_SUCCESS, "get_image_info should succeed");
    return orientation;
}

static void test_resize_jpeg_succeeds(void) {
    Buffer jpeg = make_jpeg();
    uint8_t* output = NULL;
    int output_size = 0;

    int result = bicubic_resize_jpeg(jpeg.data, jpeg.size, 4, 2, JPEG_QUALITY,
                                     FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f,
                                     CROP_CENTER, ASPECT_ORIGINAL, 1.0f, 1.0f,
                                     1, &output, &output_size);

    CHECK(result == BICUBIC_SUCCESS, "valid JPEG resize should succeed");
    CHECK(output != NULL && output_size > 0, "JPEG output should be set");
    free_buffer(output);
}

static void test_encoded_outputs_reject_overflowing_dims(void) {
    Buffer jpeg = make_jpeg();
    Buffer png = make_png();
    uint8_t* output = NULL;
    int output_size = 0;

    int jpeg_result = bicubic_resize_jpeg(
        jpeg.data, jpeg.size, OVERFLOWING_DIM, OVERFLOWING_DIM, JPEG_QUALITY,
        FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL,
        1.0f, 1.0f, 1, &output, &output_size);
    int png_result = bicubic_resize_png(
        png.data, png.size, OVERFLOWING_DIM, OVERFLOWING_DIM,
        FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL,
        1.0f, 1.0f, PNG_COMPRESSION, &output, &output_size);
    int rgb_result = bicubic_resize_to_rgb(
        jpeg.data, jpeg.size, OVERFLOWING_DIM, OVERFLOWING_DIM,
        FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL,
        1.0f, 1.0f, 1, 1, &output, &output_size);

    CHECK(jpeg_result == BICUBIC_ERROR_INVALID_DIMS,
          "JPEG resize must reject output buffers larger than INT_MAX");
    CHECK(png_result == BICUBIC_ERROR_INVALID_DIMS,
          "PNG resize must reject output buffers larger than INT_MAX");
    CHECK(rgb_result == BICUBIC_ERROR_INVALID_DIMS,
          "raw RGB resize must reject output buffers larger than INT_MAX");
    CHECK(output == NULL, "no output buffer should be returned on error");
}

static void test_raw_resize_rejects_overflowing_dims(void) {
    uint8_t input[SOURCE_WIDTH * SOURCE_HEIGHT * 4] = {0};
    uint8_t output[4] = {0};

    int rgb_result = bicubic_resize_rgb(
        input, SOURCE_WIDTH, SOURCE_HEIGHT, output, OVERFLOWING_DIM,
        OVERFLOWING_DIM, FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f, CROP_CENTER,
        ASPECT_ORIGINAL, 1.0f, 1.0f);
    int rgba_result = bicubic_resize_rgba(
        input, SOURCE_WIDTH, SOURCE_HEIGHT, output, OVERFLOWING_DIM,
        OVERFLOWING_DIM, FILTER_CATMULL_ROM, EDGE_CLAMP, 1.0f, CROP_CENTER,
        ASPECT_ORIGINAL, 1.0f, 1.0f);

    CHECK(rgb_result == BICUBIC_ERROR_INVALID_DIMS,
          "RGB resize must reject output buffers larger than INT_MAX");
    CHECK(rgba_result == BICUBIC_ERROR_INVALID_DIMS,
          "RGBA resize must reject output buffers larger than INT_MAX");
}

static void test_exif_orientation_is_read(void) {
    Buffer jpeg = make_jpeg_with_exif(EXIF_IFD_OFFSET_DEFAULT,
                                      EXIF_ORIENTATION_ROTATE_90_CW);

    int orientation = read_orientation(&jpeg);

    CHECK(orientation == EXIF_ORIENTATION_ROTATE_90_CW,
          "valid EXIF orientation should be parsed");
}

static void test_exif_rotation_swaps_dimensions(void) {
    Buffer jpeg = make_jpeg_with_exif(EXIF_IFD_OFFSET_DEFAULT,
                                      EXIF_ORIENTATION_ROTATE_90_CW);
    uint8_t* output = NULL;
    int output_size = 0;

    int result = bicubic_resize_to_rgb(
        jpeg.data, jpeg.size, SOURCE_HEIGHT, SOURCE_WIDTH, FILTER_CATMULL_ROM,
        EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL, 1.0f, 1.0f, 1, 1,
        &output, &output_size);

    CHECK(result == BICUBIC_SUCCESS, "rotated resize should succeed");
    CHECK(output_size == SOURCE_WIDTH * SOURCE_HEIGHT * SOURCE_CHANNELS,
          "rotated output size should match requested dims");
    free_buffer(output);
}

static void test_exif_hostile_ifd_offsets_are_ignored(void) {
    const uint32_t hostile_offsets[] = {
        EXIF_IFD_OFFSET_NEGATIVE_AS_INT,
        EXIF_IFD_OFFSET_WRAPPING,
    };

    for (size_t i = 0; i < sizeof(hostile_offsets) / sizeof(hostile_offsets[0]);
         i++) {
        Buffer jpeg = make_jpeg_with_exif(hostile_offsets[i],
                                          EXIF_ORIENTATION_ROTATE_90_CW);
        uint8_t* output = NULL;
        int output_size = 0;

        int orientation = read_orientation(&jpeg);
        int result = bicubic_resize_jpeg(
            jpeg.data, jpeg.size, 4, 2, JPEG_QUALITY, FILTER_CATMULL_ROM,
            EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL, 1.0f, 1.0f, 1,
            &output, &output_size);

        CHECK(orientation == EXIF_ORIENTATION_NORMAL,
              "out-of-range IFD offset should fall back to normal orientation");
        CHECK(result == BICUBIC_SUCCESS,
              "JPEG with hostile EXIF should still resize");
        free_buffer(output);
    }
}

static void test_exif_truncated_segment_is_ignored(void) {
    Buffer full = make_jpeg_with_exif(EXIF_IFD_OFFSET_DEFAULT,
                                      EXIF_ORIENTATION_ROTATE_90_CW);
    const int truncated_size = 2 + 4 + 6 + 8 + 4;
    uint8_t* output = NULL;
    int output_size = 0;

    // EXIF is parsed before decoding, so a buffer cut inside the IFD reaches
    // the parser and must be rejected by the decoder without overreading.
    int result = bicubic_resize_jpeg(
        full.data, truncated_size, 4, 2, JPEG_QUALITY, FILTER_CATMULL_ROM,
        EDGE_CLAMP, 1.0f, CROP_CENTER, ASPECT_ORIGINAL, 1.0f, 1.0f, 1,
        &output, &output_size);

    CHECK(result == BICUBIC_ERROR_DECODE_FAILED,
          "truncated JPEG should fail to decode");
    CHECK(output == NULL, "no output buffer should be returned on error");
}

int main(void) {
    test_resize_jpeg_succeeds();
    test_encoded_outputs_reject_overflowing_dims();
    test_raw_resize_rejects_overflowing_dims();
    test_exif_orientation_is_read();
    test_exif_rotation_swaps_dimensions();
    test_exif_hostile_ifd_offsets_are_ignored();
    test_exif_truncated_segment_is_ignored();

    if (failures > 0) {
        fprintf(stderr, "%d native check(s) failed\n", failures);
        return EXIT_FAILURE;
    }
    printf("All native checks passed\n");
    return EXIT_SUCCESS;
}
