# Rapid Cloud & Bento Multi-OS Vagrant Experimentation Guide (`EXPERIMENTS.md`)

LibScript provides a unified, idempotent **Experiment-Runner Abstraction**
(`./libscript.sh experiment` on POSIX `/bin/sh` and `.\libscript.cmd experiment` on Windows Batch)
that links cloud compute provisioning with the multi-OS Bento Vagrant component matrix and compiler
benchmark suites.

By decoupling **`a_provision_instance`** (`provision_instance`) from **`i_deprovision_instance`**
(`deprovision_instance`), you can provision a high-core-count experiment host once, run experiments
across one or many target operating systems, component versions, and package managers
(`b_use_bento_fork` through `h_pull_logs`), stream logs back to your host after each run, and
deprovision only when finished.

---

## 1. Architecture & Named Lifecycle Phases (`a_provision_instance` .. `i_deprovision_instance`)

All steps are named and ordered lexicographically (`a_...` through `i_...`) and can be invoked
either with their lexicographical prefix (`a_provision_instance`) or their unprefixed descriptive
name (`provision_instance`):

```text
+==========================================================================================+
|              LIBSCRIPT UNIFIED RAPID EXPERIMENT-RUNNER ABSTRACTION                       |
|               (./libscript.sh experiment  |  .\libscript.cmd experiment)                 |
+==========================================================================================+
                                             |
     +---------------------------------------+---------------------------------------+
     | [a_provision_instance] (provision_instance)                                   |
     |     - Provisions cloud/experiment node (default: Standard_D160ads_v7)         |
     |     - Waits for SSH readiness & syncs LibScript repo                          |
     |     - Decoupled from [i_deprovision_instance] for multi-OS runs               |
     +---------------------------------------+---------------------------------------+
                                             |
                                             v
  +-------------------------------------------------------------------------------------+
  |                MULTI-OS BENTO VAGRANT MATRIX LOOP (--target-os=<OS>)                |
  |                (Filterable by --component, --version, --pkg-mgr, --toolchain)       |
  |                                                                                     |
  |  [b_use_bento_fork]               -> SamuelMarks/bento @ multi-os-qemu-aarch64      |
  |  [c_install_virtualization_stack] -> vagrant, packer, ruby, qemu, bento-builder     |
  |  [d_deploy_vagrant_box]           -> Register & boot bento/<target_os> VM           |
  |  [e_snapshot_vagrant_box]         -> Save clean baseline 'vanilla' snapshot         |
  |  [f_test_libscript_components]    -> Restore 'vanilla' snapshot + 2x idempotent     |
  |     (or run_experiments)             install & test per component / compiler suite  |
  |  [g_collect_logs]                 -> Consolidate remote logs into 1 bundle dir      |
  |     (move_to_log_dir)                                                               |
  |  [h_pull_logs]                    -> Transfer bundle dir to current host            |
  |     (move_log_dir_to_host / send_logs_to_host)                                      |
  +------------------------------------------+------------------------------------------+
                                             | (Test next --target-os or proceed)
                                             v
     +---------------------------------------+---------------------------------------+
     | [i_deprovision_instance] (deprovision_instance)                               |
     |     - Tears down compute node, VNet, and NSG (_lib/cloud/core/teardown)       |
     |     - Preserves all transferred host logs and transfer-manifest.json          |
     +-------------------------------------------------------------------------------+
```

| Lexicographical Step Name            | Unprefixed / Descriptive Alias                           | Action Performed                                                                                                                                                                       |
| :----------------------------------- | :------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`a_provision_instance`**           | `provision_instance`                                     | Provisions the cloud host (default `160-vCPU Standard_D160ads_v7` on Azure), waits for SSH, and syncs LibScript.                                                                       |
| **`b_use_bento_fork`**               | `use_bento_fork`                                         | Clones/updates `https://github.com/SamuelMarks/bento.git` and checks out branch `multi-os-qemu-aarch64`.                                                                               |
| **`c_install_virtualization_stack`** | `install_virtualization_stack`                           | Installs Vagrant, Packer, Ruby, QEMU, VirtualBox, and ISO tools via LibScript's reusable `_lib/virtualization/bento-builder` stack.                                                    |
| **`d_deploy_vagrant_box`**           | `deploy_vagrant_box`                                     | Registers Bento `.box` images (`tests/register_bento_boxes.{sh,cmd}`) and boots `vagrant/<target_os>`.                                                                                 |
| **`e_snapshot_vagrant_box`**         | `snapshot_vagrant_box`                                   | Captures an idempotent clean baseline snapshot (`vanilla`) of the target OS Vagrant VM.                                                                                                |
| **`f_test_libscript_components`**    | `test_libscript_components`, `run_experiments`           | Runs every component (or filtered `--component`, `--version`, `--pkg-mgr`), restoring the `vanilla` snapshot before each component and running **twice (`2x`)** to verify idempotency. |
| **`g_collect_logs`**                 | `collect_logs`, `move_to_log_dir`                        | Consolidates remote `tests_tmp/` and experiment reports into one remote bundle directory (`~/libscript/build/experiment_bundle`).                                                      |
| **`h_pull_logs`**                    | `pull_logs`, `move_log_dir_to_host`, `send_logs_to_host` | Transfers the consolidated bundle directory from the remote host to `build/experiment_results/` on the current host.                                                                   |
| **`i_deprovision_instance`**         | `deprovision_instance`                                   | Tears down the cloud instance and network resources while preserving local transferred logs.                                                                                           |
| **`bento_matrix`**                   | `os_matrix`                                              | Composite alias for `b_use_bento_fork` through `h_pull_logs` (runs an OS experiment without provisioning or deprovisioning).                                                           |
| **`all`**                            | `full_bento_matrix`                                      | Runs the complete lifecycle (`a_provision_instance` through `i_deprovision_instance`).                                                                                                 |

