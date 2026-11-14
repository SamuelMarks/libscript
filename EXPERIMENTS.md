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

---

## 4. Multi-Suite SIGPLAN Empirical Evaluation (`--suite=libtpu|edgcpp|manifest`)

Beyond Bento Vagrant OS matrices, LibScript's experiment runner provides a zero-dependency
statistical, provenance, and LaTeX macro synthesis substrate (`_lib/_common/experiment_harness.sh`
and `.cmd`, governed by `experiment-suite.schema.json`) enforcing SIGPLAN empirical evaluation
invariants (`RULE-1` through `RULE-7`):

- **`RULE-1` (Single-Source Provenance & LaTeX Emission):** Every `results/*.json` records exact
  40-hex `git_commit_sha`, clean worktree verification, and `host_manifest_ref`; Suite `E8`
  mechanically emits `results/generated_metrics.tex` and rejects unresolved `\tbd` / `???` tokens.
- **`RULE-2` (Native ISA Guard — Zero Rosetta/QEMU Timing):** Rejects Rosetta 2
  (`sysctl.proc_translated=1`), QEMU user/TCG emulation, and WoW64 translation during native timing.
- **`RULE-3` & `RULE-4` (Cold vs. Warm Subprocesses & Non-Parametric Dispersion):** Separates cold
  runs (`drop_caches` / cold binary copy) from warm loops ($W \ge 10$ warmups + $N \ge 200$ fresh
  subprocesses), recording full `samples_ns` arrays alongside sorted median (`P50`), `IQR`
  (`P75 - P25`), `P99`, and `min`/`max`.
- **`RULE-5` (OS-Normalized `ru_maxrss`):** Normalizes `Darwin`/`Windows_NT` bytes vs. `Linux` KiB
  ($\times 1024$) into binary MiB ($2^{20}$ bytes) and records empty-C11 baseline RSS subtraction.
- **`RULE-6` & `RULE-7` (Pinned Release Profiles & Prerequisite Gates):** Pins Cargo/C11 release
  flags + deterministic `llvm-strip --strip-unneeded` / `strip -x`, and gates suites on codebase
  readiness predicates.

### POSIX (`/bin/sh`) & Windows Batch (`.cmd`) Dual-ISA Campaign Examples

```sh
# 1. Remote bare-metal/dedicated Linux x86_64 campaign (E0-E8) + host pull
./libscript.sh experiment libtpu_campaign --suite=libtpu --host-arch=linux_x64 \
  --provider=azure --size="160-vCPU Standard_D160ads_v7" \
  --subsuites=E0,E1,E2,E3,E4,E5,E6,E7,E8 --warmup=10 --trials=200 \
  --repo-dir=../libtpu-rs --paper-dir=../new_research/libtpu_paper

# 2. Local native macOS arm64 execution into consolidated results directory + PDF audit
./libscript.sh libtpu-rs experiments --host-arch=macos_arm64 \
  --subsuites=E0,E2,E4,E8 --warmup=10 --trials=200 \
  --results-dir=./build/experiment_results/results \
  --paper-dir=../new_research/libtpu_paper --build-pdf
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd experiment libtpu_campaign --suite=libtpu --host-arch=linux_x64 --warmup=10 --trials=200
.\libscript.cmd libtpu-rs experiments --subsuites=E0,E1,E2,E5,E6,E7,E8 --results-dir=.\build\libtpu_results
```

---

## 5. `win_port` 14-Repository Ecosystem, 5-OS + MS-DOS Matrix & 285-Macro Protocol (`--suite=win_port`)

LibScript natively orchestrates the 14-repository `win_port` empirical campaign (`E0`–`E7`, governed
by `_lib/toolchains/win-port-suite/win_port.suite.json`), enforcing:

- **Phase 0 Remediation & Pinned Lockfiles (`E0`):** Verifies `manifests/c_upstreams.lock.json` (9 C
  codebases including `jq 1.8.2` + extracted `Oniguruma 6.9.9`) and the 82-repository
  `manifests/batch_wild_corpus.lock.json`, plus `cdd-c` strict C89 prologue hoisting,
  `AUTO_WIN_MSVC_USE_CDD_C`, `win-cmd-rs` Packrat `PegRuleKey` memoization, and `msi-rs` affine
  `Drop` rollback guards.
- **Unconfounded Emulation & Validation Parity (`E3` & `E4`):** Separates `msi-rs light` (105 ICEs),
  `light -sval` (0 ICEs matched to `wixl`), standalone `smoke` (105 ICEs), `.NET 8 wix`, and
  `darice.cub` validation; measures warm persistent `wineserver -p` vs. cold `wineserver -k` on both
  `Linux_x86_64` and `Darwin_arm64`; separates WSL2 in-VM loopback from cross-boundary TCP and
  `wsl.exe` spawn latency; and runs 32-bit MS-DOS (`msdos-1.25`, `msdos-2.0`, `msdos-4.0`,
  `freedos-1.4`) `CTest` suites over Vagrant `COM1` (`DOS32A.EXE` + OpenWatcom `wcl386`).
