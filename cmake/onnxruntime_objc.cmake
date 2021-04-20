# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

if (${CMAKE_VERSION} VERSION_LESS "3.18")
    message(FATAL_ERROR "CMake 3.18+ is required when building the Objective-C API.")
endif()

check_language(OBJC)
if (CMAKE_OBJC_COMPILER)
    enable_language(OBJC)
else()
    message(FATAL_ERROR "Objective-C is not supported.")
endif()

check_language(OBJCXX)
if (CMAKE_OBJCXX_COMPILER)
    enable_language(OBJCXX)
else()
    message(FATAL_ERROR "Objective-C++ is not supported.")
endif()

set(OBJC_ROOT "${REPO_ROOT}/objc")

set(OBJC_ARC_COMPILE_OPTIONS
    "-fobjc-arc"
    "-fobjc-arc-exceptions")

# onnxruntime_objc target

# these headers are the public interface
# explicitly list them here so it is easy to see what is included
set(onnxruntime_objc_headers
    "${OBJC_ROOT}/include/onnxruntime.h"
    "${OBJC_ROOT}/include/onnxruntime/ort_env.h"
    "${OBJC_ROOT}/include/onnxruntime/ort_session.h"
    "${OBJC_ROOT}/include/onnxruntime/ort_value.h")

file(GLOB onnxruntime_objc_srcs
    "${OBJC_ROOT}/src/*.h"
    "${OBJC_ROOT}/src/*.m"
    "${OBJC_ROOT}/src/*.mm")

# files common to implementation and test targets
set(onnxruntime_objc_common_srcs
    "${OBJC_ROOT}/common/assert_arc_enabled.mm")

source_group(TREE "${OBJC_ROOT}"
    FILES
        ${onnxruntime_objc_headers}
        ${onnxruntime_objc_srcs}
        ${onnxruntime_objc_common_srcs})

add_library(onnxruntime_objc SHARED
    ${onnxruntime_objc_headers}
    ${onnxruntime_objc_srcs}
    ${onnxruntime_objc_common_srcs})

target_include_directories(onnxruntime_objc
    PUBLIC
        "${OBJC_ROOT}/include"
    PRIVATE
        "${OPTIONAL_LITE_INCLUDE_DIR}"
        "${OBJC_ROOT}")

find_library(FOUNDATION_LIB Foundation REQUIRED)

target_link_libraries(onnxruntime_objc PUBLIC onnxruntime ${FOUNDATION_LIB})

target_compile_options(onnxruntime_objc PRIVATE ${OBJC_ARC_COMPILE_OPTIONS})

set_target_properties(onnxruntime_objc PROPERTIES
    FRAMEWORK TRUE
    VERSION "1.0.0"
    SOVERSION "1.0.0"
    FRAMEWORK_VERSION "A"
    PUBLIC_HEADER "${onnxruntime_objc_headers}"
    FOLDER "ONNXRuntime")

if (onnxruntime_BUILD_UNIT_TESTS)
    find_package(XCTest REQUIRED)

    # onnxruntime_test_objc target

    file(GLOB onnxruntime_objc_test_srcs
        "${OBJC_ROOT}/test/*.h"
        "${OBJC_ROOT}/test/*.m"
        "${OBJC_ROOT}/test/*.mm")

    source_group(TREE "${OBJC_ROOT}"
        FILES ${onnxruntime_objc_test_srcs})

    xctest_add_bundle(onnxruntime_objc_test onnxruntime_objc
        ${onnxruntime_objc_headers}
        ${onnxruntime_objc_test_srcs}
        ${onnxruntime_objc_common_srcs})

    target_include_directories(onnxruntime_objc_test
        PRIVATE
            "${OBJC_ROOT}")

    target_compile_options(onnxruntime_objc_test PRIVATE ${OBJC_ARC_COMPILE_OPTIONS})

    set_target_properties(onnxruntime_objc_test PROPERTIES
        FOLDER "ONNXRuntimeTest")

    add_custom_command(TARGET onnxruntime_objc_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${OBJC_ROOT}/test/testdata"
            "$<TARGET_BUNDLE_CONTENT_DIR:onnxruntime_objc_test>/Resources/testdata")

    xctest_add_test(XCTest.onnxruntime_objc_test onnxruntime_objc_test)

    set_property(TEST XCTest.onnxruntime_objc_test APPEND PROPERTY
        ENVIRONMENT DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:onnxruntime>)
endif()