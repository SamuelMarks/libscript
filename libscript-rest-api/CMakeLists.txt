cmake_minimum_required(VERSION 3.10)
project(libscript-rest-api C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Configure build output directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Add vendor directory for the c-rest-framework
# We use add_subdirectory if it has a CMakeLists.txt, otherwise we just include its paths
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/vendor/c-rest-framework/CMakeLists.txt")
    add_subdirectory(vendor/c-rest-framework)
endif()

# Include directories (both for our project and for the vendor framework if we need to include it manually)
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/c-rest-framework/include
)

# Add src subdirectory
add_subdirectory(src)

# Add a custom target to run the server easily
add_custom_target(run
    COMMAND $<TARGET_FILE:libscript-rest-api>
    DEPENDS libscript-rest-api
    COMMENT "Running libscript REST API Server..."
    USES_TERMINAL
)
