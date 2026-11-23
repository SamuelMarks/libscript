# In-Memory Caches & HTTP Accelerators (`_lib/caches/`)

## Overview

**Tier Scope**: `T1`

Low-latency key-value stores, distributed caches, and reverse-proxy HTTP accelerators (`redis`,
`valkey`, `dragonfly`, `keydb`, `memcached`, `hazelcast`, `varnish`).

Each subdirectory in `_lib/caches/` is an atomic, self-contained LibScript component governed by its
own `manifest.json` and `vars.schema.json`. Components in `_lib/caches/` never cross-source sibling
components directly; instead, they source `T0` helpers from `engine/common/` and are composed upward
by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh dragonfly --help
./libscript.sh install dragonfly latest
./_lib/caches/dragonfly/cli.sh test
```

```cmd
.\libscript.cmd dragonfly --help
.\libscript.cmd install dragonfly latest
.\_lib\caches\dragonfly\cli.cmd test
```

## Components (7)

<!-- BEGIN_COMPONENTS -->

- [`dragonfly`](./dragonfly/README.md) (`T1` — `userland-package`, `service-daemon`): Modern
  shared-nothing multithreaded in-memory data store compatible with Redis and Memcached protocols.
- [`hazelcast`](./hazelcast/README.md) (`T1` — `userland-package`, `service-daemon`): Distributed
  in-memory data grid and real-time stream processing platform.
- [`keydb`](./keydb/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  multithreaded fork of Redis focusing on active-active replication and flash storage.
- [`memcached`](./memcached/README.md) (`T1` — `userland-package`, `service-daemon`):
  High-performance, distributed memory object caching system.
- [`redis`](./redis/README.md) (`T1` — `userland-package`, `service-daemon`): In-memory data
  structure store used as a database, cache, message broker, and streaming engine.
- [`valkey`](./valkey/README.md) (`T1` — `userland-package`, `service-daemon`): A high-performance,
  open-source, in-memory data store that is fully compatible with Redis.
- [`varnish`](./varnish/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  caching HTTP reverse proxy accelerator with flexible VCL policy configuration.

<!-- END_COMPONENTS -->
