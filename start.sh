#!/usr/bin/env bash
# 启动服务(.env 有变化时 compose 会自动重建容器)
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "未检测到 Docker。"
  read -r -p "是否现在安装?(y/N) " INSTALL
  if [[ "$INSTALL" == "y" || "$INSTALL" == "Y" ]]; then
    curl -fsSL https://get.docker.com | sh
  else
    echo "已取消。请先安装 Docker 后再运行本脚本。"
    exit 1
  fi
fi

if [[ ! -f .env ]]; then
  echo "错误: 未找到 .env 文件,请先执行: cp .env.example .env 并填写 R2 凭证"
  exit 1
fi

# 读取 .env 中的端口用于显示(compose 本身会加载 .env)
CPA_PORT=$(grep -E '^CPA_PORT=' .env | cut -d= -f2 | tail -1)
CPA_PORT=${CPA_PORT:-8317}

docker compose up -d
docker compose ps
echo ">>> 服务已启动。API 地址: http://localhost:${CPA_PORT}"
