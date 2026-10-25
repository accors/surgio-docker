#!/bin/sh
set -e

: "${REPO_URL:?REPO_URL is required}"
: "${REPO_DOMAIN:?REPO_DOMAIN is required}"

PNPM_SOURCE=${PNPM_SOURCE:-https://registry.npmjs.org}
targetBranch=$1
if [ -n "$REPO_BRANCH" ]; then
    targetBranch="$REPO_BRANCH"
fi
if [ -z "$targetBranch" ]; then
    targetBranch="master"
fi

TZ=${TZ:-Asia/Shanghai}
if [ ! -f "/usr/share/zoneinfo/$TZ" ]; then
    echo "Unknown TZ '$TZ', falling back to Asia/Shanghai" >&2
    TZ=Asia/Shanghai
fi
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" >/etc/timezone
export TZ

if [ -n "$KEY_FILE" ]; then
    if [ ! -r "$KEY_FILE" ]; then
        echo "KEY_FILE ($KEY_FILE) is not readable" >&2
        exit 1
    fi
    cp "$KEY_FILE" /root/.ssh/id_rsa
elif [ -n "$KEY" ]; then
    printf "%b" "$KEY" >/root/.ssh/id_rsa
else
    echo "Either KEY or KEY_FILE is required" >&2
    exit 1
fi
chmod 600 /root/.ssh/id_rsa

cloneRepo() {
    repoName=$1
    repoUrl=$2
    branchName=$3
    if [ ! -d "/${repoName}/.git" ]; then
        echo "未检查到${repoName}仓库，拉取中..."
        git clone "${repoUrl}" /"${repoName}"
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

ssh-keyscan "$REPO_DOMAIN" >/root/.ssh/known_hosts
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
