# 🛠️ Developing LibScript: Join the Revolution!

We are building a public-domain, completely open-source alternative to Docker and heavy configuration managers, and we want YOUR help to expand our massive library of components!

## 🚀 Why Contribute?
Every time you write a simple shell script for a new LibScript component, you aren't just making a native installer. Thanks to our dynamic architecture, you are automatically creating:
- A way to generate **good quality Dockerfiles** for that component!
- A way to generate **nice Windows/Linux/FreeBSD/macOS installers** for it!
- A new building block for our **LAMP/WAMP and Generic Stack Maker**!
- A way to write **cleaner, smaller Chef/Ansible recipes** for that software!

## 🧩 How to Scaffold a Component
It's incredibly easy. No DSLs, no Ruby, no Go. Just shell!
1. **Create your folder** in `_lib/_toolchain/my_awesome_tool`.
2. **Define `vars.schema.json`**: Tell LibScript what ports or dependencies your tool needs.
3. **Write `setup.sh`**: Write a simple POSIX shell script to download and configure your tool.
4. **Write `setup_win.ps1`**: Write a PowerShell script for our incredible Windows support.

By simply defining dependencies in your JSON schema, LibScript will automatically link them up when users generate a `docker-compose.yml` or a native installer! 

Let's build the ultimate cross-platform provisioning engine together!
