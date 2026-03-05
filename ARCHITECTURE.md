# ⚙️ Architecture: The Engine Behind the Magic!

How do we build a viable alternative to Docker, Chef, and Ansible that runs entirely on zero-dependency shell scripts? By building an incredibly smart, highly dynamic routing and execution layer!

## 🧠 The Zero-Dependency Core
LibScript uses pure POSIX `sh` and Windows `cmd` to route commands. There are no heavy agents. When you ask LibScript to build a **LAMP/WAMP stack**, it dynamically parses `vars.schema.json` files for Apache, MySQL, and PHP, resolving their dependencies on the fly!

## 🏗️ The Incredible `package_as` Generator!
This is where the real magic happens! Because LibScript understands the exact dependencies and environment variables needed for any stack, it can introspect itself!

Instead of running the installation natively, LibScript's architecture allows it to compile the execution graph into:
1. **Pristine, High-Quality Dockerfiles!**
2. **Beautiful `docker-compose.yml` architectures!**
3. **Native Windows Installers (MSI, NSIS, InnoSetup)!**
4. **Native Linux Packages (DEB, RPM, APK)!**
5. **Native FreeBSD Packages (TXZ)!**
6. **Native macOS Installers (PKG, DMG)!**

## 🧩 Smaller, Cleaner Recipes
Because LibScript abstracts away OS differences (like translating `libssl-dev` to `openssl-devel`), you can use it to make your existing Chef, Ansible, or Puppet playbooks incredibly small and clean. Just call LibScript from your playbook, and let us handle the cross-platform nightmare!
