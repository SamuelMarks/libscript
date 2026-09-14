# Testing Strategy

LibScript relies on a comprehensive testing matrix to ensure reliable cross-platform execution and
artifact generation. A core focus of our testing is ensuring strict functional parity between POSIX
and Windows implementations.

## Cross-Platform Parity & Validation

The Continuous Integration (CI) pipeline provisions, installs, and verifies components natively
across the following environments:

- **Linux:** Ubuntu, Debian, Alpine, RHEL/AlmaLinux.
- **BSD:** FreeBSD 13/14, OpenBSD.
- **macOS:** Intel and Apple Silicon.
- **Windows:** Native Command Prompt (CMD) and PowerShell environments (Windows 10/11 and Server).

We utilize a suite of parity tests to ensure that `./libscript.sh` and `libscript.cmd` produce
identical side effects, directory structures, and environment configurations for any given component
or stack.

## Automated Cloud Testing (Combinations Matrix)

To rigorously test component implementations against live environments, the repository includes
orchestrated test combination tools:

- `test_combinations.sh` (POSIX)
- `test_combinations.cmd` (Windows Batch)

These tools leverage the `cloud` module's multicloud abstraction to dynamically provision temporary
VPCs, Firewalls (using native NSGs), and Compute Nodes across **AWS**, **Azure**, and **GCP**.

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
7. Executes a hyper-fast `restore` command to scrub the node back to its clean base snapshot before
   testing the next package.

### Machine Learning Infrastructure

Because TPU and GPU provisioning require specific quotas, ML and hardware-accelerated stacks (such
as `tpu-vm-vllm` or `gke-xpk-inference`) use mocked dry-runs during standard CI validation. Set
`E2E_CLOUD=1` to trigger actual cloud quota usage on supported GCP projects.

## Local Testing (Vagrant)

For isolated local testing across different operating systems, LibScript provides predefined Vagrant
environments (located in the `vagrant/` directory). This is highly useful for validating
cross-platform compatibility and verifying component behavior without relying on cloud
infrastructure.

### Vagrant Environments

The repository contains several Vagrant configurations representing our target platforms (e.g.,
Debian 13, Alpine 3.24, FreeBSD 15.1, Windows 11).

