# TODO - flutter_bicubic_resize

## v1.4.0 - Async & Error Handling ✅

- [x] Add `resizeJpegAsync()`, `resizePngAsync()`, `resizeAsync()`, `resizeForModelAsync()` wrappers using `Isolate.run()`
- [x] Define native error codes enum (invalid input, decode failure, encode failure, memory allocation failure)
- [x] Return detailed error messages from native layer instead of generic `-1`
- [x] Validate custom `mean`/`std` values in `resizeForModel()` (must not be zero for std)

## v1.9.0 - ML Presets & Batch Processing (shipped)

- [x] Add `NormalizationPreset` with ready-to-use configs: `mobileNet`, `resNet`, `efficientNet`, `yolo`, `openClip`
- [x] Add `resizeBatch()` for processing multiple images in parallel across isolates
- [x] Add `resizeForModelBatch()` for ML pipeline preprocessing
- [x] Add `resizeForModelPreset()` / `resizeForModelPresetBatch()` preset entry points

## Format Utilities (shipped)

- [x] Format conversion without resize, shipped as `jpegToPng()` / `pngToJpeg()` / `convertFormat()`
- [ ] Add `decodeToRgb()` / `decodeToRgba()` (decode without resize)
- [x] Add `getImageInfo()` returning width, height, format, EXIF orientation without full decode

## v2.0.0 - Web & New Platforms

- [ ] Web support via WASM compilation of C code
- [ ] Verify and test Windows build
- [ ] Verify and test Linux build
- [ ] macOS standalone support (not just via iOS)

## Testing

- [ ] Integration tests with real JPEG/PNG images on device
- [ ] Edge case tests: 1x1 px input, very large images (8K), corrupted data, empty bytes
- [ ] Memory leak tests under stress (1000+ sequential resizes)
- [ ] Performance benchmarks with CI tracking (regression detection)
- [ ] Fuzz testing for native C code with random input data

## Documentation

- [ ] Document all native error codes with causes and solutions
- [ ] Add performance comparison table vs `image` package, `flutter_image_compress`, native platform APIs
- [ ] Add migration guide for major version bumps
