# Project Motivation

LibScript was developed to address the complexity and overhead often associated with modern configuration management, containerization, and multicloud orchestration.

## Granular Package & Version Management

Traditional system package managers often lock users into specific, sometimes outdated versions. Language-specific version managers (like `nvm` or `pyenv`) solve this for code but not for services. LibScript provides a granular manager for *everything*—Postgres, Nginx, Redis, etc.—allowing you to install and manage specific versions without system-wide side effects.

## Alternative to Container Overhead

While containers provide excellent reproducibility, they introduce virtualization layers and hardware abstraction. LibScript allows for provisioning complex, reproducible environments directly on the native host operating system. conversely, if containerization is required, the `package_as` engine can automatically generate `Dockerfile` and `docker-compose` artifacts.

## Unified Multicloud Interface

Cloud vendors each provide their own CLIs with divergent syntaxes and behaviors. LibScript wraps these official tools into a unified, idempotent interface. Whether you are on AWS, Azure, or GCP, the commands to create a network, a group of nodes, or a storage bucket remain consistent.

## Zero-Dependency Execution

Most configuration managers require heavy language runtimes (Python, Ruby) on the target machine. LibScript avoids this requirement by orchestrating tasks through pure POSIX shell and Windows batch scripts, making it suitable for edge devices, minimalist servers, and "golden image" preparation.

## Automated Cross-Platform Packaging

Creating native installers for multiple OSs traditionally requires learning distinct toolchains (WiX, DEB/RPM scripts, PKG). LibScript uses its internal component model to dynamically compile a single declarative definition into functional installers for Windows, macOS, Linux, and FreeBSD.
