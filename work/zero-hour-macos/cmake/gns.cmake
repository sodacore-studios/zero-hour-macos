if(APPLE OR WIN32)
    # Configure GameNetworkingSockets build
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(BUILD_TOOLS OFF CACHE BOOL "" FORCE)

    if(WIN32)
        set(BUILD_SHARED_LIB OFF CACHE BOOL "" FORCE)
        set(BUILD_STATIC_LIB ON CACHE BOOL "" FORCE)
    endif()
    set(Protobuf_USE_STATIC_LIBS ON CACHE BOOL "" FORCE)
    include(protobuf_static)
    if(WIN32)
        set(Protobuf_DIR "${PROTOBUF_STATIC_PREFIX}/cmake" CACHE PATH "" FORCE)
    else()
        set(Protobuf_DIR "${PROTOBUF_STATIC_PREFIX}/lib/cmake/protobuf" CACHE PATH "" FORCE)
    endif()
    unset(Protobuf_LIBRARY CACHE)
    unset(Protobuf_INCLUDE_DIR CACHE)
    unset(Protobuf_PROTOC_EXECUTABLE CACHE)

    set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON CACHE BOOL "" FORCE)

    # Enable WebRTC ICE (implementation=2) instead of Valve native ICE (implementation=1)
    set(USE_STEAMWEBRTC ON CACHE BOOL "" FORCE)
    add_definitions(-DSTEAMNETWORKINGSOCKETS_ENABLE_WEBRTC)

    FetchContent_Declare(
        GameNetworkingSockets
        GIT_REPOSITORY https://github.com/ValveSoftware/GameNetworkingSockets.git
        GIT_TAG        d534c19aa760df3fb75fd20db13ba1932b8a5463
    )
    
    FetchContent_MakeAvailable(GameNetworkingSockets)

    # p2p_webrtc.cpp defines CConnectionTransportP2PICE_WebRTC and
    # g_SteamNetworkingSockets_CreateICESessionFunc needed by the ENABLE_WEBRTC code path.
    # GNS upstream CMakeLists doesn't include it in the opensource source list.
    if(WIN32)
        set(ZERO_HOUR_GNS_TARGET GameNetworkingSockets_s)
    else()
        set(ZERO_HOUR_GNS_TARGET GameNetworkingSockets)
    endif()
    target_sources(${ZERO_HOUR_GNS_TARGET} PRIVATE
        "${gamenetworkingsockets_SOURCE_DIR}/src/steamnetworkingsockets/clientlib/steamnetworkingsockets_p2p_webrtc.cpp"
    )

    # libwebrtc-lite.a (cocoa_threading.mm) requires Foundation for NSThread
    if(APPLE)
    find_library(FOUNDATION_FW Foundation)
    if(FOUNDATION_FW)
        target_link_libraries(GameNetworkingSockets PRIVATE ${FOUNDATION_FW})
    endif()
    endif()
endif()
