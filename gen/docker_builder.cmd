:: ###################
:: #	Toolchain(s) #
:: ###################

docker build --file "dockerfiles\alpine.toolchain.Dockerfile" --progress="plain" --no-cache --tag "deploysh-toolchain":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\debian.toolchain.Dockerfile" --progress="plain" --no-cache --tag "deploysh-toolchain":"dockerfiles/debian-latest" .

:: ###################
:: #	Servers #
:: ###################


:: ###################
:: #	Storage #
:: ###################

docker build --file "dockerfiles\alpine.storage.Dockerfile" --progress="plain" --no-cache --tag "deploysh-storage":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\debian.storage.Dockerfile" --progress="plain" --no-cache --tag "deploysh-storage":"dockerfiles/debian-latest" .

:: ###################
:: #	Third party #
:: ###################

docker build --file "dockerfiles\alpine.third_party.Dockerfile" --progress="plain" --no-cache --tag "deploysh-third_party":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\debian.third_party.Dockerfile" --progress="plain" --no-cache --tag "deploysh-third_party":"dockerfiles/debian-latest" .

:: ###################
:: #	WWWROOT(s) #
:: ###################

docker build --file "dockerfiles\alpine.wwwroot.Dockerfile" --progress="plain" --no-cache --tag "deploysh-wwwroot":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\debian.wwwroot.Dockerfile" --progress="plain" --no-cache --tag "deploysh-wwwroot":"dockerfiles/debian-latest" .

:: ###################
:: #	rest #
:: ###################

docker build --file "dockerfiles\alpine.Dockerfile" --progress="plain" --no-cache --tag "deploysh-":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.example_com.Dockerfile" --progress="plain" --no-cache --tag "deploysh-example_com":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.jupyterhub.Dockerfile" --progress="plain" --no-cache --tag "deploysh-jupyterhub":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.nodejs-http-server.Dockerfile" --progress="plain" --no-cache --tag "deploysh-nodejs-http-server":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.nodejs.Dockerfile" --progress="plain" --no-cache --tag "deploysh-nodejs":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.postgres.Dockerfile" --progress="plain" --no-cache --tag "deploysh-postgres":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.python-server.Dockerfile" --progress="plain" --no-cache --tag "deploysh-python-server":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.python.Dockerfile" --progress="plain" --no-cache --tag "deploysh-python":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.rabbitmq.Dockerfile" --progress="plain" --no-cache --tag "deploysh-rabbitmq":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.rust.Dockerfile" --progress="plain" --no-cache --tag "deploysh-rust":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.sadas.Dockerfile" --progress="plain" --no-cache --tag "deploysh-sadas":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\alpine.valkey.Dockerfile" --progress="plain" --no-cache --tag "deploysh-valkey":"dockerfiles/alpine-latest" .
docker build --file "dockerfiles\debian.Dockerfile" --progress="plain" --no-cache --tag "deploysh-":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.example_com.Dockerfile" --progress="plain" --no-cache --tag "deploysh-example_com":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.jupyterhub.Dockerfile" --progress="plain" --no-cache --tag "deploysh-jupyterhub":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.nodejs-http-server.Dockerfile" --progress="plain" --no-cache --tag "deploysh-nodejs-http-server":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.nodejs.Dockerfile" --progress="plain" --no-cache --tag "deploysh-nodejs":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.postgres.Dockerfile" --progress="plain" --no-cache --tag "deploysh-postgres":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.python-server.Dockerfile" --progress="plain" --no-cache --tag "deploysh-python-server":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.python.Dockerfile" --progress="plain" --no-cache --tag "deploysh-python":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.rabbitmq.Dockerfile" --progress="plain" --no-cache --tag "deploysh-rabbitmq":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.rust.Dockerfile" --progress="plain" --no-cache --tag "deploysh-rust":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.sadas.Dockerfile" --progress="plain" --no-cache --tag "deploysh-sadas":"dockerfiles/debian-latest" .
docker build --file "dockerfiles\debian.valkey.Dockerfile" --progress="plain" --no-cache --tag "deploysh-valkey":"dockerfiles/debian-latest" .

