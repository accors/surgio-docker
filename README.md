# Surgio Docker

[![GitHub Stars](https://img.shields.io/github/stars/accors/surgio-docker?style=flat-square)](https://github.com/accors/surgio-docker/stargazers)
[![Docker Pulls](https://img.shields.io/docker/pulls/accors/surgio?style=flat-square)](https://hub.docker.com/r/accors/surgio)
[![License: GPL-3.0](https://img.shields.io/github/license/accors/surgio-docker?style=flat-square)](LICENSE)

[English](#english) | [简体中文](#简体中文)

## English

### Overview

`surgio-docker` is an independent Docker deployment wrapper for the [Surgio](https://github.com/surgioproject/surgio) API/Gateway. It is not the upstream Surgio project.

At startup, the main image:

1. Connects to a user-controlled private Git repository over SSH.
2. Clones or synchronizes the Surgio configuration into `/surgio`.
3. Configures pnpm, optionally sources `/surgio/diy.sh`, and installs the repository dependencies.
4. Starts cron and runs the Surgio Gateway under PM2.

The published `accors/surgio:latest` image supports `linux/amd64`, `linux/arm64/v8`, and `linux/arm/v7`.

### Prerequisites

- Read the [Surgio API Gateway deployment guide](https://surgio.js.org/guide/advance/api-gateway.html#%E8%87%AA%E6%9C%89%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%83%A8%E7%BD%B2) and prepare a valid Surgio project.
- Install Docker Engine and the Docker Compose plugin.
- Push your Surgio project to a private Git repository.
- Create a restricted SSH deploy key that can read that repository, then escape its line breaks for the `KEY` environment variable.

If needed, use this repository's [sample `gateway.js`](https://raw.githubusercontent.com/accors/surgio-docker/main/gateway.js) in the root of your Surgio project.

### Quick start

Pull the image:

```sh
docker pull accors/surgio:latest
```

Create and enter a working directory:

```sh
mkdir -p surgio-docker
cd surgio-docker
```

Create `docker-compose.yml`:

```yaml
version: "3.7"
services:
  surgio:
    image: accors/surgio:latest
    container_name: surgio-docker
    restart: unless-stopped
    environment:
      - REPO_URL=git@github.com:YOUR_USER/YOUR_REPOSITORY.git
      - PNPM_SOURCE=https://registry.npmjs.org
      - REPO_DOMAIN=github.com
      - REPO_BRANCH=main
      - KEY=YOUR_ESCAPED_OPENSSH_PRIVATE_KEY
      - GATEWAY_TOKEN=YOUR_RANDOM_TOKEN
      - HOST=0.0.0.0
      - PORT=3000
    ports:
      - "3000:3000"
    volumes:
      - "./surgio:/surgio"
```

Start the container:

```sh
docker compose up -d
```

Restart the container after changing its environment or deployment configuration.

### Environment variables

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `REPO_URL` | Yes | - | SSH URL of the private Surgio repository. |
| `REPO_DOMAIN` | Yes | - | SSH host used by the repository, such as `github.com`. |
| `KEY` | Yes* | - | Escaped OpenSSH private key used to read the repository. *Not needed when `KEY_FILE` is set. |
| `KEY_FILE` | No | - | Path to a mounted private key file (for example a Docker secret). Takes precedence over `KEY` and keeps the key out of `docker inspect`. |
| `REPO_BRANCH` | No | `master` | Branch checked out and synchronized at startup. |
| `KNOWN_HOSTS` | No | - | `known_hosts` lines for `REPO_DOMAIN`, with line breaks escaped like `KEY`. |
| `KNOWN_HOSTS_FILE` | No | - | Path to a `known_hosts` file inside the container. Set at most one of `KNOWN_HOSTS` or `KNOWN_HOSTS_FILE`. |
| `PNPM_SOURCE` | No | `https://registry.npmjs.org` | pnpm registry used when installing dependencies. |
| `GATEWAY_TOKEN` | Yes, with the sample config | - | Gateway access token read by the sample `surgio.conf.js`, which enables `gateway.auth`. Surgio refuses to load that config without it, including `surgio generate`. Only applies if your `surgio.conf.js` reads it. |
| `DEFAULT_CRON` | No | `0 0 * * *` | Cron schedule for running `update` (pull the repository and restart the Gateway). Applied at each container start. |
| `HOST` | No | `0.0.0.0` | Surgio Gateway listening address. |
| `PORT` | No | `3000` | Surgio Gateway listening port. Update the container-side port mapping when changing it. |
| `TZ` | No | `Asia/Shanghai` | Container time zone; also decides when the daily update cron runs. |

The image is based on Node.js 22 Alpine and activates pnpm 11.10.0 through Corepack.

Besides `latest`, every build is also tagged by UTC date (`YYYYMMDD`) and commit (`sha-<7 chars>`), so you can pin or roll back to a known image.

### Custom startup commands

If `/surgio/diy.sh` exists, the entrypoint sources it before installing dependencies. The script runs as root inside the container, so only use a script from a repository you trust.

### Security and update behavior

- The SSH key is provided through `KEY` or a mounted `KEY_FILE` and written to `/root/.ssh/id_rsa` (mode `600`) inside the container. `KEY_FILE` avoids exposing the key in the container environment. `KEY` is unset after it is written, so `diy.sh`, dependency scripts, and the Gateway do not inherit it. Prefer a read-only, repository-scoped deploy key.
- `REPO_URL`, `REPO_DOMAIN`, `REPO_BRANCH`, and `PNPM_SOURCE` must not start with `-`, and the branch must be a valid Git branch name. Avoid embedding credentials in `REPO_URL`, as Git error messages may print the URL.
- SSH host keys come from `KNOWN_HOSTS` or `KNOWN_HOSTS_FILE`. Without them, `github.com` uses GitHub's published host keys built into the image; any other `REPO_DOMAIN` falls back to `ssh-keyscan` with a warning, which trusts whatever key the host presents at startup. Set `KNOWN_HOSTS` for self-hosted Git servers.
- Repository code, `diy.sh`, and package lifecycle scripts run as root inside the container. Treat the repository and its dependencies as trusted code.
- Startup synchronization runs `git reset --hard origin/<branch>` in `/surgio`. Tracked local changes in the mounted directory can be overwritten.
- The Gateway listens on `0.0.0.0:3000` by default. The sample `surgio.conf.js` enables Gateway authentication with `GATEWAY_TOKEN`; subscription URLs then need `?access_token=<GATEWAY_TOKEN>`. Use a long random token, for example from `openssl rand -hex 32`, and still apply appropriate network or reverse-proxy access controls before exposing it publicly.

### Acknowledgements

- [@geekdada](https://github.com/surgioproject/surgio)
- [@lowking](https://github.com/lowking/rule-store)

Issues and suggestions are welcome in the [GitHub issue tracker](https://github.com/accors/surgio-docker/issues).

## 简体中文

### 项目概览

`surgio-docker` 是 [Surgio](https://github.com/surgioproject/surgio) API/Gateway 的独立 Docker 部署包装层，并非 Surgio 上游项目本身。

主镜像启动时会：

1. 通过 SSH 连接用户控制的私有 Git 仓库。
2. 将 Surgio 配置克隆或同步到 `/surgio`。
3. 配置 pnpm，可选加载 `/surgio/diy.sh`，并安装仓库依赖。
4. 启动 cron，再由 PM2 运行 Surgio Gateway。

公开镜像 `accors/surgio:latest` 支持 `linux/amd64`、`linux/arm64/v8` 和 `linux/arm/v7`。

### 使用前提

- 阅读 [Surgio API Gateway 部署文档](https://surgio.js.org/guide/advance/api-gateway.html#%E8%87%AA%E6%9C%89%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%83%A8%E7%BD%B2)，并准备一个有效的 Surgio 项目。
- 安装 Docker Engine 和 Docker Compose 插件。
- 将自己的 Surgio 项目推送到私有 Git 仓库。
- 创建仅具有该仓库读取权限的 SSH deploy key，并将私钥换行转义后传入 `KEY` 环境变量。

如有需要，可将本仓库的[示例 `gateway.js`](https://raw.githubusercontent.com/accors/surgio-docker/main/gateway.js)放入 Surgio 项目根目录。

### 快速开始

拉取镜像：

```sh
docker pull accors/surgio:latest
```

创建并进入工作目录：

```sh
mkdir -p surgio-docker
cd surgio-docker
```

创建 `docker-compose.yml`：

```yaml
version: "3.7"
services:
  surgio:
    image: accors/surgio:latest
    container_name: surgio-docker
    restart: unless-stopped
    environment:
      - REPO_URL=git@github.com:YOUR_USER/YOUR_REPOSITORY.git
      - PNPM_SOURCE=https://registry.npmjs.org
      - REPO_DOMAIN=github.com
      - REPO_BRANCH=main
      - KEY=YOUR_ESCAPED_OPENSSH_PRIVATE_KEY
      - GATEWAY_TOKEN=YOUR_RANDOM_TOKEN
      - HOST=0.0.0.0
      - PORT=3000
    ports:
      - "3000:3000"
    volumes:
      - "./surgio:/surgio"
```

启动容器：

```sh
docker compose up -d
```

修改环境变量或部署配置后，请重启容器使配置生效。

### 环境变量

| 变量 | 必填 | 默认值 | 用途 |
| --- | --- | --- | --- |
| `REPO_URL` | 是 | - | 私有 Surgio 仓库的 SSH URL。 |
| `REPO_DOMAIN` | 是 | - | 仓库使用的 SSH 主机，例如 `github.com`。 |
| `KEY` | 是* | - | 用于读取仓库、已转义换行的 OpenSSH 私钥。*设置了 `KEY_FILE` 时可不填。 |
| `KEY_FILE` | 否 | - | 挂载进容器的私钥文件路径（如 Docker secret）。优先于 `KEY`，私钥不会出现在 `docker inspect` 中。 |
| `REPO_BRANCH` | 否 | `master` | 容器启动时检出并同步的分支。 |
| `KNOWN_HOSTS` | 否 | - | `REPO_DOMAIN` 的 `known_hosts` 内容，换行转义方式与 `KEY` 相同。 |
| `KNOWN_HOSTS_FILE` | 否 | - | 容器内 `known_hosts` 文件路径。`KNOWN_HOSTS` 与 `KNOWN_HOSTS_FILE` 最多设置其一。 |
| `PNPM_SOURCE` | 否 | `https://registry.npmjs.org` | 安装依赖时使用的 pnpm registry。 |
| `GATEWAY_TOKEN` | 使用示例配置时必填 | - | 示例 `surgio.conf.js` 读取的 Gateway 访问令牌，示例默认开启 `gateway.auth`。未设置时 Surgio 会拒绝加载该配置（包括 `surgio generate`）。仅在你的 `surgio.conf.js` 读取它时生效。 |
| `DEFAULT_CRON` | 否 | `0 0 * * *` | 执行 `update`（拉取仓库并重启 Gateway）的 cron 表达式，每次容器启动时生效。 |
| `HOST` | 否 | `0.0.0.0` | Surgio Gateway 监听地址。 |
| `PORT` | 否 | `3000` | Surgio Gateway 监听端口；修改后需同步调整端口映射的容器端口。 |
| `TZ` | 否 | `Asia/Shanghai` | 容器时区，同时决定每日更新任务的执行时间。 |

镜像基于 Node.js 22 Alpine 构建，并通过 Corepack 激活 pnpm 11.10.0。

除 `latest` 外，每次构建还会打上 UTC 日期（`YYYYMMDD`）和提交（`sha-<7 位>`）标签，便于固定版本或回滚。

### 自定义启动命令

如果 `/surgio/diy.sh` 存在，入口脚本会在安装依赖前加载它。该脚本会在容器内以 root 身份运行，因此只能使用可信仓库中的脚本。

### 安全与更新行为

- SSH 私钥通过 `KEY` 或挂载的 `KEY_FILE` 传入，并写入容器内的 `/root/.ssh/id_rsa`（权限 `600`）。使用 `KEY_FILE` 可避免私钥暴露在容器环境变量中。`KEY` 写入后会被 unset，`diy.sh`、依赖脚本和 Gateway 不会继承它。建议使用只读、仅限目标仓库的 deploy key。
- `REPO_URL`、`REPO_DOMAIN`、`REPO_BRANCH` 和 `PNPM_SOURCE` 不能以 `-` 开头，分支名必须是合法的 Git 分支名。不要在 `REPO_URL` 中嵌入凭据，Git 报错信息可能会打印该 URL。
- SSH 主机密钥来自 `KNOWN_HOSTS` 或 `KNOWN_HOSTS_FILE`。未设置时，`github.com` 使用镜像内置的 GitHub 官方主机密钥；其他 `REPO_DOMAIN` 回退到 `ssh-keyscan` 并打印警告，此时会信任主机在启动时提供的任意密钥。自建 Git 服务器建议设置 `KNOWN_HOSTS`。
- 仓库代码、`diy.sh` 和依赖生命周期脚本会在容器内以 root 身份运行，应将仓库及其依赖视为可信代码。
- 启动同步会在 `/surgio` 中执行 `git reset --hard origin/<branch>`，挂载目录中已跟踪但未提交的本地修改可能被覆盖。
- Gateway 默认监听 `0.0.0.0:3000`。示例 `surgio.conf.js` 通过 `GATEWAY_TOKEN` 开启 Gateway 身份验证，订阅链接需带上 `?access_token=<GATEWAY_TOKEN>`。请使用足够长的随机令牌（例如 `openssl rand -hex 32` 生成），公开暴露前仍应配置合适的网络或反向代理访问控制。

### 致谢

- [@geekdada](https://github.com/surgioproject/surgio)
- [@lowking](https://github.com/lowking/rule-store)

欢迎通过 [GitHub Issues](https://github.com/accors/surgio-docker/issues) 提交问题和建议。如果项目对你有帮助，也欢迎 Star。
