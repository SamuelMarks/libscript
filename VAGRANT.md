# Vagrant Testing & Box Generation

This guide explains how to generate custom Vagrant boxes using a customized fork of Bento, utilize
those boxes within your `Vagrantfile`, and execute LibScript tests across all components.

## 1. Using the Custom Bento Fork

To build local Vagrant boxes for OS distributions like Alpine, Debian, and FreeBSD (especially
useful for QEMU / ARM64 or custom setups), start by cloning the custom fork of Bento:

```bash
git clone -b multi-os-qemu-aarch64 https://github.com/SamuelMarks/bento.git
cd bento
```

## 2. Creating New Images (Boxes)

Bento utilizes HashiCorp's Packer to build Vagrant boxes. Ensure you have
[Packer](https://developer.hashicorp.com/packer/downloads) installed along with the appropriate
virtualization provider (e.g., QEMU).

First, install Ruby dependencies:

```bash
bundle install
```

### Build the Boxes

From the root of the cloned `bento` directory, you can build the boxes using the provided `bento`
CLI wrapper. This builds the Alpine 3.24.1, Debian 13.6, and FreeBSD 15.1 images using QEMU:

```bash
# Alpine Linux 3.24.1 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/alpine/alpine-3.24-aarch64

# Debian Linux 13.6.0 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/debian/debian-13-aarch64

# FreeBSD 15.1 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/freebsd/freebsd-15-aarch64
```

After the build completes, Vagrant `.box` files will be generated in the `builds/build_complete/`
directory. Both a `.qemu.box` and a `.libvirt.box` are produced.

### Adding the Boxes to Vagrant

Import the newly created boxes into your local Vagrant installation so they can be referenced in
your `Vagrantfile`.

The `qemu` provider boxes are fully compatible with `vagrant-qemu` natively, while you can
optionally add the `libvirt` versions if using other environments.

```bash
# Add Alpine 3.24.1
vagrant box add --name bento/alpine-3.24 --provider qemu builds/build_complete/alpine-3.24-aarch64.qemu.box
vagrant box add --name bento/alpine-3.24 --provider libvirt builds/build_complete/alpine-3.24-aarch64.libvirt.box

# Add Debian 13
vagrant box add --name bento/debian-13 --provider qemu builds/build_complete/debian-13.6-aarch64.qemu.box
vagrant box add --name bento/debian-13 --provider libvirt builds/build_complete/debian-13.6-aarch64.libvirt.box

# Add FreeBSD 15.1
vagrant box add --name bento/freebsd-15.1 --provider qemu builds/build_complete/freebsd-15.1-aarch64.qemu.box
vagrant box add --name bento/freebsd-15.1 --provider libvirt builds/build_complete/freebsd-15.1-aarch64.libvirt.box
```

## 3. Using the Boxes in a Vagrantfile

Once the boxes are added, you can instantiate VMs using them. Here is a sample `Vagrantfile` that
mounts the LibScript repository (via `rsync`) and configures the environment:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set repository root via environment variable or default to the current directory
repo_root = ENV['LIBSCRIPT_REPO_ROOT'] || "."

Vagrant.configure("2") do |config|
  config.vm.define "libscript-test-node" do |t|
    # Reference the box you just added
    t.vm.box = "bento/alpine-3.24" # Or "bento/debian-13", or "bento/freebsd-15.1"

    t.vm.provider "qemu" do |qe|
      qe.net_mode = :user
      # Randomize SSH port to prevent collisions during parallel isolated runs
      qe.ssh_port = 50022 + rand(1000)
    end

    t.ssh.insert_key = true
    # Use /bin/sh for Alpine/FreeBSD; use /bin/bash for Debian
    t.ssh.shell = "/bin/sh"

    t.vm.allowed_synced_folder_types = [:rsync]

    # Sync the LibScript repository to /opt/repos/libscript inside the VM
    t.vm.synced_folder repo_root, "/opt/repos/libscript", type: "rsync"
  end
end
```
