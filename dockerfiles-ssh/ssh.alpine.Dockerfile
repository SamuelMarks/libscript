FROM alpine:latest

ARG SSH_PUBKEY

RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && printf '%s\n' "${SSH_PUBKEY}" > /root/.ssh/authorized_keys \
    && apk add --update openrc openssh \
    && ssh-keygen -A \
    && printf 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
    && mkdir -p -- /run/openrc \
    && touch -- /run/openrc/softlevel

EXPOSE 22

#CMD ["/sbin/init"]
ENTRYPOINT ["sh", "-c", "rc-status; rc-service sshd start"]
