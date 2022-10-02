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
        && mkdir -p /root/.ssh \
        && apk add --no-cache bash tzdata git moreutils curl jq openssh-client openrc npm \
        && rm -rf /var/cache/apk/* \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && chmod +x /opt/config/* \
        && npm install -g pm2@latest \
        && npm config set registry https://registry.npmmirror.com \
        && touch /surgio/env.sh \
        && echo -e "$DEFAULT_CRON /opt/config/update.sh" > /var/spool/cron/crontabs/root \
        && chmod +x /usr/local/bin/docker-entrypoint.sh \
        && ln -sf /opt/config/env.sh /surgio/env.sh  
WORKDIR /surgio
ENTRYPOINT ["docker-entrypoint.sh"]
