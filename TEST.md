# Testing Strategy

LibScript relies on a comprehensive testing matrix to ensure reliable cross-platform execution and artifact generation. 

## Cross-Platform Validation

The Continuous Integration (CI) pipeline provisions, installs, and verifies components natively across the following environments:
- Linux (Ubuntu, Debian, Alpine, RHEL/AlmaLinux)
- FreeBSD
- macOS
- Windows (Modern and Legacy MS-DOS environments)

## Artifact Verification

Testing extends beyond native script execution. The CI pipeline actively validates the outputs of the `package_as` generator engine:
- Generated `docker-compose.yml` files and Dockerfiles are linted and built to verify syntactic and functional correctness.
- Native installers (MSI, DEB, RPM, etc.) are compiled and tested in isolated sandboxes to confirm they accurately reflect the declared component schemas.
