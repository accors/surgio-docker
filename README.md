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

The `main` branch continues to publish `accors/surgio:latest`. This `codex/v4-beta` branch builds `accors/surgio:v4-beta` for Surgio v4 projects; it does not publish `latest`. Both images target `linux/amd64`, `linux/arm64/v8`, and `linux/arm/v7`. This repository also contains a separate Sub-Store image path based on `Sub.dockerfile` and `entrypoint.sh`; it is independent of the main Surgio image.

### Prerequisites

- Read the [Surgio API Gateway deployment guide](https://surgio.js.org/guide/advance/api-gateway.html#%E8%87%AA%E6%9C%89%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%83%A8%E7%BD%B2) and prepare a valid Surgio project.
- Install Docker Engine and the Docker Compose plugin.
- Push your Surgio project to a private Git repository.
- Create a restricted SSH deploy key that can read that repository, then escape its line breaks for the `KEY` environment variable.

For `v4-beta`, the private repository must contain a Surgio v4 project and an ESM `gateway.js`; if needed, use this branch's [sample `gateway.js`](https://raw.githubusercontent.com/accors/surgio-docker/codex/v4-beta/gateway.js). If you maintain a custom PM2 configuration, name it `ecosystem.config.cjs`, keep the application name `Gateway`, and update its script for the ESM Gateway. An existing `ecosystem.config.js` must be migrated before startup. When no PM2 configuration exists, the image copies its default `ecosystem.config.cjs` into `/surgio`.

### Quick start

Pull the image:

```sh
docker pull accors/surgio:v4-beta
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
    image: accors/surgio:v4-beta
    container_name: surgio-docker
    restart: unless-stopped
    environment:
      - REPO_URL=git@github.com:YOUR_USER/YOUR_REPOSITORY.git
      - PNPM_SOURCE=https://registry.npmjs.org
      - REPO_DOMAIN=github.com
      - REPO_BRANCH=main
      - KEY=YOUR_ESCAPED_OPENSSH_PRIVATE_KEY
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
| `KEY` | Yes | - | Escaped OpenSSH private key used to read the repository. |
| `REPO_BRANCH` | No | `master` | Branch checked out and synchronized at startup. |
| `PNPM_SOURCE` | No | `https://registry.npmjs.org` | pnpm registry used when installing dependencies. |
| `HOST` | No | `0.0.0.0` | Surgio Gateway listening address. |
| `PORT` | No | `3000` | Surgio Gateway listening port. Update the container-side port mapping when changing it. |

The image requires Node.js 22.22.2 or newer and activates pnpm 11.10.0 through Corepack. The private project must install Surgio v4 dependencies during container startup; `config/update` only pulls Git changes and restarts `Gateway`, so restart the container after upgrading dependencies.

### Custom startup commands

If `/surgio/diy.sh` exists, the entrypoint sources it before installing dependencies. The script runs as root inside the container, so only use a script from a repository you trust.

### Security and update behavior

- The SSH key is provided through an environment variable and written to `/root/.ssh/id_rsa` inside the container. Prefer a read-only, repository-scoped deploy key.
- Repository code, `diy.sh`, and package lifecycle scripts run as root inside the container. Treat the repository and its dependencies as trusted code.
- Startup synchronization runs `git reset --hard origin/<branch>` in `/surgio`. Tracked local changes in the mounted directory can be overwritten.
- The Gateway listens on `0.0.0.0:3000` by default. Configure Surgio authentication and appropriate network or reverse-proxy access controls before exposing it publicly.

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

`main` 分支继续发布 `accors/surgio:latest`。当前 `codex/v4-beta` 分支为 Surgio v4 项目构建 `accors/surgio:v4-beta`，不会发布 `latest`。两条镜像线均以 `linux/amd64`、`linux/arm64/v8` 和 `linux/arm/v7` 为目标平台。本仓库还包含由 `Sub.dockerfile` 和 `entrypoint.sh` 构成的独立 Sub-Store 镜像链路；它不属于 Surgio 主镜像的启动流程。

### 使用前提

- 阅读 [Surgio API Gateway 部署文档](https://surgio.js.org/guide/advance/api-gateway.html#%E8%87%AA%E6%9C%89%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%83%A8%E7%BD%B2)，并准备一个有效的 Surgio 项目。
- 安装 Docker Engine 和 Docker Compose 插件。
- 将自己的 Surgio 项目推送到私有 Git 仓库。
- 创建仅具有该仓库读取权限的 SSH deploy key，并将私钥换行转义后传入 `KEY` 环境变量。

使用 `v4-beta` 时，私有仓库必须包含 Surgio v4 项目和 ESM 格式的 `gateway.js`；如有需要，可使用当前分支的[示例 `gateway.js`](https://raw.githubusercontent.com/accors/surgio-docker/codex/v4-beta/gateway.js)。若自行维护 PM2 配置，请将文件命名为 `ecosystem.config.cjs`，保留应用名 `Gateway`，并让脚本指向 ESM Gateway。现有 `ecosystem.config.js` 必须在启动前迁移。没有 PM2 配置时，镜像会把默认 `ecosystem.config.cjs` 复制到 `/surgio`。

### 快速开始

拉取镜像：

```sh
docker pull accors/surgio:v4-beta
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
    image: accors/surgio:v4-beta
    container_name: surgio-docker
    restart: unless-stopped
    environment:
      - REPO_URL=git@github.com:YOUR_USER/YOUR_REPOSITORY.git
      - PNPM_SOURCE=https://registry.npmjs.org
      - REPO_DOMAIN=github.com
      - REPO_BRANCH=main
      - KEY=YOUR_ESCAPED_OPENSSH_PRIVATE_KEY
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
| `KEY` | 是 | - | 用于读取仓库、已转义换行的 OpenSSH 私钥。 |
| `REPO_BRANCH` | 否 | `master` | 容器启动时检出并同步的分支。 |
| `PNPM_SOURCE` | 否 | `https://registry.npmjs.org` | 安装依赖时使用的 pnpm registry。 |
| `HOST` | 否 | `0.0.0.0` | Surgio Gateway 监听地址。 |
| `PORT` | 否 | `3000` | Surgio Gateway 监听端口；修改后需同步调整端口映射的容器端口。 |

镜像要求 Node.js 22.22.2 或更新版本，并通过 Corepack 激活 pnpm 11.10.0。私有项目的 Surgio v4 依赖会在容器启动时安装；`config/update` 仅拉取 Git 变更并重启 `Gateway`，升级依赖后应重启容器。

### 自定义启动命令

如果 `/surgio/diy.sh` 存在，入口脚本会在安装依赖前加载它。该脚本会在容器内以 root 身份运行，因此只能使用可信仓库中的脚本。

### 安全与更新行为

- SSH 私钥通过环境变量传入，并写入容器内的 `/root/.ssh/id_rsa`。建议使用只读、仅限目标仓库的 deploy key。
- 仓库代码、`diy.sh` 和依赖生命周期脚本会在容器内以 root 身份运行，应将仓库及其依赖视为可信代码。
- 启动同步会在 `/surgio` 中执行 `git reset --hard origin/<branch>`，挂载目录中已跟踪但未提交的本地修改可能被覆盖。
- Gateway 默认监听 `0.0.0.0:3000`。公开暴露前，请配置 Surgio 身份验证以及合适的网络或反向代理访问控制。

### 致谢

- [@geekdada](https://github.com/surgioproject/surgio)
- [@lowking](https://github.com/lowking/rule-store)

欢迎通过 [GitHub Issues](https://github.com/accors/surgio-docker/issues) 提交问题和建议。如果项目对你有帮助，也欢迎 Star。
