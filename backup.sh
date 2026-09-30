#!/usr/bin/env bash
# 手动立即备份到 R2(配置无变动时自动跳过;--force 强制备份)并显示快照列表
set -euo pipefail
cd "$(dirname "$0")"

FORCE=""
[[ "${1:-}" == "--force" ]] && FORCE="--force"

docker compose run --rm --entrypoint restic backup-sync \
  backup /data --exclude "*/logs/*" --exclude "*.log" --tag manual $FORCE

# 手动备份成功后刷新哈希状态,让 sidecar 知道已是最新
docker compose run --rm --entrypoint "" \
  -v "$(pwd)/backup.state:/state" \
  -v "$(pwd)/data:/data:ro" backup-sync \
  sh -c 'NEW_HASH=$(find /data -type f ! -path "*/logs/*" ! -name "*.log" -print0 | sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum | cut -d" " -f1); [ -n "$NEW_HASH" ] && echo "$NEW_HASH" > /state/last.hash'

timeout 300 docker compose run --rm --entrypoint restic backup-sync forget --keep-daily 7 --keep-weekly 4 --prune || true
echo ">>> 当前 R2 中的快照:"
timeout 60 docker compose run --rm --entrypoint restic backup-sync snapshots
