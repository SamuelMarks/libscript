FreeBSD 14 vagrant image
========================

## Usage

    vagrant up

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    vagrant ssh <<< '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    vagrant ssh <<< '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'

### FreeBSD specific notes

For some reason the -c syntax doesn't work so you have to use `<<<` which limits what host shell you are using.

Also, you need to manually copy files over as the vagrant/hypervisor folder sync feature doesn't work.
For example—assuming you've exported `vagrant ssh-config` and named it `freebsd_14`—run:

    rsync -avz --exclude='**/.vagrant' ~/repos/libscript freebsd_14:/opt/repos/
