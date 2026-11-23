# Plane B Experiment CLI & Rapid Cloud Harness (`experiments/cli/`)

## Overview

`experiments/cli/` provides the command-line subcommands, cloud benchmark orchestrator, and plugin
scaffolder backing `./libscript.sh experiment` (`experiments/engine.{sh,cmd}`) and
`./libscript.sh rapid-experiment`.

## Modules

- **`cli.{sh,cmd}`**: Parses global experiment flags, environment overrides, and subsuite selectors.
- **`scaffold.{sh,cmd}`**: Scaffolds new Open/Closed experiment plugins (`experiments/<suite-id>/`)
  conforming to `experiments/schemas/experiment-suite.schema.json`, including zero-code
  `--template=installer-e2e` cross-OS package & UI verification suites.
- **`experiment_cloud.{sh,cmd}`**: Automates ephemeral cloud VM / TPU / bare-metal provisioning,
  remote benchmark execution, artifact collection, and guaranteed teardown.
- **`rapid_experiment.{sh,cmd}`**: Fast local/Vagrant/Docker iterative experiment runner invoked via
  `./libscript.sh rapid-experiment`.

## Usage

```sh
./libscript.sh experiment list
./libscript.sh experiment validate
./libscript.sh experiment scaffold my-study
./libscript.sh experiment scaffold wordpress --template=installer-e2e
./libscript.sh rapid-experiment --help
```

```cmd
.\libscript.cmd experiment list
.\libscript.cmd experiment validate
.\libscript.cmd experiment scaffold my-study
```