Building the underlying boxes (`bento/windows-11`, `bento/alpine-3.24`, `bento/debian-13`,
`bento/freebsd-15.1`) requires the custom Bento fork at
[https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
(`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`), supporting builds on
macOS Apple Silicon (`aarch64`) and other `x86_64` hosts. See [VAGRANT.md](VAGRANT.md) for full box
building instructions.

You can orchestrate these environments using the main `libscript` tool:

```sh
# Provision the Vagrant environment
libscript install vagrant

# Start the Vagrant environment
libscript start vagrant
```

Alternatively, you can manually navigate to specific platform folders (e.g., `vagrant/debian-12/`)
and run `vagrant up`.

### Component Execution over SSH

Once a Vagrant box is running, you can execute component scripts natively within the isolated VM
over SSH. For example, to install and test PostgreSQL:

```sh
# Run the component setup script
vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/setup.sh'

# Source the generated environment block and run tests
vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/databases/postgres/test.sh'
```

### Batch Matrix Testing

To validate your changes across multiple distributions simultaneously, you can iterate over the
Vagrant environments locally. Wrapping the `vagrant ssh` executions in parallel subshells allows you
to mimic a fast CI loop on your local machine.

### Testing Installation Heuristics

Vagrant VMs are ideal for testing dependency management behaviors. You can inject environment
variables (e.g., `LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"` or local overrides like
`PYTHON_INSTALL_METHOD="uv"`) over SSH to verify that fallback resolution paths, system package
managers, and source compilation scripts act exactly as expected on varied Linux and BSD
distributions.

### Automated Local Integration Testing

LibScript includes a dedicated harness for running fully automated local end-to-end integration
tests using Vagrant. Currently, we have validated almost every package to build and test
successfully against Alpine Linux. The test scripts (`tests/run_local_tests.sh` and
`tests/run_local_tests.cmd`) iterate over package categories (or specific targets) and execute a
provisioned VM test loop (defaulting to Alpine Linux via `vagrant/alpine-3.24/Vagrantfile`, with
support for other targets like `debian-13` via the `--os` flag).

**Running the Test Suite**

You can run the tests for specific categories, individual packages, or the entire repository.

For POSIX (Linux/macOS):

```sh
# Run tests for default categories (databases, languages, toolchains)
./tests/run_local_tests.sh

# Run tests for specific packages
./tests/run_local_tests.sh postgres redis

# Run tests for all packages
./tests/run_local_tests.sh all
```

For Windows:

```cmd
:: Run tests for default categories (databases, languages, toolchains)
.\tests\run_local_tests.cmd

:: Run tests for specific packages
.\tests\run_local_tests.cmd postgres redis

:: Run tests for all packages
.\tests\run_local_tests.cmd all
```

**What the test does under the hood:**

For each target package:

1. **Isolation:** A unique temporary directory (`tests_tmp/runs/<target>`) is created, and the
   Vagrantfile is copied there. The Vagrantfile dynamically names the VM (e.g.,
   `bento/alpine-<target>`) to ensure complete, container-like isolation at the hypervisor
   level—much like building a fresh Docker image.
2. **Provisioning:** Vagrant boots this isolated Alpine 3.24 virtual machine.
3. **Synchronization:** The local LibScript repository is mapped into the guest OS
   (`/opt/repos/libscript`) via `rsync`.
4. **Execution & Validation:** An inline shell provisioner automatically executes
   `./libscript.sh install <target>` followed by `./libscript.sh test <target>` directly within the
   VM.
5. **Cleanup:** The VM is automatically destroyed after the test concludes (whether successful or
   not) to prepare for the next package.

**Debugging Failures**

During execution, test logs and results are not printed directly to the console to prevent noise.
Instead, they are routed to the `tests_tmp/` directory at the repository root.

If a test fails (e.g., outputs `[FAILED] postgres`), you can inspect the corresponding log files to
diagnose the problem:

```sh
# View standard output of the failed installation/test
cat tests_tmp/postgres.linux.alpine.stdout

# View error output (standard error)
cat tests_tmp/postgres.linux.alpine.stderr
```

When iterating on a fix for a test failure, it is often faster to temporarily comment out the
`vagrant destroy -f` lines in `tests/run_local_tests.sh` (or `.cmd`). This leaves the isolated VM
running after a failure, allowing you to `cd tests_tmp/runs/<target> && vagrant ssh` into the box
and run the failing install or test commands manually.

## Native Host Testing

For direct, high-performance testing without virtual machine overhead, LibScript provides native
test runners for both POSIX systems and Windows:

- `tests/run_native_tests.sh` (POSIX `/bin/sh`)
- `tests/run_native_tests.cmd` (Windows Command Prompt)
- `tests/run_native_tests.ps1` (PowerShell wrapper)

These runners execute directly on host systems, CI runners, or containerized environments. They
inspect component manifests for OS compatibility (`os_whitelist` and `os_blacklist`), execute the
native `./libscript.sh install` / `libscript.cmd install` and `./libscript.sh test` /
`libscript.cmd test` lifecycle, and capture execution artifacts into `tests_tmp/`.

### Native Testing Usage

POSIX (`/bin/sh`):

```sh
# Test specific components
./tests/run_native_tests.sh sqlite curl

# Test by category
./tests/run_native_tests.sh --category databases

# Run dry-run simulation
./tests/run_native_tests.sh --dry-run sqlite
```

Windows (`cmd.exe`):

```cmd
:: Test specific components
call tests\run_native_tests.cmd sqlite curl

:: Test by category
call tests\run_native_tests.cmd --category databases

:: Run dry-run simulation
call tests\run_native_tests.cmd --dry-run sqlite
```

## Central Results Reporting

All test runners output marker files into `tests_tmp/`:

- `<component>.<os_tag>.success`: Component passed install and test lifecycle
- `<component>.<os_tag>.failure`: Component failed either install or test

The `tests/update_results.sh` (POSIX) and `tests/update_results.cmd` (Windows) scripts scan these
markers and update the root `README.md` compatibility matrix:

| Status Badge | Meaning                                                     |
| ------------ | ----------------------------------------------------------- |
| `✅`         | Passed integration and verification tests                   |
| `❌`         | Failed installation or verification test                    |
| `❓`         | Untested on this platform                                   |
| `-`          | Explicitly blacklisted or unsupported in component manifest |

You can also export matrix results as structured JSON:

```sh
./tests/update_results.sh --json tests_tmp/matrix_results.json
```

## Multi-Platform Continuous Integration Matrix

The `.github/workflows/multiplatform_tests.yml` workflow orchestrates parallel CI validation across
our primary operating system targets:

1. **Alpine Linux (`test-alpine`):** Executes in an Alpine 3.21 container.
2. **Debian Linux (`test-debian`):** Executes on native Ubuntu/Debian runner.
3. **FreeBSD (`test-freebsd`):** Executes inside a FreeBSD 14 virtual machine via
   `vmactions/freebsd-vm`.
4. **Windows (`test-windows`):** Executes on `windows-latest` via Windows Command Prompt.
5. **Aggregate & Report (`aggregate-and-report`):** Downloads test artifacts from all platform jobs,
   runs `./tests/update_results.sh` to update `README.md`, verifies the diff, and outputs the
   aggregate matrix to the GitHub Actions Job Summary.

## Artifact Verification

Testing extends beyond native script execution. The CI pipeline actively validates the outputs of
the `package-as` generator engine:

- **Containers:** Generated `docker-compose.yml` files and Dockerfiles are linted and built to
  verify syntactic and functional correctness.
- **Native Installers:** MSI, DEB, RPM, and PKG installers are compiled and tested in isolated
  sandboxes to confirm they accurately reflect the declared component schemas.
