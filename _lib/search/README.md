# Full-Text, Vector & Analytics Search Engines (`_lib/search/`)

## Overview

**Tier Scope**: `T1`

Distributed search, vector retrieval, and log analytics engines (`elasticsearch`, `opensearch`,
`opensearch-dashboards`, `meilisearch`, `typesense`, `solr`, `sonic`).

Each subdirectory in `_lib/search/` is an atomic, self-contained LibScript component governed by its
own `manifest.json` and `vars.schema.json`. Components in `_lib/search/` never cross-source sibling
components directly; instead, they source `T0` helpers from `engine/common/` and are composed upward
by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh elasticsearch --help
./libscript.sh install elasticsearch latest
./_lib/search/elasticsearch/cli.sh test
```

```cmd
.\libscript.cmd elasticsearch --help
.\libscript.cmd install elasticsearch latest
.\_lib\search\elasticsearch\cli.cmd test
```

## Components (7)

<!-- BEGIN_COMPONENTS -->

- [`elasticsearch`](./elasticsearch/README.md) (`T1` — `userland-package`, `service-daemon`):
  Distributed, RESTful search and analytics engine for Open edX legacy search backends.
- [`meilisearch`](./meilisearch/README.md) (`T1` — `userland-package`, `service-daemon`): A
  lightning-fast, ultra-relevant search engine built in Rust.
- [`opensearch`](./opensearch/README.md) (`T1` — `userland-package`, `service-daemon`):
  Community-driven Apache 2.0 distributed search, analytics, and vector database suite.
- [`opensearch-dashboards`](./opensearch-dashboards/README.md) (`T1` — `userland-package`,
  `service-daemon`): Open-source data visualization, search analytics, and observability UI
  dashboard server for OpenSearch.
- [`solr`](./solr/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  enterprise-grade search platform built on Apache Lucene with SolrCloud clustering.
- [`sonic`](./sonic/README.md) (`T1` — `userland-package`, `service-daemon`): Fast, lightweight, and
  schema-less search backend written in Rust as a minimal alternative to heavy search clusters.
- [`typesense`](./typesense/README.md) (`T1` — `userland-package`, `service-daemon`): Lightning-fast
  open-source typo-tolerant search engine optimized for instant sub-50ms search-as-you-type.

<!-- END_COMPONENTS -->
