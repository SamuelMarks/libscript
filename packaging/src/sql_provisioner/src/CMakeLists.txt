# ## Overview
# Target definition and compiler warning configuration for sql_provisioner DLL.
# Enables pedantic warning levels and treats all warnings as errors across MSVC, GCC, and Clang.

add_library(sql_provisioner SHARED
    sql_provisioner.cpp
    sql_provisioner.hpp
)

target_include_directories(sql_provisioner PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Enforce highest compiler and linker warning levels
if(MSVC)
    target_compile_options(sql_provisioner PRIVATE
        /W4
        /WX
        /permissive-
        /external:anglebrackets
        /external:W0
    )
    target_link_options(sql_provisioner PRIVATE
        /WX
    )
else()
    target_compile_options(sql_provisioner PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Werror
        -Wshadow
        -Wnon-virtual-dtor
        -Wold-style-cast
        -Wcast-align
        -Wunused
        -Woverloaded-virtual
        -Wconversion
        -Wsign-conversion
        -Wnull-dereference
        -Wdouble-promotion
        -Wformat=2
    )
endif()

if(WIN32)
    target_link_libraries(sql_provisioner PRIVATE
        msi
        ws2_32
        kernel32
        user32
        advapi32
    )
endif()
