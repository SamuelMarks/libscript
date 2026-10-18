# Tier 3.5 HA Topology Blueprint: `openedx-ha`

## Overview

Turnkey multi-node high-availability topology blueprint for `openedx-ha` orchestrated by
`topologies/engine.sh` and `topologies/engine.cmd`. Separates stateful datastore nodes
(`mysql`, `mongodb`, `redis`, `meilisearch`) from stateless LMS/Studio WSGI and Celery worker nodes.

## Usage

```sh
./topologies/openedx-ha/cli.sh up
./topologies/openedx-ha/cli.sh status
./topologies/openedx-ha/cli.sh destroy
```
