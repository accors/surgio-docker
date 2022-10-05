#!/bin/sh
set -e
cloneRepo() {
if [ ! -d "/app/Sub-Store/.git" ]; then
echo "未检查到Sub-Store仓库，拉取中..."
git clone https://github.com/sub-store-org/Sub-Store /app
git clone https://github.com/sub-store-org/Sub-Store-Front-End /app 
else
echo "更新Sub-Store仓库..."
git -C /app/Sub-Store fetch --all
git -C /app/Sub-Store-Front-End fetch --all
fi
}
cloneRepo
echo "仓库拉取成功，安装依赖中..."
cd Sub-Store-Front-End && pnpm install
cd .. && cd Sub-Store/backend && pnpm install
echo "依赖安装完成，启动后端与面板..."
cd && cd Sub-Store-Front-End && pnpm dev
pm2-runtime start sub-store.min.js

