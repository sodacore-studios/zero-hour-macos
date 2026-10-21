# Platform/MacOS — Metal backend, Cocoa integration, platform stubs
# This library provides the macOS platform layer that replaces Win32Device components.

# ── Metal rendering backend (DX8 → Metal) ──
set(METAL_SRC
    Source/Metal/MetalDevice8.mm
    Source/Metal/MetalInterface8.mm
    Source/Metal/MetalSurface8.mm
    Source/Metal/MetalTexture8.mm
    Source/Metal/MetalCubeTexture8.mm
    Source/Metal/MacOSDisplayManager.mm
    Source/Metal/MetalBridgeMappings.h
    Source/Metal/MetalDevice8.h
    Source/Metal/MetalFormatConvert.h
    Source/Metal/MetalInterface8.h
    Source/Metal/MetalIndexBuffer8.h
    Source/Metal/MetalSurface8.h
    Source/Metal/MetalTexture8.h
    Source/Metal/MetalTextureCapture.h
    Source/Metal/MetalVertexBuffer8.h
)

# ── Main application (game engine, entry handled by GeneralsMD/Code/Main) ──
# MacOSGameEngine, MacOSMouse and MacOSGameClientFactory bind to a single game's W3D
# device layer, so each game compiles them itself against its own headers. See
# macos_platform_game_sources() at the end of this file.
set(MAIN_SRC
    Source/Main/MacOSGameEngine.h
    Source/Main/MacOSCrashTrail.cpp
    Source/Main/MacOSCrashTrail.h
)

# ── Audio ──
# MacOSAudioManager reads GlobalData, whose field offsets differ between the games, so it
# compiles per game. See macos_platform_add_game_glue() at the end of this file.
set(AUDIO_SRC
    Source/Audio/MacOSAudioManager.h
    Source/Audio/AVAudioBridge.mm
    Source/Audio/AVAudioBridge.h
    Source/Audio/MacOSVideoAudioStream.mm
    Source/Audio/MacOSVideoAudioStream.h
    Source/Audio/AdpcmWavDecoder.cpp
    Source/Audio/AdpcmWavDecoder.h
)

# ── Input ──
set(INPUT_SRC
    Source/Input/MacOSKeyboard.mm
    Source/Input/MacOSKeyboard.h
    Source/Input/MacOSMouse.h
)

# ── System ──
set(SYSTEM_SRC
    Source/System/MacOSLocalFileSystem.mm
    Source/System/MacOSLocalFileSystem.h
)

# ── Stubs ──
set(STUBS_SRC
    Source/GeneralsOnlineStubs.cpp
)

# Simulation compatibility definitions are shared with Windows in the root build.

# ── Combine all sources ──
add_library(macos_platform STATIC
    ${METAL_SRC}
    ${MAIN_SRC}
    ${AUDIO_SRC}
    ${INPUT_SRC}
    ${SYSTEM_SRC}
    ${STUBS_SRC}
)

# ── Include directories ──
target_include_directories(macos_platform PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Include
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/Metal
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/Main
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/Input
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/System
    ${CMAKE_CURRENT_SOURCE_DIR}/Source/Audio
)

target_include_directories(macos_platform PRIVATE
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WWLib
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WWDebug
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WWMath
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WWSaveLoad
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WW3D2
    ${CMAKE_SOURCE_DIR}/Core/Libraries/Source/WWVegas/WWAudio
    ${CMAKE_SOURCE_DIR}/Core/GameEngineDevice/Include
    ${CMAKE_SOURCE_DIR}/Core/GameEngine/Include
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/GameEngine/Include/Precompiled
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/GameEngine/Include
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/GameEngineDevice/Include
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/Libraries/Source/WWVegas
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/Libraries/Source/WWVegas/WW3D2
    ${CMAKE_SOURCE_DIR}/GeneralsMD/Code/GameEngine/Include/GameNetwork/GeneralsOnline
)

# ── macOS frameworks ──
find_library(METAL_FRAMEWORK Metal REQUIRED)
find_library(METALKIT_FRAMEWORK MetalKit REQUIRED)
find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)
find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
find_library(AUDIOTOOLBOX_FRAMEWORK AudioToolbox REQUIRED)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation REQUIRED)
find_library(CORETEXT_FRAMEWORK CoreText REQUIRED)
find_library(COREGRAPHICS_FRAMEWORK CoreGraphics REQUIRED)

target_link_libraries(macos_platform PUBLIC
    ${METAL_FRAMEWORK}
    ${METALKIT_FRAMEWORK}
    ${QUARTZCORE_FRAMEWORK}
    ${COCOA_FRAMEWORK}
    ${APPKIT_FRAMEWORK}
    ${IOKIT_FRAMEWORK}
    ${AUDIOTOOLBOX_FRAMEWORK}
    ${AVFOUNDATION_FRAMEWORK}
    ${CORETEXT_FRAMEWORK}
    ${COREGRAPHICS_FRAMEWORK}
)

# ── Project dependencies ──
target_link_libraries(macos_platform PUBLIC
    core_config
    corei_always
    corei_gameengine_include
    resources
)

target_link_libraries(macos_platform PRIVATE
    zi_always
    zi_gameengine_include
)

