FROM alpine:latest
LABEL AUTHOR="accors" \
      VERSION=1.5
ENV PATH=/usr/local/bin:$PATH LANG=C.UTF-8 \
    DEFAULT_CRON="0 0 * * *"
COPY ./docker-entrypoint.sh /usr/local/bin
COPY ./config /opt/config
COPY ./ecosystem.config.js /root/ecosystem.config.js
RUN set -ex \
        && apk update -f \
        && apk upgrade \
        && apk add --no-cache bash tzdata git moreutils curl jq openssh-client openrc npm \
        && rm -rf /var/cache/apk/* \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && npm install -g pm2@latest \
        && npm config set registry https://registry.npmmirror.com \
        && echo -e "$DEFAULT_CRON /opt/config/update.sh" > /var/spool/cron/crontabs/root \
        && mkdir -p /root/.ssh 
        && chmod +x /usr/local/bin/docker-entrypoint.sh \
        && ln -sf /opt/shell/env.sh /surgio/env.sh \
        && chmod 600 /root/.ssh/id_rsa 
WORKDIR /surgio
ENTRYPOINT ["docker-entrypoint.sh"]
