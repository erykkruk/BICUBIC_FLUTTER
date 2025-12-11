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

# Ensure exported symbols are visible
target_compile_options(flutter_bicubic_resize PRIVATE
    -fvisibility=hidden
)
