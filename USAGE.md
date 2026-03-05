# 🔥 Usage Guide: Let's Build Some Stacks!

LibScript is incredibly powerful and shockingly easy to use! Whether you are building a generic stack, a LAMP/WAMP stack, or generating an installer, you have total control!

## 🛠️ The Generic Stack Maker
Want to install a tool natively, completely bypassing Docker overhead?
```sh
./libscript.sh install nodejs 20
./libscript.sh install rust latest
```

## 🌐 Building a LAMP / WAMP Stack
Define your perfect stack in a `libscript.json` file!
```json
{
  "deps": {
    "httpd": "latest",
    "mariadb": "latest",
    "php": "8.2"
  }
}
```
Then provision the entire stack instantly:
```sh
./libscript.sh install-deps libscript.json
```
Boom! You have a native LAMP (Linux) or WAMP (Windows) stack running perfectly!

## 🐳 Generating Good Quality Dockerfiles
Need to containerize your stack? LibScript is the easiest way to generate top-tier Dockerfiles and Docker Compose files!
```sh
# Generate a perfect docker-compose setup!
./libscript.sh package_as docker_compose postgres 16 redis latest > docker-compose.yml
```

## 📦 Generating Nice Installers!
Ready to ship your application? Generate native installers without writing a single line of packaging code!
```sh
# Generate a Windows MSI Installer!
./libscript.cmd package_as msi --app-name "My Awesome App" nodejs 20

# Generate a Linux Debian Package!
./libscript.sh package_as deb --app-name "My Awesome App" nodejs 20
```
*(macOS and BSD installers are coming soon!)*
