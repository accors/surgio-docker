FROM alpine:latest
WORKDIR /app
COPY ./entrypoint.sh /app
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && echo "========= 安装软件，设置时区 =========" \
    && apk update -f \
    && apk upgrade \
    && apk --no-cache add -f npm bash tzdata git \
    && npm config set registry https://registry.npmmirror.com \
    && npm install npm pnpm pm2 -g \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && mv /app/*.sh /usr/local/bin \
    && chmod +x /usr/local/bin/*.sh
EXPOSE 3000 8888
ENTRYPOINT ["entrypoint.sh"]
