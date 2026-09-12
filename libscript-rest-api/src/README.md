# LibScript REST API Source

This directory contains the C source implementation and build definitions for the native LibScript
REST API server (`libscript-rest-api`).

## Architecture

- **`main.c`**: Entry point for the LibScript daemon and REST API server, handling daemon lifecycle
  and HTTP routing via `c-rest-framework`.
- **`CMakeLists.txt`**: CMake build configuration targeting standard C99/C11 compilers, with vendor
  dependencies dynamically linked or compiled in-tree.

## Building

```sh
cd libscript-rest-api
mkdir -p build && cd build
cmake ..
cmake --build .
```
