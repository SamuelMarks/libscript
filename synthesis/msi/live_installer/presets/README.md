# msi-rs Application Workloads

## Purpose & Overview

Encapsulates application-tier workload recipes orchestrated by the `msi-rs` installation engine.
Provides staging, configuration injection, and service setup for multi-tier applications like Open
edX and WordPress.

## Usage

```sh
# Deploy Open edX application workload into target rootfs
./openedx.sh <target_sysroot> [options]

# Deploy WordPress workload into target rootfs
./wordpress.sh <target_sysroot> [options]
```

## Available Scripts

- `openedx.sh` / `.cmd`: Configures Open edX LMS/CMS microfrontends, Python runtime, and services.
- `wordpress.sh` / `.cmd`: Configures WordPress web stack, database schema, and web server bindings.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
