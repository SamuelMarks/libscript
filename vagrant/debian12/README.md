debian 12 (bookworm) vagrant image
==================================

## Usage

    vagrant up

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    vagrant ssh -c '${LIBSCRIPT_ROOT_DIR}/_lib/_storage/postgres/setup.sh'
