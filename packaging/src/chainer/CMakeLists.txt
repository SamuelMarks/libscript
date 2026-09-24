# ## Overview
# Root CMake configuration for libscript_msi_chainer Windows Installer custom action DLL.
#
# ## Usage
# cmake -B build -S .
# cmake --build build

cmake_minimum_required(VERSION 3.15)
project(libscript_msi_chainer LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory(src)
