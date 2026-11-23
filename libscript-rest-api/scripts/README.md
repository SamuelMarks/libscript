# REST API Dependency Bootstrap Scripts (`libscript-rest-api/scripts/`)

## Overview

`libscript-rest-api/scripts/` (`bootstrap.{sh,cmd}`) fetches, verifies, and stages third-party C
dependencies (such as `c-rest-framework`) required to configure and build `libscript-rest-api` via
CMake in online or cached CI environments.

## Usage

```sh
./libscript-rest-api/scripts/bootstrap.sh
cmake -S libscript-rest-api -B libscript-rest-api/build
cmake --build libscript-rest-api/build
```
