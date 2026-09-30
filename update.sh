#!/usr/bin/env bash
# 更新 CLIProxyAPI 到最新版(或指定版本),保留配置数据
# 用法: ./update.sh [版本号]   例: ./update.sh v6.4.2   不带参数则用 .env 中的镜像
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "错误: 未找到 .env 文件"
  exit 1
fi

if [[ $# -ge 1 ]]; then
  echo ">>> 更新 .env 中的镜像版本为 $1 ..."
  if grep -q '^CPA_IMAGE=' .env; then
    sed -i.bak "s|^CPA_IMAGE=.*|CPA_IMAGE=eceasy/cli-proxy-api:$1|" .env && rm -f .env.bak
  else
    echo "CPA_IMAGE=eceasy/cli-proxy-api:$1" >> .env
  fi
fi

# 更新前先做一次即时备份(配置无变动时自动跳过)
# sidecar 的 entrypoint 是 /bin/sh -c,run 时需覆盖为 restic;加超时防止网络故障时卡死
if [[ ! -f data/config.yaml ]] || [[ ! -s data/config.yaml ]]; then
  echo "警告: ./data/config.yaml 不存在或为空,跳过更新前备份"
elif timeout 300 docker compose run --rm --entrypoint restic backup-sync \
  backup /data --exclude "*/logs/*" --exclude "*.log" --tag pre-update; then
  echo ">>> 更新前触发一次即时备份到 R2 ..."
  # 备份成功后刷新哈希状态,避免 sidecar 重复备份
  docker compose run --rm --entrypoint "" \
    -v "$(pwd)/backup.state:/state" \
    -v "$(pwd)/data:/data:ro" backup-sync \
    sh -c 'NEW_HASH=$(find /data -type f ! -path "*/logs/*" ! -name "*.log" -print0 | sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum | cut -d" " -f1); [ -n "$NEW_HASH" ] && echo "$NEW_HASH" > /state/last.hash'
else
  echo "警告: 更新前备份失败,继续更新(现有 R2 定期备份仍可用)"
fi

echo ">>> 拉取最新镜像并重启服务 ..."
docker compose pull cliproxy
docker compose up -d

docker compose ps
echo ">>> 更新完成。当前镜像:"
docker inspect --format '{{.Config.Image}}' cliproxy-api