- **285-Placeholder Dual-Manuscript Synthesis (`E7`):** Emits `generated_metrics.tex` and verifies
  **0** remaining `\tbd{???}` placeholders across both `win_port_paper.tex` (`283` sites, $\le 20$
  pages) and `win_port_appendix.tex` (`2` sites).

```sh
# POSIX /bin/sh: Local or multi-host win_port campaign + dual-PDF verification
./libscript.sh win-port-suite experiments --subsuites=E0,E1,E2,E4,E5,E6,E7 \
  --host-arch=macos_arm64 --ecosystem-dir=.. --paper-dir=../new_research/win_port --build-pdf

./libscript.sh experiment win_port_campaign --suite=win_port --host-arch=windows_x64 \
  --subsuites=E1B,E3,E4A,E4C,E5B --ecosystem-dir=.. --paper-dir=../new_research/win_port
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd win-port-suite experiments --subsuites=E1B,E3,E4A,E4C,E5B --host-arch=windows_x64
.\libscript.cmd experiment win_port_campaign --suite=win_port --host-arch=windows_x64
```

---

## 6. EDG C/C++ v7.0.1 Multi-Backend Evaluation & 60-Placeholder Protocol (`--suite=edgcpp_backends`)

LibScript natively orchestrates the zero-hallucination **EDG C/C++ Multi-Backend Protocol**
(`E0`–`E7`, governed by `_lib/toolchains/edgcpp-backends-suite/edgcpp_backends.suite.json`),
evaluating `EDG-FE-ONLY`, `EDG-LLVM` (`llvm_gen_be`), `EDG-GCC` (`gcc_gen_be` / `libgccjit`),
`EDG-C-LEGACY` (`c_gen_be`), `EDG-CPP-LEGACY` (`cp_gen_be`), `NATIVE-CLANG`, and `NATIVE-GCC`:

- **Phase 0 Gates, Coverage & Bug #4 Ablation (`E0`):** Verifies all 6 pre-benchmark fixes in
  `edgcpp-compiler-multibackend` (Itanium §2.9.5 `__vmi_class_type_info::__flags`, deterministic
  `_Z_coro_frame_%lu_%s` + HALO soundness, clean `aarch64-apple-darwin` `DataLayout`, external
  `> 16B` AAPCS64 `declare` lowering, `-O0` `i1` branch lowering, and dynamic `realloc`
  `deferred_structs` + bitfield RMW), runs CTest & 4-mode CMake builds, extracts disaggregated
  `llvm-cov` and `gcov`/`lcov` coverage (`exp0_coverage.json`), and times the `sqlite3.c`
  array-decay pathology fix (`exp0_bug4_ablation.json`).
- **Matched-Opt Compile/Runtime, EH, Coroutines, psABI/Differential Fuzzing & Kernel Sweep
  (`E1`–`E6`):** Enforces matched optimization flags (`-O0` vs. `-O0`, `-O2` vs. `-O2`),
  same-LLVM/same-GCC baseline alignment, two-stage `.int.c`/`.int.cpp` accounting, 15-way SQLite
  SHA-256 SQL correctness + TBAA/ThinLTO/IR-PGO ablations (`E2`), DCE-proof C++ EH unwinding (`E3`)
  and C++20 coroutine HALO/ASan gates (`E4`), 1,000-signature Split-TU psABI + GCC Torture +
  Csmith/YARPGen differential campaigns (`E5`), and multi-TU open-source + authentic Linux kernel
  `compile_commands.json` sweeps (`E6`).
- **60-Placeholder Automated LaTeX Synthesis (`E7`):** Verifies single-SHA provenance across all 13
  `results/raw/*.json` files, emits `generated_metrics.tex`, asserts zero remaining `\tbd` or `???`
  tokens in `edgecpp_backends.tex`, and audits PDF compilation via `_lib/toolchains/texlive`.

```sh
# POSIX /bin/sh: Local or multi-host edgcpp_backends campaign + PDF verification
./libscript.sh edgcpp-backends-suite experiments --subsuites=E0,E1,E2,E3,E4,E5,E6,E7 \
  --repo=/Volumes/external_repos/edgcpp-compiler-multibackend \
  --paper-dir=../new_research/edgcpp_backends --build-pdf

./libscript.sh experiment edgcpp_backends_campaign --suite=edgcpp_backends \
  --host-arch=linux_x64 --subsuites=E0,E5,E6,E7 --paper-dir=../new_research/edgcpp_backends
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd edgcpp-backends-suite experiments --subsuites=E0,E1,E2,E3,E4,E5 --host-arch=windows_x64
.\libscript.cmd experiment edgcpp_backends_campaign --suite=edgcpp_backends --host-arch=windows_x64
```
