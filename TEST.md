Testing instructions
====================

When contributing new `ports' it's important to test on different OSs and distributions.

## Alpine Linux, Debian, Ubuntu

Convenience Docker Images have been setup here https://github.com/SamuelMarks/libscript-docker-images

### Usage
(see repo for how to setup ssh keys or alternative password solution)

[optional] Modify your `~/.ssh/config` with:

    Host alpine321
        HostName 127.0.0.1
        Port 2222
        User root
        PreferredAuthentications publickey
        PubkeyAuthentication yes
        PasswordAuthentication no
        ServerAliveInterval 10
        IdentityFile /tmp/.ssh/id_rsa

Then execute:

    $ docker run --name alpine-server-3-2-1 \
        -p 2222:22 \
        -e USER_PASSWORD='null' \
        -e USER_PUBKEY="$(cat -- /tmp.ssh/id_rsa.pub)" \
        samuelmarks/libscript-docker-images:alpine-3.21
    $ # remove previous ssh host verification with
    $ ssh-keygen -R '[127.0.0.1]:2222'
    $ ssh alpine321 cat /etc/os-release
    NAME="Alpine Linux"
    ID=alpine
    VERSION_ID=3.21.3
    PRETTY_NAME="Alpine Linux v3.21"
    HOME_URL="https://alpinelinux.org/"
    BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"

Now to actually test you can do something like:

    $ export LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-/path/to/libscript}"
    $ rsync -az "${LIBSCRIPT_ROOT_DIR}" alpine321:/opt/repos/
    $ # implicit test
    $ ssh alpine321 '/opt/repos/libscript/_lib/_toolchain/jq/test.sh'
    $ # explicit handwritten test
    $ ssh alpine321 jq --version

### Usage (Windows)
You can essentially follow same steps as above; for `rsync` use the Cygwin version. Alternatively copy files over using `scp` or whatever your preferred approach is.

PuTTy instructions are also available at https://github.com/SamuelMarks/libscript-docker-images

## Windows
(guide coming soon)

## NetBSD; FreeBSD; OpenBSD; SunOS / OpenSolaris / illumos; HP/UX; z/OS
(guide coming soon; hopefully I find an open-source alternative to Vagrant for this!)

## Android

Install Python on your host machine—e.g., using [_lib/_toolchain/python/setup.sh](_lib/_toolchain/python/setup.sh)—then follow the guide here to setup your Android and SDK https://github.com/jb2170/better-adb-sync finishing by running:

    $ python -m pip install BetterADBSync
    $ export LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-/path/to/libscript}"
    $ adbsync push --delete "${LIBSCRIPT_ROOT_DIR}" /sdcard/repos/

Then use [termux](https://termux.dev/en/) to access that directory and execute commands. [scrcpy](https://github.com/Genymobile/scrcpy) is popular to remotely control the screen+keyboard, and [escrcpy](https://github.com/viarotel-org/escrcpy) appears to allow remote execution of scripts (though remains to be tested & checked for security flaws).

Or alternatively the docs say you can edit your .ssh/config with:

    Host sshelper
        Port 2222
        ProxyCommand adb-channel tcp:%p com.arachnoid.sshelper/.SSHelperActivity 1

(though SSHelper seems to be unmaintained and won't work on new Android's)

## iOS
(guide coming soon)
