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
Debian, Alpine, AlmaLinux, FreeBSD). You can orchestrate these environments using the main
`libscript` tool:

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

### End-to-End Integration Testing

In addition to interactive component execution over SSH, LibScript uses dedicated Vagrantfiles for
fully automated end-to-end (E2E) integration tests. These files are located in the `tests/vagrant/`
directory and perform comprehensive validation (e.g., installation, service configuration, and
client connection tests).

For example, to run the PostgreSQL E2E test on an Alpine Linux VM:

```sh
# Navigate to the test directory
cd tests/vagrant/linux

# Tell Vagrant to use the specific test file and provision the environment
VAGRANT_VAGRANTFILE=postgres.alpine.linux.Vagrantfile vagrant up
```

**What the test does under the hood:**

1. **Provisioning:** Vagrant boots an Alpine virtual machine.
2. **Synchronization:** The local LibScript repository is mapped into the guest OS
   (`/opt/repos/libscript`) via `rsync`.
3. **Execution:** An inline shell provisioner triggers the native
   `./libscript.sh install postgres 17` and `./libscript.sh restart postgres` commands directly
   within the VM.
4. **Validation:** The provisioner executes a Python script (using `psycopg2`) to connect to the
   newly provisioned database, confirming that LibScript's setup was fully successful, initialized,
   and accepting connections.

After validation completes, you can clean up the temporary environment:

```sh
VAGRANT_VAGRANTFILE=postgres.alpine.linux.Vagrantfile vagrant destroy -f
```

## Artifact Verification

Testing extends beyond native script execution. The CI pipeline actively validates the outputs of
the `package-as` generator engine:

- **Containers:** Generated `docker-compose.yml` files and Dockerfiles are linted and built to
  verify syntactic and functional correctness.
- **Native Installers:** MSI, DEB, RPM, and PKG installers are compiled and tested in isolated
  sandboxes to confirm they accurately reflect the declared component schemas.
