FROM node:current-alpine
LABEL AUTHOR="accors" \
      VERSION=1.0
ENV PATH=/usr/local/bin:$PATH LANG=C.UTF-8
RUN set -ex \
        && apk update -f \
        && apk upgrade \
        && apk add --no-cache bash tzdata git moreutils curl jq openssh-client \
        && rm -rf /var/cache/apk/* \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && npm install -g pm2 \
        && npm config set registry https://registry.npmmirror.com \
        && mkdir -p /root/.ssh 
COPY ./docker-entrypoint.sh /usr/local/bin
RUN set -ex \
        chmod 600 /root/.ssh/id_rsa
WORKDIR /surgio
CMD ["master"]
ENTRYPOINT ["docker-entrypoint.sh"]
