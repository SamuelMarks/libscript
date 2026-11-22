# Slurm Workload Manager (`_lib/schedulers/slurm`)

## Overview

Standalone Version Manager for **Slurm Workload Manager** (`slurm`, `sbatch`, `srun`, `squeue`,
`scancel`, `slurmctld`, `slurmd`), orchestrating HPC and distributed AI gang-scheduled jobs.

## Usage

```sh
./libscript.sh ls-remote slurm
./libscript.sh install slurm 24.05.3
./libscript.sh use slurm 24.05.3
./libscript.sh start slurm
./libscript.sh status slurm
./libscript.sh test slurm
./libscript.sh stop slurm
./libscript.sh uninstall slurm 24.05.3
```

```cmd
libscript.cmd install slurm 24.05.3
libscript.cmd start slurm
libscript.cmd status slurm
libscript.cmd test slurm
```

## Configuration

| Variable               | Description                                            | Default            |
| :--------------------- | :----------------------------------------------------- | :----------------- |
| `SLURM_VERSION`        | Specific version of Slurm to install.                  | `24.05.3`          |
| `SLURM_INSTALL_METHOD` | How to install Slurm (`libscript_native` or `system`). | `libscript_native` |
| `SLURM_CTLD_PORT`      | Slurm controller (`slurmctld`) TCP port.               | `6817`             |
| `SLURM_D_PORT`         | Slurm compute node (`slurmd`) TCP port.                | `6818`             |
| `SLURM_STATE_DIR`      | Job state and spool directory.                         | `/var/spool/slurm` |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                               | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SLURM_VERSION`        | Specific version of Slurm Workload Manager to install.                                                    | `24.05.3`          | latest, stable   |
| `SLURM_INSTALL_METHOD` | How to install Slurm ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages). | `libscript_native` |                  |
| `SLURM_CTLD_PORT`      | TCP port on which the Slurm controller daemon (slurmctld) listens.                                        | `6817`             |                  |
| `SLURM_D_PORT`         | TCP port on which the Slurm compute node daemon (slurmd) listens.                                         | `6818`             |                  |
| `SLURM_STATE_DIR`      | Filesystem directory path for Slurm controller job state and spool files.                                 | `/var/spool/slurm` |                  |
| `SLURM_HOME`           | Filesystem directory or path configuration for slurm (SLURM_HOME).                                        | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
