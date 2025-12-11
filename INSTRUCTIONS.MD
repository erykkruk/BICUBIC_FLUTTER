# Plan: Biblioteka Flutter do Bicubic Resize (FFI + stb_image_resize)

## Kontekst

Potrzebuję biblioteki Flutter, która:
- Robi resize obrazków algorytmem **Bicubic**
- Działa **identycznie** na iOS i Android (ten sam kod C pod spodem)
- Jest szybka (native performance)
- Można ją zaimportować jako package z GitHuba

## Cel

Stworzyć `flutter_bicubic_resize` — gotowy package do publikacji, który po dodaniu do `pubspec.yaml` działa out-of-the-box.

---

## Task 1: Struktura projektu

Stwórz strukturę katalogów dla Flutter plugin/package z FFI:

```
flutter_bicubic_resize/
├── README.md
├── LICENSE (MIT)
├── CHANGELOG.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── flutter_bicubic_resize.dart      # Public API export
│   └── src/
│       ├── bicubic_resizer.dart         # Główna klasa
│       ├── native_bindings.dart         # FFI bindings
│       └── resize_isolate.dart          # Compute isolate wrapper
├── src/                                  # Native C code
│   ├── stb_image_resize2.h              # Biblioteka STB (pobrać z GitHub)
│   ├── resize.c                         # Wrapper C
│   └── resize.h                         # Header
├── android/
│   ├── build.gradle
│   ├── CMakeLists.txt
│   └── src/main/AndroidManifest.xml
├── ios/
│   ├── flutter_bicubic_resize.podspec
│   └── Classes/
│       └── (empty - używamy src/ przez podspec)
├── example/
│   ├── pubspec.yaml
│   ├── lib/main.dart
│   └── ...
└── test/
    └── bicubic_resizer_test.dart
```

---

## Task 2: Kod C (native)

### 2.1 Pobierz stb_image_resize2.h

```bash
curl -o src/stb_image_resize2.h https://raw.githubusercontent.com/nothings/stb/master/stb_image_resize2.h
```

### 2.2 Stwórz src/resize.h

```c
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
```

### 2.3 Stwórz src/resize.c

Implementacja używająca stb_image_resize2.h z filtrem STBIR_FILTER_CUBICBSPLINE (Bicubic).

---

## Task 3: Android setup

### 3.1 android/build.gradle

```gradle
group 'com.example.flutter_bicubic_resize'
version '1.0.0'

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'

android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        
        externalNativeBuild {
            cmake {
                cppFlags ""
                arguments "-DANDROID_STL=c++_shared"
            }
        }
    }
    
    externalNativeBuild {
        cmake {
            path "CMakeLists.txt"
        }
    }
}
```

### 3.2 android/CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(flutter_bicubic_resize)

add_library(flutter_bicubic_resize SHARED
    ../src/resize.c
)

target_include_directories(flutter_bicubic_resize PRIVATE
    ../src
)

set_target_properties(flutter_bicubic_resize PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
)
```

### 3.3 android/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.flutter_bicubic_resize">
</manifest>
```

---

## Task 4: iOS setup

### 4.1 ios/flutter_bicubic_resize.podspec

```ruby
Pod::Spec.new do |s|
  s.name             = 'flutter_bicubic_resize'
  s.version          = '1.0.0'
  s.summary          = 'Bicubic image resize for Flutter using native C code'
  s.description      = 'Cross-platform bicubic image resizing with identical results on iOS and Android'
  s.homepage         = 'https://github.com/YOUR_USERNAME/flutter_bicubic_resize'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = '../src/**/*.{h,c}'
  s.platform         = :ios, '11.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_CFLAGS' => '-fvisibility=default'
  }
end
```

---

## Task 5: Dart FFI bindings

### 5.1 lib/src/native_bindings.dart

Stwórz FFI bindings:
- Załaduj bibliotekę dynamiczną (Android: .so, iOS: process)
- Zdefiniuj sygnatury funkcji C
- Stwórz wrapper Dart do wywołań

