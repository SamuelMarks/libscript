# Plane B Experiment Suite JSON Schemas (`experiments/schemas/`)

## Overview

`experiments/schemas/` defines the JSON Schema (Draft 2020-12) contracts governing LibScript's
Open/Closed empirical experiment plugins (`experiments/<suite-id>/`).

## Schemas

- **`experiment-suite.schema.json`**: Core plugin manifest contract (`suite_id`, `substrate`,
  `subsuites`, `metrics`, `artifacts`, `entry_points`) validated by
  `./libscript.sh experiment validate`.
- **`installer-experiment.schema.json`**: Declarative cross-OS native installer (`msi`, `deb`,
  `rpm`, `apk`, `pkg`, `dmg`, `txz`) and guest UI/HTTP verification contract executed by
  `experiments/_common/pkg_ui_runner.{sh,cmd}`.
- **`os-matrix-results.schema.json`**: Structured test & compatibility matrix output contract
  emitted by `experiments/os-component-matrix/` and consumed by `tests/update_results.*`.
