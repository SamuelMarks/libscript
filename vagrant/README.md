vagrant
=======

`Vagrantfile`s primarily used for testing whether libscript works on specific OS+distribution+version+arch.

Each has the same instructions, namely:

## Usage

    vagrant up

## Libscript usage

Then you can use it like any other ssh host, e.g., to install PostgreSQL:

    vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'

### Test

…and to test PostgreSQL:

    vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'

---

So you can run it in a loop, like:

    previous_wd="$(pwd)"
    for dir in *; do
        if [ -f "${dir}"'/Vagrantfile' ]; then
            cd -- "${dir}"

            # then aforementioned vagrant ssh commands
            vagrant up
            vagrant ssh -c '"${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/setup.sh'
            vagrant ssh -c '. "${LIBSCRIPT_ROOT_DIR}"/env.sh && "${LIBSCRIPT_ROOT_DIR}"/_lib/_storage/postgres/test.sh'

            cd -- "${previous_wd}"
        fi
    done

(wrap in a subshell with a `&` at the end to run in parallel)
