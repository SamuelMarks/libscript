# MySQL

**Tier**: `T1` (`_lib/databases/mysql/`) | **Capabilities**: `userland-package`, `service-daemon`

MySQL 8.x relational database management system.

## Usage

Provides `mysql` server and client for database workloads. Open edX uses MySQL 8.x (with `utf8mb4`
collation) as its primary relational store for LMS and CMS data.

```sh
./libscript.sh install mysql
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                       | Default              | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------------- |
| `MYSQL_VERSION`            | Specific version of MySQL to install (e.g. '8.4.11', '8.0.36', 'latest').                                                                         | `8.4.11`             |                  |
| `MYSQL_INSTALL_METHOD`     | Installation method for MySQL ('system', 'libscript_native').                                                                                     | `system`             |                  |
| `MYSQL_PORT`               | TCP port MySQL listens on.                                                                                                                        | `3306`               |                  |
| `MYSQL_ROOT_PASSWORD`      | Root password for MySQL server administration.                                                                                                    | ``                   |                  |
| `MYSQL_DATABASE`           | Initial database to create upon setup (e.g., 'openedx').                                                                                          | `openedx`            |                  |
| `MYSQL_USER`               | Database user account to create and grant permissions.                                                                                            | `openedx`            |                  |
| `MYSQL_PASSWORD`           | Password for the database user account.                                                                                                           | ``                   |                  |
| `MYSQL_DATA_DIR`           | Custom directory where MySQL storage engine databases are kept.                                                                                   | `none`               |                  |
| `MYSQL_REMOTE_URL`         | Connection string or URL for external MySQL host (e.g. 'mysql://user:pass@remote-host:3306/db'). If set, local MySQL installation can be skipped. | `none`               |                  |
| `MYSQL_INSTALL_LOCAL`      | Whether to install and provision a local MySQL database server instance.                                                                          | `true`               |                  |
| `MYSQL_SKIP_LOCAL_INSTALL` | Explicitly bypass local MySQL server setup when utilizing a managed remote database.                                                              | `none`               |                  |
| `MYSQL_CHARACTER_SET`      | Default server and database character set.                                                                                                        | `utf8mb4`            |                  |
| `MYSQL_COLLATION`          | Default server and database collation sequence.                                                                                                   | `utf8mb4_unicode_ci` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
