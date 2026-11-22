# T5 HA Topology Blueprint: `openedx-ha`

## Overview

Turnkey multi-node high-availability topology blueprint for `openedx-ha` orchestrated by
`workloads/constellations/engine.sh` and `workloads/constellations/engine.cmd`. Separates stateful
datastore nodes (`mysql`, `mongodb`, `redis`, `meilisearch`) from stateless LMS/Studio WSGI and
Celery worker nodes.

## Usage

```sh
./workloads/constellations/openedx-ha/cli.sh up
./workloads/constellations/openedx-ha/cli.sh status
./workloads/constellations/openedx-ha/cli.sh destroy
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
