Ideas
=====

This document is not ready for [ROADMAP.md](ROADMAP.md); but a place for looser ideation.

Think about [dokku](https://dokku.com) and other [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service)' and what they have.

For example:

- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) project
- [Healthcheck (status-check)](https://en.wikipedia.org/wiki/Network_monitoring) project
  - This could be built by adding a `test.sh` to each `port'.
  - Example: [`_lib/_storage/postgres/test.sh`](https://github.com/SamuelMarks/libscript/blob/master/_lib/_storage/postgres/test.sh)
- See logs of project
  - `logs -f project_name33`
- Start|stop project
  - `start project_name33`
- Start|stop component of project
  - `stop project_name33 postgresql`

Also; maybe; consider:
- [Multi-user](https://en.wikipedia.org/wiki/Multi-user_software)
- [GitOps](https://about.gitlab.com/topics/gitops/)

This would additionally require every non shared-library / shared-toolchain understand:
- `INSTALL_DIR="${LIBSCRIPT_PROJECT_DIR}"'/'"${project_name}"`
- `HERMETIC_BUILD=1`

Penultimately, because network isolation isn't builtin, maybe some dry-run checks like:
- [Port](https://en.wikipedia.org/wiki/Port_(computer_networking)) availability
- [Socket](https://en.wikipedia.org/wiki/Unix_domain_socket) availability
- Database name availability
  - E.g., with PostgreSQL you can have multiple databases made with `CREATE DATABSE`|`createdb`. So rather than error naïvely that port `5432` is in use, try and create a database and only error if port `5432` is in use and database already exists. 

Finally, there's the whole day-2 operations stuff, like:
- [Backups](https://en.wikipedia.org/wiki/Backup)
  - [Snapshots](https://en.wikipedia.org/wiki/Snapshot_(computer_storage))
  - [Rollbacks](https://en.wikipedia.org/wiki/Rollback_(data_management))
- [Canary deployments](https://en.wikipedia.org/wiki/Feature_toggle#Canary_release)
- Clustered deployments
- [Deployment of clusters](https://en.wikipedia.org/wiki/Computer_cluster)
- Centralised monitoring
- Centralised [logging](https://en.wikipedia.org/wiki/Logging_(computing))
- [Upgrades](https://en.wikipedia.org/wiki/Upgrade)
- [Downgrades](https://en.wikipedia.org/wiki/Downgrade)