---

## 2. Parameter Reference

All parameters can be passed as CLI flags or environment variables (documented in
`_lib/cloud/core/vars.schema.json`):

| CLI Flag                                        | Environment Variable                         | Default                                    | Description                                                                                                                                           |
| :---------------------------------------------- | :------------------------------------------- | :----------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--steps=<list>`                                | `CORE_EXPERIMENT_STEPS`                      | `all`                                      | Comma-separated list of named steps (`a_provision_instance,...,i_deprovision_instance`, `bento_matrix`, or unprefixed step names).                    |
| `--target-os=<os>`                              | `CORE_EXPERIMENT_TARGET_OS`                  | `alpine-3.24`                              | Target Vagrant OS (`alpine-3.24`, `debian-13`, `rockylinux-10.2`, `freebsd-15.1`, `omnios`, `windows-11`, `macos-14-arm64`, or comma-separated list). |
| `--component=<comp>` / `--components=<list>`    | `CORE_EXPERIMENT_COMPONENTS`                 | `all`                                      | Component name, category, comma-separated list, or `component@version` shorthand (e.g. `postgres@16.2`, `nodejs`, `databases`).                       |
| `--version=<ver>` / `--component-version=<ver>` | `CORE_EXPERIMENT_COMPONENT_VERSION`          | `latest`                                   | Specific component version to install and test inside the Vagrant VM (e.g. `16.2`, `22.14.0`, `3.46.1`).                                              |
| `--pkg-mgr=<pm>` / `--package-manager=<pm>`     | `CORE_EXPERIMENT_PKG_MGR`                    | `""` (auto)                                | Package manager override (`apt-get`, `apk`, `dnf`, `brew`, `winget`, `choco`, `scoop`, `nix`, `guix`, `spack`, `vcpkg`, `conan`, `pkg`).              |
| `--install-method=<method>`                     | `CORE_EXPERIMENT_INSTALL_METHOD`             | `""` (auto)                                | Installation method override (`libscript_native`, `system`, `from-source`, `nix`, `brew`, `winget`, `choco`, `scoop`, `vcpkg`, `spack`).              |
| `--from-source`                                 | `CORE_EXPERIMENT_INSTALL_METHOD=from-source` | —                                          | Shorthand flag to build the target component from source inside the Vagrant VM.                                                                       |
| `--toolchain=<tc>`                              | `CORE_EXPERIMENT_TOOLCHAIN`                  | `""` (default)                             | Compiler toolchain when building from source (`default`, `gcc`, `clang`, `tcc`, `edgcpp`, `custom-cc`).                                               |
| `--snapshot=<name>`                             | `CORE_EXPERIMENT_SNAPSHOT_NAME`              | `vanilla`                                  | Baseline Vagrant snapshot name created in `e_snapshot_vagrant_box` and restored before each component in `f_test_libscript_components`.               |
| `--idempotency-runs=<N>`                        | `CORE_EXPERIMENT_IDEMPOTENCY_RUNS`           | `2`                                        | Number of consecutive `install` + `test` passes per component after snapshot restore.                                                                 |
| `--bento-repo=<url>`                            | `CORE_EXPERIMENT_BENTO_REPO`                 | `https://github.com/SamuelMarks/bento.git` | Git repository URL for the Bento fork.                                                                                                                |
| `--bento-branch=<branch>`                       | `CORE_EXPERIMENT_BENTO_BRANCH`               | `multi-os-qemu-aarch64`                    | Git branch checked out in the Bento repository.                                                                                                       |
| `--provider=<cloud>`                            | `CORE_EXPERIMENT_PROVIDER`                   | `azure`                                    | Cloud provider (`azure`, `aws`, `gcp`).                                                                                                               |
| `--size=<sku>`                                  | `CORE_EXPERIMENT_SIZE`                       | `160-vCPU Standard_D160ads_v7`             | Cloud VM size / SKU.                                                                                                                                  |
| `--local-dir=<dir>`                             | `CORE_EXPERIMENT_LOCAL_DIR`                  | `build/experiment_results`                 | Local host directory where remote logs and `transfer-manifest.json` are pulled.                                                                       |
| `--dry-run` / `-n`                              | `DRY_RUN=1`                                  | `0`                                        | Simulate cloud/Vagrant execution and state transitions without live cloud billing.                                                                    |

