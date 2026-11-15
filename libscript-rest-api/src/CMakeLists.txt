# ## Overview
# CMake build definition for the native C11 libscript-rest-api executable.
#
# ## Usage
# Included via add_subdirectory(src) from libscript-rest-api/CMakeLists.txt.

set(SOURCES
    main.c
    rest_dispatch.c
)

add_executable(libscript-rest-api ${SOURCES})

if(MSVC)
    target_compile_options(libscript-rest-api PRIVATE /W4 /WX)
else()
    target_compile_options(libscript-rest-api PRIVATE -Wall -Wextra -Wconversion -Wsign-conversion -Werror -pedantic)
endif()

if(TARGET c-rest-framework)
    target_link_libraries(libscript-rest-api PRIVATE c-rest-framework)
endif()

if(WIN32)
    target_link_libraries(libscript-rest-api PRIVATE ws2_32 bcrypt)
elseif(UNIX AND NOT APPLE)
    target_link_libraries(libscript-rest-api PRIVATE pthread m)
endif()
