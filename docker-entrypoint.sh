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

ssh-keyscan "$REPO_DOMAIN" >/root/.ssh/known_hosts ||
    die "ssh-keyscan failed for REPO_DOMAIN=$REPO_DOMAIN"
cloneRepo surgio "$REPO_URL" "$targetBranch"
pnpm config set registry "$PNPM_SOURCE"
crond
if [ -f /surgio/diy.sh ]; then
        . /surgio/diy.sh
fi
pnpm install
if [ ! -f /surgio/ecosystem.config.js ]; then
        cp /root/ecosystem.config.js /surgio/ecosystem.config.js
fi
. /root/env.sh
pm2-runtime start ecosystem.config.js --env production
