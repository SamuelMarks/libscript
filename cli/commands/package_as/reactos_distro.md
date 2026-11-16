# Package As: `reactos-distro`

Synthesizes and packages declarative **ReactOS** distribution profiles (`profiles/reactos/*.json`)
into bootable installation/live ISOs (`iso`), raw disk images (`raw`), QEMU (`qcow2`), Hyper-V /
Azure (`vhd`), VMware (`vmdk`), and Vagrant (`box`) images.

## Usage

```sh
./libscript.sh package-as reactos-distro --format iso --profile profiles/reactos/desktop-classic-i686.json
./libscript.sh package-as reactos-distro --format box --profile profiles/reactos/minimal-headless-i686.json
```
