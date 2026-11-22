# Elasticsearch

Distributed, RESTful search and analytics engine for Open edX legacy search backends.

## Usage

Provides `elasticsearch` for indexing courseware and libraries. Supported as a legacy alternative to
Meilisearch in Open edX.

```sh
./libscript.sh install elasticsearch
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                       | Description                                                               | Default           | Aliases/Examples |
| ------------------------------ | ------------------------------------------------------------------------- | ----------------- | ---------------- |
| `ELASTICSEARCH_VERSION`        | Version of Elasticsearch to install (e.g. '7.17.21', '8.13.0', 'latest'). | `7.17.21`         |                  |
| `ELASTICSEARCH_INSTALL_METHOD` | How to install Elasticsearch ('system', 'libscript_native').              | `system`          |                  |
| `ELASTICSEARCH_HTTP_PORT`      | HTTP REST port for Elasticsearch.                                         | `9200`            |                  |
| `ELASTICSEARCH_CLUSTER_NAME`   | Cluster name identifier.                                                  | `openedx-cluster` |                  |
| `ELASTICSEARCH_DATA_DIR`       | Directory where index data is stored.                                     | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
