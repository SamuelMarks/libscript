FROM debian:bookworm-slim

ARG SSH_PUBKEY

RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    printf '%s\n' "${SSH_PUBKEY}" > /root/.ssh/authorized_keys && \
    apt-get update -qq && \
    apt-get install -y openssh-server && \
    ssh-keygen -A && \
    printf 'PasswordAuthentication no' >> /etc/ssh/sshd_config

EXPOSE 22

#CMD ["/sbin/init"]
ENTRYPOINT ["sh", "-c", "rc-status; rc-service sshd start"]
