Ideas
=====

This document is not ready for [ROADMAP.md](ROADMAP.md); but a place for looser ideation.

Think about [dokku](https://dokku.com) and other [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service)' and what they have.

For example:

- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) project
- Healthcheck (status-check) project
  - This could be built by adding a `test.sh` to each `port'.
  - Example: [`_lib/_storage/postgres/test.sh`](_lib/_storage/postgres/test.sh)
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

Finally, because network isolation isn't builtin, maybe some dry-run checks like:
- Port availability
- Socket availability
- Database name availability
  - E.g., with PostgreSQL you can have multiple databases made with `CREATE DATABSE`|`createdb`. So rather than error naïvely that port `5432` is in use, try and create a database and only error if port `5432` is in use and database already exists. 
