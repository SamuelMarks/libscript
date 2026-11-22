# ## Overview
# Target definition and compiler warning configuration for libscript_msi_chainer DLL.
# Enables pedantic warning levels and treats all warnings as errors across MSVC, GCC, and Clang.

add_library(libscript_msi_chainer SHARED
    chainer.cpp
    chainer.hpp
)

target_include_directories(libscript_msi_chainer PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Enforce highest compiler and linker warning levels
if(MSVC)
    target_compile_options(libscript_msi_chainer PRIVATE
        /W4
        /WX
        /permissive-
        /external:anglebrackets
        /external:W0
    )
    target_link_options(libscript_msi_chainer PRIVATE
        /WX
    )
else()
    target_compile_options(libscript_msi_chainer PRIVATE
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
    target_link_libraries(libscript_msi_chainer PRIVATE
        msi
        kernel32
        user32
        advapi32
    )
endif()
