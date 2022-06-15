source /opt/shell/env.sh && pm2 start /surgio/gateway.js --name "gateway"
pm2 save && pm2 startup