---

## 3. Common Workflows & Examples

### A. Testing One Component-Version & Package-Manager on One OS

To test a single component (e.g., `postgres` version `16.2` via `apt-get` on `debian-13`, or
`sqlite` version `3.46.1` built from source with `edgcpp` on `alpine-3.24`):

```sh
# POSIX /bin/sh: Test postgres 16.2 via apt-get on Debian 13 (using component@version shorthand)
./libscript.sh experiment bento_matrix --target-os=debian-13 --component=postgres@16.2 --pkg-mgr=apt-get

# Or using explicit named steps and --component / --version flags
./libscript.sh experiment --steps=d_deploy_vagrant_box,e_snapshot_vagrant_box,f_test_libscript_components,g_collect_logs,h_pull_logs --target-os=debian-13 --component=postgres --version=16.2 --pkg-mgr=apt-get

# Test sqlite 3.46.1 built from source with the EDG C/C++ frontend on Alpine 3.24
./libscript.sh experiment --steps=f_test_libscript_components,g_collect_logs,h_pull_logs --target-os=alpine-3.24 --component=sqlite --version=3.46.1 --from-source --toolchain=edgcpp
```

```cmd
:: Windows Batch (.cmd): Test postgres 16.2 via apt-get on Debian 13
libscript.cmd experiment bento_matrix --target-os=debian-13 --component=postgres@16.2 --pkg-mgr=apt-get

:: Test nodejs 22.14.0 via winget on Windows 11
libscript.cmd experiment bento_matrix --target-os=windows-11 --component=nodejs --version=22.14.0 --pkg-mgr=winget
```

You can also invoke the underlying local Vagrant runner directly with the same flags:

```sh
# Direct local Vagrant test of a single component-version and package-manager
./tests/run_local_tests.sh postgres --version 16.2 --pkg-mgr apt-get --os debian-13 --reuse-vm

# Windows Batch equivalent
tests\run_local_tests.cmd postgres --version 16.2 --pkg-mgr apt-get --os debian-13 --reuse-vm
```

### B. Testing Multiple OSs Before Deprovisioning (`a_provision_instance` -> `bento_matrix` -> `i_deprovision_instance`)

Because `a_provision_instance` and `i_deprovision_instance` are separated, you can provision the
cloud instance once and test multiple target OSs sequentially before tearing down:

```sh
# Provision the 160-vCPU compute instance once
./libscript.sh experiment a_provision_instance

# Run full LibScript matrix on Alpine 3.24 and pull logs to host
./libscript.sh experiment bento_matrix --target-os=alpine-3.24

# Run full LibScript matrix on Debian 13, Rocky Linux 10.2, and FreeBSD 15.1 (b_use_bento_fork & c_install_virtualization_stack exit early idempotently!)
./libscript.sh experiment bento_matrix --target-os=debian-13
./libscript.sh experiment bento_matrix --target-os=rockylinux-10.2
./libscript.sh experiment bento_matrix --target-os=freebsd-15.1

# Deprovision the compute instance once all OS runs are complete
./libscript.sh experiment i_deprovision_instance
```

### C. Granular Step-by-Step Execution (Lexicographically Ordered Named Steps)

Every step can be executed individually by its lexicographical step name or unprefixed alias:

```sh
./libscript.sh experiment a_provision_instance                              # Provision cloud instance
./libscript.sh experiment b_use_bento_fork                                  # Clone SamuelMarks/bento @ multi-os-qemu-aarch64
./libscript.sh experiment c_install_virtualization_stack                    # Install Vagrant, Packer, Ruby, QEMU, etc.
./libscript.sh experiment d_deploy_vagrant_box --target-os=alpine-3.24      # Deploy target OS as a Vagrant box
./libscript.sh experiment e_snapshot_vagrant_box --target-os=alpine-3.24    # Save clean 'vanilla' snapshot
./libscript.sh experiment f_test_libscript_components --target-os=alpine-3.24 # Test components (snapshot restore + 2x idempotency)
./libscript.sh experiment g_collect_logs --target-os=alpine-3.24            # Consolidate logs into one remote bundle dir
./libscript.sh experiment h_pull_logs --target-os=alpine-3.24               # Pull consolidated log bundle dir to current host
./libscript.sh experiment i_deprovision_instance                            # Deprovision cloud instance
```
