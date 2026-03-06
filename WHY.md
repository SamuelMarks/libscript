# Project Motivation

LibScript was developed to address the complexity and overhead often associated with modern configuration management and containerization tools.

## Alternative to Container Overhead

While containers provide excellent reproducibility, they abstract away host hardware and introduce virtualization layers. LibScript offers a way to provision complex, reproducible environments directly on the native host operating system. Conversely, its `package_as` feature allows users to translate native definitions into `Dockerfile` and `docker-compose` artifacts when containerization is preferred.

## Zero-Dependency Execution

Traditional configuration managers require the installation of heavy language runtimes (like Python or Ruby) on target machines. LibScript avoids this requirement entirely by orchestrating tasks through POSIX shell and Windows batch scripts, making it suitable for edge devices and minimalist environments.

## Automated Installer Compilation

Packaging software for multiple operating systems traditionally requires learning distinct toolchains (WiX for Windows, Debian packaging scripts for Linux, etc.). By maintaining a typed schema of component dependencies, LibScript can dynamically generate functional installers for Windows, macOS, Linux, and FreeBSD from a single declarative definition.