# ── Compile Metal shaders ──
execute_process(
    COMMAND xcrun -sdk macosx metal --version
    RESULT_VARIABLE METAL_CHECK_RESULT
    OUTPUT_QUIET ERROR_QUIET
)
# TheSuperHackers @build Support Command Line Tools without the offline Metal compiler.
set(METAL_SHADER_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/Source/Metal/MacOSShaders.metal)
if(METAL_CHECK_RESULT EQUAL 0)
    set(METAL_AIR_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/MacOSShaders.air)
    set(METAL_BUNDLE_RESOURCE ${CMAKE_CURRENT_BINARY_DIR}/default.metallib)
    add_custom_command(
        VERBATIM
        OUTPUT ${METAL_AIR_OUTPUT}
        COMMAND xcrun -sdk macosx metal -std=metal3.0 -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -c ${METAL_SHADER_SOURCE} -o ${METAL_AIR_OUTPUT}
        DEPENDS ${METAL_SHADER_SOURCE}
        COMMENT "Compiling Metal shaders"
    )
    add_custom_command(
        VERBATIM
        OUTPUT ${METAL_BUNDLE_RESOURCE}
        COMMAND xcrun -sdk macosx metallib ${METAL_AIR_OUTPUT} -o ${METAL_BUNDLE_RESOURCE}
        DEPENDS ${METAL_AIR_OUTPUT}
        COMMENT "Linking Metal shader library"
    )
else()
    message(STATUS "Offline Metal compiler unavailable; bundle shader source for runtime compilation")
    set(METAL_BUNDLE_RESOURCE ${CMAKE_CURRENT_BINARY_DIR}/MacOSShaders.metal)
    add_custom_command(
        VERBATIM
        OUTPUT ${METAL_BUNDLE_RESOURCE}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${METAL_SHADER_SOURCE} ${METAL_BUNDLE_RESOURCE}
        DEPENDS ${METAL_SHADER_SOURCE}
        COMMENT "Bundling Metal shader source"
    )
endif()
set(METAL_BUNDLE_RESOURCE ${METAL_BUNDLE_RESOURCE} PARENT_SCOPE)
add_custom_target(metal_shaders ALL DEPENDS ${METAL_BUNDLE_RESOURCE})
add_dependencies(macos_platform metal_shaders)

# ── ObjC++ settings ──
target_compile_options(macos_platform PRIVATE
    $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>
    "$<$<COMPILE_LANGUAGE:OBJCXX>:-include;${CMAKE_CURRENT_SOURCE_DIR}/Include/metal_prefix.h>"
)

target_precompile_headers(macos_platform PRIVATE
    [["Utility/CppMacros.h"]]
)

# Disable PCH for ObjC++ files — PCH is compiled as C++ which conflicts with .mm
set_source_files_properties(
    Source/Metal/MetalDevice8.mm
    Source/Metal/MetalInterface8.mm
    Source/Metal/MetalSurface8.mm
    Source/Metal/MetalTexture8.mm
    Source/Metal/MetalCubeTexture8.mm
    Source/Metal/MacOSDisplayManager.mm
    Source/Input/MacOSKeyboard.mm
    Source/System/MacOSLocalFileSystem.mm
    Source/Audio/AVAudioBridge.mm
    Source/Audio/MacOSVideoAudioStream.mm
    PROPERTIES
        SKIP_PRECOMPILE_HEADERS ON
        LANGUAGE OBJCXX
)

# ── Per-game platform glue ──
# These sources bind to types that exist separately in Generals and GeneralsMD: the W3D
# device layer (W3DGameClient, W3DDisplay, W3DGameLogic and friends) and GlobalData, whose
# field offsets and inline accessors differ between the games. Compiling them inside the
# shared library would bind every game to whichever headers won the include order, so each
# game target compiles its own copy against its own includes.
function(macos_platform_add_game_glue target)
    target_sources(${target} PRIVATE
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSGameEngine.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSBundleImage.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Audio/MacOSAudioManager.cpp
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Input/MacOSMouse.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Input/MacOSGameClientFactory.cpp
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/dx8wrapper_metal.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalVertexBuffer8.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalIndexBuffer8.mm
    )

    # MacOSMain.mm is added by each game's Main CMakeLists and keeps that target's
    # precompiled header, so it is deliberately absent here.
    set_source_files_properties(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSGameEngine.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSBundleImage.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Input/MacOSMouse.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/dx8wrapper_metal.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalVertexBuffer8.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalIndexBuffer8.mm
        PROPERTIES
            SKIP_PRECOMPILE_HEADERS ON
            LANGUAGE OBJCXX
    )

    set_source_files_properties(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Input/MacOSGameClientFactory.cpp
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Audio/MacOSAudioManager.cpp
        PROPERTIES
            SKIP_PRECOMPILE_HEADERS ON
    )

    # Apple framework headers collide with engine types (WideChar, RGBColor, Byte). The
    # two glue sources moved out of the shared library keep the prefix header and ARC it
    # applied to them; MacOSMain.mm never had either and still must not get them.
    set_source_files_properties(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSGameEngine.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Main/MacOSBundleImage.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Input/MacOSMouse.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/dx8wrapper_metal.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalVertexBuffer8.mm
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Source/Metal/MetalIndexBuffer8.mm
        PROPERTIES
            COMPILE_OPTIONS "-fobjc-arc;-include;${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Include/metal_prefix.h"
    )
endfunction()
