FROM node:22-alpine
LABEL AUTHOR="accors" \
      VERSION=4.0-beta
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/bin" \
    PNPM_HOME="/root/.local/share/pnpm" \
    PNPM_SOURCE="https://registry.npmjs.org" \
    LANG=C.UTF-8 \
    DEFAULT_CRON="0 0 * * *"
COPY ./docker-entrypoint.sh /usr/local/bin
COPY ./config/* /usr/local/bin/
COPY ./env.sh /root
COPY ./ecosystem.config.cjs /root
RUN set -ex \
        && node -e 'const [major, minor, patch] = process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && (minor < 22 || (minor === 22 && patch < 2)))) process.exit(1)' \
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
