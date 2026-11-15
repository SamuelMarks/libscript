# ## Overview
# Standalone CMake build definition for LibScript's rootless Zephyr RTOS native_sim firmware target.
#
# ## Usage
# cmake -B <build_dir> -GNinja -DZEPHYR_CONF_DIR=<dir> -DZEPHYR_VER=<ver> _lib/kernel/zephyr/bsp

cmake_minimum_required(VERSION 3.16)
project(libscript_zephyr_sim C)
set(CMAKE_C_STANDARD 11)

add_executable(zephyr.elf zephyr_boot_main.c)
target_compile_definitions(zephyr.elf PRIVATE ZEPHYR_HOST_SIM=1 ZEPHYR_VER_STR="${ZEPHYR_VER}")
target_include_directories(zephyr.elf PRIVATE "${ZEPHYR_CONF_DIR}")
