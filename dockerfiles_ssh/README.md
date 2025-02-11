dockerfiles for ssh
===================

## Usage

### Setup public and private keys just for this

```sh
mkdir -- '.ssh'
ssh-keygen -t 'rsa' -b '4096' -C 'libscript ssh keys' -f '.ssh/id_rsa'
```

(this local ".ssh" directory is in both `.gitignore` and `.dockerignore`)

### Build Dockerfiles

```sh
docker build -f 'ssh.alpine.Dockerfile' --tag 'ssh-alpine':'latest' --build-arg SSH_PUBKEY="$(cat -- .ssh/id_rsa.pub)" .
```

### Run Dockerfiles and external images

```sh
docker run -d \
  --name='openssh-server' \
  --hostname='openssh-server' \
  -e PUID='1000' \
  -e PGID='1000' \
  -e TZ='Etc/UTC' \
  -e PUBLIC_KEY="$(cat -- .ssh/id_rsa.pub)" \
  -e SUDO_ACCESS=1 \
  -e USER_NAME='root' \
  -p 2222:2223 \
  --restart 'unless-stopped' \
  lscr.io/linuxserver/openssh-server:latest
sudo docker run --name ssh-alpine-run -t -d -p 22:222 ssh-alpine
```

Also found this one:
```sh
docker run -d --name debian-openssh-server -p 2222:22 -e USER_PASSWORD=654321 devdotnetorg/openssh-server:debian
```

That you can ssh to with password `654321`
