# libscript-rest-api

This directory contains the REST API server for `libscript`. It provides an HTTP interface to
programmatically execute `libscript` components, manage multicloud resources, and query system
states.

## Overview

The API is built using the `c-rest-framework` to maintain a lightweight footprint and native
execution speeds, aligning with the core philosophy of `libscript`. It acts as a daemon, safely
wrapping and executing the underlying shell scripts, tracking their execution as background jobs,
and returning standardized JSON responses.

## Future Portability

This project is currently housed within the `libscript` repository to prevent version skew and
simplify CI/CD. However, the directory structure and documentation are designed to be self-contained
so that it can be easily extracted into a standalone repository (`libscript-rest-api`) in the future
if a strict separation of concerns is required.

## Directory Structure

- `README.md` - High-level overview.
- `ARCHITECTURE.md` - Technical design and component layout.
- `USAGE.md` - Instructions for building, configuring, and running the server.
