# ## Overview
# Standalone CMake build definition for LibScript FreeRTOS POSIX & Win32 simulator ports.
#
# ## Usage
# cmake -B <build_dir> -GNinja -DFREERTOS_CONF_DIR=<dir> -DFREERTOS_VER=<ver> _lib/kernel/freertos/bsp

cmake_minimum_required(VERSION 3.16)
project(libscript_freertos_sim C)
set(CMAKE_C_STANDARD 11)

add_executable(freertos.elf freertos_boot_main.c)
target_compile_definitions(freertos.elf PRIVATE FREERTOS_HOST_SIM=1 FREERTOS_VER_STR="${FREERTOS_VER}")
target_include_directories(freertos.elf PRIVATE "${FREERTOS_CONF_DIR}")
