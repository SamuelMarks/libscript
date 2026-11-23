# Relational, Document, Columnar & Consensus Databases (`_lib/databases/`)

## Overview

**Tier Scope**: `T1`

Transactional SQL, NoSQL document, time-series, analytical OLAP, graph, embedded, and Raft/quorum
datastore engines (`postgres`, `mariadb`, `mysql`, `sqlite`, `duckdb`, `mongodb`, `clickhouse`,
`etcd`, `zookeeper`, `cockroachdb`, `tidb`, `scylladb`, etc.).

Each subdirectory in `_lib/databases/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/databases/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh cassandra --help
./libscript.sh install cassandra latest
./_lib/databases/cassandra/cli.sh test
```

```cmd
.\libscript.cmd cassandra --help
.\libscript.cmd install cassandra latest
.\_lib\databases\cassandra\cli.cmd test
```

## Components (25)

<!-- BEGIN_COMPONENTS -->

- [`cassandra`](./cassandra/README.md) (`T1` — `userland-package`, `service-daemon`): Distributed
  wide-column NoSQL database designed to handle large amounts of data across commodity servers with
  high availability.
- [`clickhouse`](./clickhouse/README.md) (`T1` — `userland-package`, `service-daemon`):
  High-performance column-oriented SQL database management system for online analytical processing
  (OLAP).
- [`cockroachdb`](./cockroachdb/README.md) (`T1` — `userland-package`, `service-daemon`):
  Cloud-native distributed SQL database built for transactional consistency, horizontal scalability,
  and survivability.
- [`couchdb`](./couchdb/README.md) (`T1` — `userland-package`, `service-daemon`): Seamless
  multi-master syncing document database with an intuitive HTTP/JSON API and reliability focus.
- [`duckdb`](./duckdb/README.md) (`T1` — `userland-package`, `sysroot-library`): An in-process SQL
  OLAP database management system.
- [`etcd`](./etcd/README.md) (`T1` — `userland-package`, `service-daemon`): A distributed, reliable
  key-value store for the most critical data of a distributed system.
- [`ferretdb`](./ferretdb/README.md) (`T1` — `userland-package`, `service-daemon`): Truly
  open-source MongoDB alternative proxy backed by PostgreSQL or SQLite storage engines.
- [`firebird`](./firebird/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  relational SQL database management system offering ANSI SQL standard compliance and stored
  procedures.
- [`influxdb`](./influxdb/README.md) (`T1` — `userland-package`, `service-daemon`): Scalable
  datastore purpose-built for metrics, events, and real-time time-series analytics.
- [`lmdb`](./lmdb/README.md) (`T1` — `userland-package`, `sysroot-library`): Symas Lightning
  Memory-Mapped Database ultra-fast, ultra-compact transactional embedded key-value store tools.
- [`mariadb`](./mariadb/README.md) (`T1` — `userland-package`, `service-daemon`): A
  community-developed, commercially supported fork of the MySQL relational database management
  system.
- [`mongodb`](./mongodb/README.md) (`T1` — `userland-package`, `service-daemon`): MongoDB is a
  source-available cross-platform document-oriented database program.
- [`mssql`](./mssql/README.md) (`T1` — `userland-package`, `service-daemon`): Microsoft SQL Server
  relational database engine and sqlcmd command-line management utility.
- [`mysql`](./mysql/README.md) (`T1` — `userland-package`, `service-daemon`): MySQL 8.x relational
  database management system.
- [`neo4j`](./neo4j/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  native graph database platform for connected data and Cypher query workloads.
- [`postgres`](./postgres/README.md) (`T1` — `userland-package`, `service-daemon`): A powerful, open
  source object-relational database system.
- [`questdb`](./questdb/README.md) (`T1` — `userland-package`, `service-daemon`): High-throughput
  open-source time-series database with fast SQL, InfluxDB Line Protocol, and PostgreSQL wire
  support.
- [`rethinkdb`](./rethinkdb/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  distributed JSON database built for real-time changefeeds and reactive web applications.
- [`rocksdb`](./rocksdb/README.md) (`T1` — `userland-package`, `sysroot-library`): Embeddable
  persistent LSM-tree key-value store library and ldb administration CLI tools optimized for fast
  flash storage.
- [`scylladb`](./scylladb/README.md) (`T1` — `userland-package`, `service-daemon`):
  Ultra-low-latency C++ distributed wide-column NoSQL database compatible with Apache Cassandra and
  Amazon DynamoDB.
- [`sqlite`](./sqlite/README.md) (`T1` — `userland-package`, `sysroot-library`): A C-language
  library that implements a small, fast, self-contained, high-reliability, full-featured, SQL
  database engine.
- [`surrealdb`](./surrealdb/README.md) (`T1` — `userland-package`, `service-daemon`): Scalable
  distributed multi-model cloud database supporting relational, document, graph, and vector queries.
- [`tidb`](./tidb/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source distributed
  Hybrid Transactional and Analytical Processing (HTAP) SQL database compatible with MySQL.
- [`timescaledb`](./timescaledb/README.md) (`T1` — `userland-package`, `service-daemon`):
  Open-source time-series SQL database extension and tuning toolkit engineered on PostgreSQL.
- [`zookeeper`](./zookeeper/README.md) (`T1` — `userland-package`, `service-daemon`): Centralized
  service for maintaining configuration information, naming, distributed synchronization, and quorum
  leader election.

<!-- END_COMPONENTS -->
