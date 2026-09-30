#!/usr/bin/env bash
# 启动 CLIProxyAPI 服务 + 自动备份 sidecar
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "错误: 未找到 .env 文件,请先执行: cp .env.example .env 并填写 R2 凭证"
  exit 1
fi

docker compose up -d
docker compose ps
echo ">>> 服务已启动。API 地址: http://localhost:${CPA_PORT:-8317}"
