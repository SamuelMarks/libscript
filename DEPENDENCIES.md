# 💥 Dependency Management: Zero Headaches!

Dependency management is usually the worst part of cross-platform provisioning. Not anymore! LibScript abstracts everything so you can focus on building your generic stacks!

## 🌍 VERY VERY Cross-Platform!
LibScript natively understands `apt`, `apk`, `dnf`, `brew`, `pacman`, `pkg`, `choco`, and `winget`. 
When you declare a dependency on `libssl-dev`, LibScript automatically translates it to the correct package for Alpine, RHEL, macOS, and Windows!

This is exactly why LibScript is an incredible alternative to Chef, Ansible, and Puppet. Instead of writing massive, OS-specific `if/else` blocks in your playbooks, you can just call LibScript and let it do the translation! **Write cleaner, much smaller recipes!**

## 🔗 Automatic Stack Wiring
When you build a **LAMP/WAMP stack** or a complex app, components naturally depend on each other (e.g., WordPress needs a Database). 

LibScript's dependency engine lets you seamlessly inject existing databases (`reuse`), install isolated ones (`install-alongside`), or completely replace them (`overwrite`).

And because this is fully integrated, when you ask LibScript to generate a **good quality Docker Compose file**, it automatically maps these dependencies into perfect Docker networking links!