### 5.2 lib/src/bicubic_resizer.dart

Główna klasa z API:

```dart
class BicubicResizer {
  /// Resize raw RGB bytes
  static Uint8List resizeRgb({
    required Uint8List input,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
  });

  /// Resize raw RGBA bytes  
  static Uint8List resizeRgba({...});

  /// Convenience: resize from JPEG bytes, return JPEG bytes
  static Future<Uint8List> resizeJpeg({
    required Uint8List jpegBytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
  });
}
```

### 5.3 lib/src/resize_isolate.dart

Wrapper używający `compute()` żeby nie blokować UI thread.

### 5.4 lib/flutter_bicubic_resize.dart

```dart
library flutter_bicubic_resize;

export 'src/bicubic_resizer.dart';
```

---

## Task 6: pubspec.yaml

```yaml
name: flutter_bicubic_resize
description: Fast, consistent bicubic image resizing across iOS and Android using native C code.
version: 1.0.0
homepage: https://github.com/YOUR_USERNAME/flutter_bicubic_resize

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.0
  image: ^4.1.0  # Do decode/encode JPEG

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true
```

---

## Task 7: Example app

Stwórz example/lib/main.dart:
- Wybierz zdjęcie z galerii
- Zrób resize do 224x224
- Pokaż przed/po
- Wyświetl czas wykonania

---

## Task 8: README.md

```markdown
# flutter_bicubic_resize

Fast, consistent bicubic image resizing for Flutter.

## Features

- ✅ Native C performance (stb_image_resize)
- ✅ Identical results on iOS and Android
- ✅ Bicubic interpolation
- ✅ RGB and RGBA support
- ✅ Runs in isolate (non-blocking)

## Installation

```yaml
dependencies:
  flutter_bicubic_resize:
    git:
      url: https://github.com/YOUR_USERNAME/flutter_bicubic_resize.git
```

## Usage

```dart
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

// Resize JPEG
final resized = await BicubicResizer.resizeJpeg(
  jpegBytes: originalBytes,
  outputWidth: 224,
  outputHeight: 224,
);
```

## Why?

Default platform APIs use different algorithms:
- Android: Bilinear
- iOS: Depends on context

This package uses the same C code on both platforms = identical output.
```

---

## Task 9: Testy

Stwórz test/bicubic_resizer_test.dart:
- Test że resize działa
- Test że output ma prawidłowe wymiary
- Test RGB i RGBA

---

## Wymagania techniczne

1. **Minimalne wersje:**
   - Flutter 3.0+
   - Android SDK 21+
   - iOS 11.0+

2. **Dependencies:**
   - `ffi: ^2.1.0`
   - `image: ^4.1.0` (do decode/encode)

3. **Algorytm:** stb_image_resize2 z filtrem Cubic B-Spline (standardowy bicubic)

---

## Kolejność implementacji

1. [ ] Stwórz strukturę katalogów
2. [ ] Pobierz stb_image_resize2.h
3. [ ] Napisz resize.h i resize.c
4. [ ] Skonfiguruj Android (build.gradle, CMakeLists.txt)
5. [ ] Skonfiguruj iOS (podspec)
6. [ ] Napisz Dart FFI bindings
7. [ ] Napisz główną klasę BicubicResizer
8. [ ] Dodaj isolate wrapper
9. [ ] Stwórz pubspec.yaml
10. [ ] Napisz README.md
11. [ ] Stwórz example app
12. [ ] Przetestuj na Android
13. [ ] Przetestuj na iOS
14. [ ] Commit & push

---

## Dodatkowe uwagi dla AI

- Użyj `STBIR_FILTER_CUBICBSPLINE` dla prawdziwego bicubic
- Pamiętaj o `visibility("default")` żeby symbole były eksportowane
- iOS wymaga `DynamicLibrary.process()` (statyczne linkowanie)
- Android wymaga `DynamicLibrary.open('libflutter_bicubic_resize.so')`
- Obsłuż edge case: input mniejszy niż output (upscale też powinien działać)