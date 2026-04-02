# Testing Strategy

LibScript relies on a comprehensive testing matrix to ensure reliable cross-platform execution and artifact generation. A core focus of our testing is ensuring strict functional parity between POSIX and Windows implementations.

## Cross-Platform Parity & Validation

The Continuous Integration (CI) pipeline provisions, installs, and verifies components natively across the following environments:
- **Linux:** Ubuntu, Debian, Alpine, RHEL/AlmaLinux.
- **BSD:** FreeBSD 13/14, OpenBSD.
- **macOS:** Intel and Apple Silicon.
- **Windows:** Native Command Prompt (CMD) and PowerShell environments (Windows 10/11 and Server).

We utilize a suite of parity tests to ensure that `./libscript.sh` and `libscript.cmd` produce identical side effects, directory structures, and environment configurations for any given component or stack.

## Automated Cloud Testing (Combinations Matrix)

To rigorously test component implementations against live environments, the repository includes orchestrated test combination tools:
- `test_combinations.sh` (POSIX)
- `test_combinations.cmd` (Windows Batch)

These tools leverage the `cloud` module's multicloud abstraction to dynamically provision temporary VPCs, Firewalls, and Compute Nodes across **AWS**, **Azure**, and **GCP**.

### Usage
```sh
# Run the test matrix on AWS
./test_combinations.sh --provider aws

# Run the test matrix on Azure (from Windows)
test_combinations.cmd --provider azure

# Run without resource cleanup (useful for debugging failures)
./test_combinations.sh --provider gcp --no-resource-cleanup
```

### Flow & Snapshotting
To prevent cloud provisioning bottlenecks, the matrix operates using rapid snapshots:
1. Provisions a single base node, firewall, and network.
2. Captures a base snapshot (AMI, Azure Image, or GCP Disk Snapshot).
3. Iterates over all declared components.
4. Uses `scp` to upload the LibScript codebase.
5. Executes the `install` and `uninstall` lifecycle commands remotely.
6. Asserts structural integrity and pulls results via `scp-from` as JSON.
7. Executes a hyper-fast `restore` command to scrub the node back to its clean base snapshot before testing the next package.

## Artifact Verification

Testing extends beyond native script execution. The CI pipeline actively validates the outputs of the `package_as` generator engine:
- **Containers:** Generated `docker-compose.yml` files and Dockerfiles are linted and built to verify syntactic and functional correctness.
- **Native Installers:** MSI, DEB, RPM, and PKG installers are compiled and tested in isolated sandboxes to confirm they accurately reflect the declared component schemas.
