#!/usr/bin/env bash
# 从 Cloudflare R2 恢复 CLIProxyAPI 配置(新机器迁移第一步)
# 用法: ./restore.sh [snapshot-id]   不带参数则恢复最新快照
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "错误: 未找到 .env 文件,请先执行: cp .env.example .env 并填写 R2 凭证"
  exit 1
fi

SNAPSHOT="${1:-latest}"
mkdir -p data

# sidecar 的 entrypoint 是 /bin/sh -c,run 时需覆盖为 restic
# compose 中 /data 是只读挂载,恢复时另挂宿主机项目目录到 /restore:
# restic 会把快照的完整路径 /data 重建在 target 下,挂项目根目录正好落回 ./data
timeout 60 docker compose run --rm --entrypoint restic backup-sync \
  snapshots >/dev/null 2>&1 || {
    echo "错误: 无法访问 R2 备份仓库,请检查 .env 中的 R2 凭证和网络"
    exit 1
  }

echo ">>> 从 R2 恢复快照 [$SNAPSHOT] 到 ./data ..."
timeout 600 docker compose run --rm --entrypoint restic \
  -v "$(pwd):/restore" backup-sync \
  restore "$SNAPSHOT" --target /restore

# 校验恢复结果:config.yaml 不存在或为空即视为失败
if [[ ! -f data/config.yaml ]] || [[ ! -s data/config.yaml ]]; then
  echo "错误: 恢复后 ./data/config.yaml 不存在或为空,恢复可能失败,请检查上方输出"
  exit 1
fi

echo ">>> 恢复完成。文件列表:"
ls -la data/
echo ">>> 下一步: ./start.sh 启动服务"
