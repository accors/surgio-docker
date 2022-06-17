#!/bin/sh
set -e
targetBranch=$1
if [ -n "$REPO_BRANCH" ]; then
    targetBranch="$REPO_BRANCH"
fi
if [ -z "$targetBranch" ]; then
    targetBranch="master"
fi

echo -e "$KEY" >/root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

cloneRepo() {
    repoName=$1
    repoUrl=$2
    branchName=$3
    if [ ! -d "/${repoName}/.git" ]; then
        echo "未检查到${repoName}仓库，clone..."
        git clone "${repoUrl}" /"${repoName}"
        git -C "/${repoName}" fetch --all
        git -C "/${repoName}" checkout "${branchName}"
        return 0
    else
        echo "更新${repoName}仓库..."
        git -C "/${repoName}" fetch --all
        git -C "/${repoName}" checkout "${branchName}"
        git -C "/${repoName}" reset --hard origin/"${branchName}"
        git -C "/${repoName}" pull origin "${branchName}" --rebase
        return 0
    fi
}

ssh-keyscan "$REPO_DOMAIN" >/root/.ssh/known_hosts
cloneRepo surgio "$REPO_URL" "$targetBranch"

npm config delete registry
npm config set registry https://registry.npmmirror.com
npm install
pm2 start /surgio/gateway.js && pm2 save && pm2 startup &>/dev/null
node /surgio/gw.js
