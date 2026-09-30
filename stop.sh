#!/usr/bin/env bash
# 停止服务(不删除数据;./start.sh 可再次启动)
set -euo pipefail
cd "$(dirname "$0")"

docker compose down
echo ">>> 服务已停止。数据保留在 ./data,执行 ./start.sh 可再次启动"
