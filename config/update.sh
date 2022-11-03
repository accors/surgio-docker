#!/bin/sh
npx surgio generate
git -C /surgio pull origin && pm2 restart Gateway
