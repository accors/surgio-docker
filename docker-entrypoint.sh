#!/bin/sh
set -e

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# 拒绝以 - 开头的值，防止被 git/ssh-keyscan/pnpm 当作命令行选项
rejectOption() {
    case "$2" in
        -*) die "$1 must not start with '-'" ;;
    esac
}

: "${REPO_URL:?REPO_URL is required}"
: "${REPO_DOMAIN:?REPO_DOMAIN is required}"
if [ -z "$KEY" ] && [ -z "$KEY_FILE" ]; then
    die "Either KEY or KEY_FILE is required"
fi
if [ -n "$KEY" ] && [ -n "$KEY_FILE" ]; then
    echo "WARNING: both KEY and KEY_FILE are set; using KEY_FILE" >&2
fi

PNPM_SOURCE=${PNPM_SOURCE:-https://registry.npmjs.org}
targetBranch=$1
if [ -n "$REPO_BRANCH" ]; then
    targetBranch="$REPO_BRANCH"
fi
if [ -z "$targetBranch" ]; then
    targetBranch="master"
fi

TZ=${TZ:-Asia/Shanghai}
# 只接受 zoneinfo 下的时区名，拒绝绝对路径和 ..，防止 /etc/localtime 指向任意文件
case "$TZ" in
    /* | *..*) tzFile="" ;;
    *) tzFile="/usr/share/zoneinfo/$TZ" ;;
esac
if [ -z "$tzFile" ] || [ ! -f "$tzFile" ]; then
    echo "Unknown TZ '$TZ', falling back to Asia/Shanghai" >&2
    TZ=Asia/Shanghai
fi
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" >/etc/timezone
export TZ

rejectOption REPO_URL "$REPO_URL"
rejectOption REPO_DOMAIN "$REPO_DOMAIN"
rejectOption REPO_BRANCH "$targetBranch"
rejectOption PNPM_SOURCE "$PNPM_SOURCE"
git check-ref-format --branch "$targetBranch" >/dev/null 2>&1 ||
    die "Invalid branch name: $targetBranch"

(
    umask 077
    if [ -n "$KEY_FILE" ]; then
        [ -r "$KEY_FILE" ] || die "KEY_FILE is not readable: $KEY_FILE"
        cat -- "$KEY_FILE" >/root/.ssh/id_rsa
    else
        printf "%b" "$KEY" >/root/.ssh/id_rsa
    fi
)
chmod 600 /root/.ssh/id_rsa
# 私钥已写入文件，避免被 diy.sh、依赖脚本和 Gateway 进程继承
unset KEY

cloneRepo() {
    repoName=$1
    repoUrl=$2
    branchName=$3
    if [ ! -d "/${repoName}/.git" ]; then
        echo "未检查到${repoName}仓库，拉取中..."
        git clone -- "${repoUrl}" /"${repoName}"
        git -C "/${repoName}" fetch --all
        git -C "/${repoName}" checkout "${branchName}"
        return 0
    else
        echo "更新${repoName}仓库..."
        git -C "/${repoName}" fetch --all
        git -C "/${repoName}" checkout "${branchName}"
        git -C "/${repoName}" reset --hard "origin/${branchName}"
        git -C "/${repoName}" pull origin "${branchName}" --rebase
        return 0
    fi
}

# GitHub 官方公布的 SSH 主机密钥：https://api.github.com/meta
writeGithubKnownHosts() {
    cat >/root/.ssh/known_hosts <<'EOF'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
EOF
}

if [ -n "$KNOWN_HOSTS" ] && [ -n "$KNOWN_HOSTS_FILE" ]; then
    die "Set only one of KNOWN_HOSTS or KNOWN_HOSTS_FILE"
fi
if [ -n "$KNOWN_HOSTS_FILE" ]; then
    [ -r "$KNOWN_HOSTS_FILE" ] || die "KNOWN_HOSTS_FILE is not readable: $KNOWN_HOSTS_FILE"
    cat -- "$KNOWN_HOSTS_FILE" >/root/.ssh/known_hosts
elif [ -n "$KNOWN_HOSTS" ]; then
    printf "%b\n" "$KNOWN_HOSTS" >/root/.ssh/known_hosts
elif [ "$REPO_DOMAIN" = "github.com" ]; then
    writeGithubKnownHosts
else
    echo "WARNING: KNOWN_HOSTS/KNOWN_HOSTS_FILE not set; trusting host keys from ssh-keyscan $REPO_DOMAIN (TOFU)" >&2
    ssh-keyscan "$REPO_DOMAIN" >/root/.ssh/known_hosts ||
        die "ssh-keyscan failed for REPO_DOMAIN=$REPO_DOMAIN"
fi
cloneRepo surgio "$REPO_URL" "$targetBranch"
pnpm config set registry "$PNPM_SOURCE"
# 启动时根据 DEFAULT_CRON 生成定时更新任务，使运行时设置生效
DEFAULT_CRON=${DEFAULT_CRON:-0 0 * * *}
case "$DEFAULT_CRON" in
    *"
"*) die "DEFAULT_CRON must be a single line" ;;
esac
printf "%s update\n" "$DEFAULT_CRON" >/var/spool/cron/crontabs/root
crond
if [ -f /surgio/diy.sh ]; then
        . /surgio/diy.sh
fi
pnpm install
# .cjs 在 CommonJS (Surgio v3) 和 ESM (Surgio v4) 仓库中都能加载；
# 仍沿用仓库内已有的 ecosystem.config.js，避免打断 v3 用户
if [ -f /surgio/ecosystem.config.cjs ]; then
        ecosystemFile=ecosystem.config.cjs
elif [ -f /surgio/ecosystem.config.js ]; then
        ecosystemFile=ecosystem.config.js
else
        cp /root/ecosystem.config.cjs /surgio/ecosystem.config.cjs
        ecosystemFile=ecosystem.config.cjs
fi
. /root/env.sh
exec pm2-runtime start "$ecosystemFile" --env production
