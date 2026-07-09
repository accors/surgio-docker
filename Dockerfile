FROM node:22-alpine
LABEL AUTHOR="accors" \
      VERSION=3.0
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm" \
    PNPM_HOME="/root/.local/share/pnpm" \
    PNPM_SOURCE="https://registry.npmjs.org" \
    LANG=C.UTF-8 \
    DEFAULT_CRON="0 0 * * *"
COPY ./docker-entrypoint.sh /usr/local/bin
COPY ./config/* /usr/local/bin/
COPY ./env.sh /root
COPY ./ecosystem.config.js /root
RUN set -ex \
        && mkdir -p /root/.ssh \
        && corepack enable \
        && corepack prepare pnpm@11.10.0 --activate \
        && apk update -f \
        && apk add --no-cache bash tzdata git moreutils curl jq openssh-client \
        && echo "Asia/Shanghai" > /etc/timezone \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && pnpm add -g pm2 \
        && rm -rf /var/cache/apk/* \
        && printf "%s\n" "$DEFAULT_CRON update" > /var/spool/cron/crontabs/root \
        && chmod +x /usr/local/bin/* 
WORKDIR /surgio
CMD docker-entrypoint.sh
