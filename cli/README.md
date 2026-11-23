# LibScript CLI Router & Command Subsystems (`cli/`)

## Overview

`cli/` implements the modular command-line subcommands invoked by the root `libscript.sh` and
`libscript.cmd` entry points for catalog discovery, semantic version resolution, workspace pin
evaluation, declarative dependency installation, OS profile configuration, and new component
scaffolding.

Domain-specific tier operations are dispatched directly from `libscript.{sh,cmd}` to their owning
tier or orthogonal plane routers:

- **`T1` / `T2` Component Verbs (`install`, `uninstall`, `use`, `ls`, `ls-remote`, `which`, `env`,
  `test`)**: Routed to `_lib/<category>/<component>/cli.{sh,cmd}` (backed by `engine/common/cli.*`).
- **`T3` Synthesis & Packaging (`package-as`, `hydrate-cache`)**: Routed to
  `synthesis/cli.{sh,cmd}`.
- **`T4` Infrastructure & Clusters (`infrastructure`, `provision`, `deprovision`, `cluster`,
  `import-image`, `publish-marketplace`)**: Routed to `infrastructure/cli.{sh,cmd}`.
- **`T5` Workloads, Stacks & Constellations (`workload`, `payload`, `constellation`, `deploy`,
  `deploy-remote`, `start`, `stop`, `restart`, `status`, `health`, `logs`, `up`, `down`, `train-ml`,
  `serve-ml`, `eval-ml`, `benchmark-ml`)**: Routed to `workloads/cli.{sh,cmd}`,
  `workloads/engine.{sh,cmd}`, `workloads/constellations/engine.{sh,cmd}`, and
  `workloads/services/`.
- **`Plane A` Traits (`trait`)**: Routed to `traits/engine.{sh,cmd}`.
- **`Plane B` Experiments (`experiment`, `rapid-experiment`)**: Routed to
  `experiments/engine.{sh,cmd}` and `experiments/cli/rapid_experiment.{sh,cmd}`.

## Structure

- [`commands/config/`](./commands/config/README.md): Interactive TUI & declarative OS synthesis
  profile configurator (`libscript config os`, `tui_engine.*`, `validate_lfs_profile.*`).
- [`commands/core/`](./commands/core/README.md): Component discovery (`list`, `search`), global
  framework version (`version`), and semantic version comparison (`semver`).
- [`commands/deps/`](./commands/deps/README.md): Declarative stack dependency installation
  (`install-deps`) and parallel checksummed artifact downloads (`process-downloads`).
- [`commands/registry/`](./commands/registry/README.md): Component catalog indexing, search, and
  metadata refresh (`search`, `update`).
- [`commands/scaffold/`](./commands/scaffold/README.md): Interactive and JSON-driven `T1`/`T2`
  component-package-manager generator (`scaffold` / `new-component`).
- `commands/resolve_env.{sh,cmd}`: Workspace version pin walker resolving `.libscript-version`,
  `libscript.json`, `.nvmrc`, `.node-version`, `.python-version`, and `rust-toolchain.toml` into
  shell `PATH` exports (`libscript resolve-env` / `libscript env`).
