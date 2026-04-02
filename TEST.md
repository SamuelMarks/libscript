# Testing Strategy

LibScript relies on a comprehensive testing matrix to ensure reliable cross-platform execution and artifact generation. A core focus of our testing is ensuring strict functional parity between POSIX and Windows implementations.

## Cross-Platform Parity & Validation

The Continuous Integration (CI) pipeline provisions, installs, and verifies components natively across the following environments:
- **Linux:** Ubuntu, Debian, Alpine, RHEL/AlmaLinux.
- **BSD:** FreeBSD 13/14, OpenBSD.
- **macOS:** Intel and Apple Silicon.
- **Windows:** Native Command Prompt (CMD) and PowerShell environments (Windows 10/11 and Server).

We utilize a suite of parity tests to ensure that `./libscript.sh` and `libscript.cmd` produce identical side effects, directory structures, and environment configurations for any given component or stack.

## Artifact Verification

Testing extends beyond native script execution. The CI pipeline actively validates the outputs of the `package_as` generator engine:
- **Containers:** Generated `docker-compose.yml` files and Dockerfiles are linted and built to verify syntactic and functional correctness.
- **Native Installers:** MSI, DEB, RPM, and PKG installers are compiled and tested in isolated sandboxes to confirm they accurately reflect the declared component schemas.
