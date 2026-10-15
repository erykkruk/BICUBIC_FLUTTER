# flutter_bicubic_resize

## Overview

Flutter FFI plugin (pub.dev `flutter_bicubic_resize`) for fast bicubic resize, crop, compress and ML tensor preprocessing. The whole decode -> resize -> encode pipeline runs in native C (stb_image, stb_image_resize2, stb_image_write).

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| Language | Dart | >=3.5.0 <4.0.0 |
| Framework | Flutter | >=3.24.0 |
| Native | C99 + stb single-header libs | vendored in `src/` |
| Interop | `ffi` | ^2.2.0 |
| Lints | `flutter_lints` | ^6.0.0 |
| Platforms | Android (CMake), iOS (CocoaPods + SwiftPM), macOS (CocoaPods) | |

## Development Commands

```bash
flutter pub get
dart format .
flutter analyze                 # must report zero issues
flutter test                    # Dart tests (do not load the native library)
mkdir -p build && cc -std=c99 -g -O1 \
  -fsanitize=address,signed-integer-overflow -fno-sanitize-recover=all \
  -Isrc src/resize.c test/native/resize_test.c -lm -o build/resize_test \
  && ./build/resize_test        # native C tests, same as the CI "native" job
dart pub publish --dry-run
```

## Directory Structure

```
lib/
  flutter_bicubic_resize.dart   # barrel export
  src/
    bicubic_resizer.dart        # public API, enums, errors, isolate batch helpers
    native_bindings.dart        # FFI typedefs + DynamicLibrary loading
    normalization_preset.dart   # ML presets
src/                            # canonical C sources (resize.c, resize.h, stb headers)
ios/flutter_bicubic_resize/Sources/flutter_bicubic_resize/   # COPY of src/ for iOS
macos/Classes/                  # COPY of src/ for macOS
android/CMakeLists.txt          # builds ../src/resize.c directly
test/                           # Dart tests + test/native/resize_test.c
```

## Architecture Pattern

Thin Dart facade (`BicubicResizer`, static methods) over a C ABI. Dart copies bytes into `calloc` memory, calls the native function, maps the negative return code to `BicubicResizeException`, and frees native buffers with `free_buffer`. `*Async` variants wrap the sync calls in `Isolate.run`.

## Module Structure

A new native operation touches, in order: `src/resize.h` (declaration + doc), `src/resize.c` (implementation), the iOS and macOS copies, `native_bindings.dart` (typedefs + lookup), `bicubic_resizer.dart` (public method + async variant), tests, README, CHANGELOG.

## Naming Conventions

- C: `bicubic_<verb>` exported with `FFI_EXPORT`, error codes `BICUBIC_ERROR_*`, enums as `#define` matching Dart enum `value`s.
- Dart enum values must equal the C `#define` integers (filters, edge modes, anchors, aspect modes, error codes).

## Error Handling

C functions return `BICUBIC_SUCCESS` (0) or a negative `BICUBIC_ERROR_*` code and never crash on bad input. Dart throws `ArgumentError` for caller mistakes detectable in Dart, `UnsupportedImageFormatException` for unknown formats and `BicubicResizeException` for native codes.

## Anti-patterns

- Editing `src/resize.c` or `src/resize.h` without copying it to the iOS and macOS folders (the three copies must stay byte-identical).
- Computing buffer sizes as plain `int` products in C without `pixel_buffer_fits` (heap overflow on large dims).
- Trusting offsets read from image data (EXIF) without bounds checks against the segment.
- Patching the vendored stb headers.
- Changing enum integer values or error code numbers (breaking change for the C ABI).

## Best Practices

- Add a case to `test/native/resize_test.c` for every native bug fix.
- Keep the public API backward compatible; bump the version in `pubspec.yaml` and both podspecs, and update the README install snippet and CHANGELOG.

## New Feature Checklist

1. C declaration + implementation, then sync iOS/macOS copies (`cp src/resize.* ...`).
2. FFI bindings and public Dart API with `///` docs and an `*Async` variant.
3. Dart tests (AAA) and native tests.
4. README, CHANGELOG, version bump.
5. Format, analyze, test, native tests, `dart pub publish --dry-run`.

## Release

Never merge to `main` without approval: a push to `main` runs `release.yml`, which tags `v<version>` from `pubspec.yaml` (or auto-bumps the patch if that tag already exists), and the tag triggers `publish.yml` to publish to pub.dev via OIDC.

## Claude Code Integration

| Type | Name | Purpose |
|------|------|---------|
| Workspace agents | architecture-review, code-review, security-review, testing-review | See `../CLAUDE.md` |
| Commands | /commit, /pr, /review, /quality-check | Workspace-level |
