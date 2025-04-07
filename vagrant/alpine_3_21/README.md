alpine 3.21 vagrant image
=========================

## Build .box file

    $ cd /some_dir
    $ git clone --depth=1 --branch='3.21' --single-branch https://github.com/SamuelMarks/alpine-packer
    $ cd alpine-packer
    $ packer build -var-file=alpine-standard/alpine-standard-3.21.3-aarch64.pkrvars.hcl vmware-iso-aarch64.pkr.hcl
    $ vagrant box add alpine-standard-3.21.3 --provider vmware_fusion file:////some_dir/alpine-packer/output-alpine-standard-3.21.3-aarch64.box

## Usage

`cd` to same folder as this `README.md`, then run:

    $ vagrant up

## Copy files over (shared folders aren't working)

    $ vagrant ssh-config > ssh_config
    $ rsync -avH -e "ssh -F ./ssh_config" default:/opt/repos/libscript ../../gen

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    $ vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    $ vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'
