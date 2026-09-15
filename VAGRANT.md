# Vagrant Testing & Box Generation

This guide explains how to generate custom Vagrant boxes using a customized fork of Bento, utilize
those boxes within your `Vagrantfile`, and execute LibScript tests across all components.

## 1. Using the Custom Bento Fork

Building the required Vagrant boxes for **Windows** (Windows 11, Windows Server 2025), **Alpine**
(Alpine 3.24), latest **FreeBSD** (FreeBSD 15 / 15.1), latest **Debian** (Debian 13 Trixie), and
**Rocky Linux** (Rocky Linux 10.2) requires the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
- **Branch**: `multi-os-qemu-aarch64` (`https://github.com/SamuelMarks/bento` @ branch
  `multi-os-qemu-aarch64`)
- **Supported Host Platforms**:
  - **macOS Apple Silicon** (`aarch64` / ARM64)
  - **x86_64 other hosts** (Linux, Windows, Intel macOS)

Clone the custom fork at the `multi-os-qemu-aarch64` branch:

```bash
git clone -b multi-os-qemu-aarch64 https://github.com/SamuelMarks/bento.git
cd bento
```

## 2. Creating New Images (Boxes)

Bento utilizes HashiCorp's Packer to build Vagrant boxes. Ensure you have
[Packer](https://developer.hashicorp.com/packer/downloads) installed along with the appropriate
virtualization provider (e.g., QEMU or VirtualBox).

First, install Ruby dependencies:

```bash
bundle install
```

### Build the Boxes

From the root of the cloned `bento` directory, you can build boxes using the provided `bento` CLI
wrapper.

#### On macOS Apple Silicon (`aarch64` Hosts)

Build ARM64 QEMU images natively on Apple Silicon:

```bash
# Windows 11 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/windows/windows-11-aarch64

# Alpine Linux 3.24.1 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/alpine/alpine-3.24-aarch64

# Debian Linux 13.6.0 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/debian/debian-13-aarch64

# FreeBSD 15.1 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/freebsd/freebsd-15-aarch64

# Rocky Linux 10.2 (aarch64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/rockylinux/rockylinux-10.2-aarch64
```

#### On x86_64 Hosts (Linux, Windows, Intel macOS)

Build x86_64 images using QEMU (or VirtualBox):

```bash
# Windows 11 (x86_64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/windows/windows-11-x86_64

# Alpine Linux 3.24.1 (x86_64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/alpine/alpine-3.24-x86_64

# Debian Linux 13.6.0 (x86_64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/debian/debian-13-x86_64

# FreeBSD 15.1 (x86_64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/freebsd/freebsd-15-x86_64

# Rocky Linux 10.2 (x86_64)
bundle exec bin/bento build -o qemu.vm os_pkrvars/rockylinux/rockylinux-10.2-x86_64
```

After the build completes, Vagrant `.box` files will be generated in the `builds/build_complete/`
directory. Both a `.qemu.box` and a `.libvirt.box` are produced for QEMU targets.

### Adding the Boxes to Vagrant

Import the newly created boxes into your local Vagrant installation so they can be referenced in
your `Vagrantfile`.

The `qemu` provider boxes are fully compatible with `vagrant-qemu` natively, while you can
optionally add the `libvirt` versions if using libvirt on Linux.

```bash
# Add Windows 11
vagrant box add --name bento/windows-11 --provider qemu builds/build_complete/windows-11-*.qemu.box
vagrant box add --name bento/windows-11 --provider libvirt builds/build_complete/windows-11-*.libvirt.box

# Add Alpine 3.24
vagrant box add --name bento/alpine-3.24 --provider qemu builds/build_complete/alpine-3.24-*.qemu.box
vagrant box add --name bento/alpine-3.24 --provider libvirt builds/build_complete/alpine-3.24-*.libvirt.box

# Add Debian 13
vagrant box add --name bento/debian-13 --provider qemu builds/build_complete/debian-13.*.qemu.box
vagrant box add --name bento/debian-13 --provider libvirt builds/build_complete/debian-13.*.libvirt.box

# Add FreeBSD 15.1
vagrant box add --name bento/freebsd-15.1 --provider qemu builds/build_complete/freebsd-15.*.qemu.box
vagrant box add --name bento/freebsd-15.1 --provider libvirt builds/build_complete/freebsd-15.*.libvirt.box

# Add Rocky Linux 10.2
vagrant box add --name bento/rockylinux-10.2 --provider qemu builds/build_complete/rockylinux-10.2-*.qemu.box
vagrant box add --name bento/rockylinux-10.2 --provider libvirt builds/build_complete/rockylinux-10.2-*.libvirt.box
```

## 3. Using the Boxes in a Vagrantfile

Once the boxes are added, you can instantiate VMs using them.

### POSIX Guests (Alpine, Debian, FreeBSD, Rocky Linux)

Sample `Vagrantfile` mounting the LibScript repository (via `rsync`):

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set repository root via environment variable or default to the current directory
repo_root = ENV['LIBSCRIPT_REPO_ROOT'] || "."

Vagrant.configure("2") do |config|
  config.vm.define "libscript-test-node" do |t|
    # Reference the box you just added
    t.vm.box = "bento/alpine-3.24" # Or "bento/debian-13", "bento/freebsd-15.1", or "bento/rockylinux-10.2"

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

### Windows Guests (Windows 11)

Sample `Vagrantfile` for `bento/windows-11` (see `vagrant/windows-11/Vagrantfile`):

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

repo_root = ENV['LIBSCRIPT_REPO_ROOT'] || "."

Vagrant.configure("2") do |config|
  config.vm.define "windows-11-test" do |t|
    t.vm.box = "bento/windows-11"
    t.vm.box_version = "0"

    t.vm.guest = :windows
    t.vm.communicator = "ssh"

    t.ssh.username = "vagrant"
    t.ssh.insert_key = false
    t.ssh.private_key_path = File.expand_path("~/.vagrant.d/insecure_private_key")
    t.ssh.shell = "powershell"

    t.vm.provider "qemu" do |qe|
      qe.net_mode = :user
      qe.ssh_port = 50022 + rand(1000)
    end

    t.vm.synced_folder ".", "/vagrant", disabled: true
    t.vm.allowed_synced_folder_types = [:rsync]

    # Sync the repository root directory
    t.vm.synced_folder repo_root, "/cygdrive/c/libscript", type: "rsync",
      rsync_exclude: [".git/", "tests_tmp/", "vagrant/"]
  end
end
```
