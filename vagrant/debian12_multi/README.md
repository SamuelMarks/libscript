debian 12 (bookworm) vagrant image (multi-edition)
==================================================

## Usage

    vagrant up

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'
