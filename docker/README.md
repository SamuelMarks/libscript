# Docker Assets and Base Images

This directory contains base Dockerfiles, templates, and builder helpers for LibScript
containerization workflows.

## Base Images

- **Alpine (`base.alpine.Dockerfile`)**: Minimalist, security-hardened Alpine Linux base container
  configured for LibScript bootstrapping.
- **Debian (`base.debian.Dockerfile`)**: Standard Debian container base with essential system
  utilities for LibScript component operations.
- **Templates (`Dockerfile.tpl`, `Dockerfile.no_body.tpl`)**: Dynamic Dockerfile templates
  interpolated during `package-as docker` runs.

## Usage

Generate Docker assets from any stack definition using:

```sh
./libscript.sh package-as docker
./libscript.sh package-as docker_compose
```
