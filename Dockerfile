FROM node:alpine
LABEL AUTHOR="accors" \
      VERSION=2.3
ENV PATH=/usr/local/bin:$PATH LANG=C.UTF-8 \
    DEFAULT_CRON="0 0 * * *"
COPY ./docker-entrypoint.sh /usr/local/bin
COPY ./config/* /usr/local/bin/
COPY ./env.sh /root
COPY ./ecosystem.config.js /root
RUN set -ex \
        && mkdir -p /root/.ssh \
        && corepack enable \
        && apk update -f \
        && apk add --no-cache bash tzdata git moreutils curl jq openssh-client \
        && echo "Asia/Shanghai" > /etc/timezone \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && pnpm setup \
        && pnpm add -g pm2 \
        && npm config set registry https://registry.npmmirror.com \
        && rm -rf /var/cache/apk/* \
        && echo -e "$DEFAULT_CRON update" > /var/spool/cron/crontabs/root \
        && chmod +x /usr/local/bin/* 
WORKDIR /surgio
ENTRYPOINT ["docker-entrypoint.sh"]
