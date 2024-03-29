#!/bin/sh
set -e
cloneRepo() {
if [ ! -d "/app/Sub-Store/.git" ]; then
echo "未检查到Sub-Store仓库，拉取中..."
cd /app
git clone https://github.com/sub-store-org/Sub-Store
git clone https://github.com/sub-store-org/Sub-Store-Front-End
return 0 
else
echo "更新Sub-Store仓库..."
cd /app/Sub-Store && git pull
cd /app/Sub-Store-Front-End && git pull
return 0
fi
}
cloneRepo
echo "仓库拉取成功，安装依赖中..."
cd /app/Sub-Store/backend && pnpm i
cd /app/Sub-Store-Front-End && sed -i 's/192.168.1.19/127.0.0.1/g' .env.development && pnpm i
echo "依赖安装完成，启动后端与面板..."
cd /app/Sub-Store/backend && pm2 start "npm run serve" --name sub-store-backend
cd /app/Sub-Store-Front-End && pm2-runtime start "npm run dev" --name sub-store-frontend
