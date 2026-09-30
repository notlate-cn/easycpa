# EasyCPA — CLIProxyAPI 快速部署 + R2 自动备份

CLIProxyAPI 的开箱即用部署方案:宿主机**只需 Docker**,无需安装 restic / awscli / rclone。
配置数据自动加密备份到 Cloudflare R2,新机器两个文件即可完成迁移。

## 文件结构

```
.
├── docker-compose.yml   # cliproxy 服务 + restic 备份 sidecar
├── .env                 # 凭证配置(从 .env.example 复制,不要提交到 git)
├── start.sh             # 启动服务(.env 有变化时自动重建容器)
├── stop.sh              # 停止服务(保留数据)
├── update.sh            # 更新 CLIProxyAPI(自动先备份)
├── backup.sh            # 手动立即备份
└── data/                # CLIProxyAPI 配置数据(自动创建)
```

## 首次部署

```bash
cp .env.example .env
# 编辑 .env,填入 Cloudflare R2 凭证
./start.sh
```

> 首次启动时备份容器会自动在 R2 桶中初始化 restic 仓库,无需手动 `restic init`。

## 新机器迁移(只需 `docker-compose.yml` + `.env` 两个文件)

```bash
# 1. 恢复配置(默认最新快照;也可指定快照 ID: ./restore.sh a1b2c3d4)
./restore.sh

# 2. 启动服务
./start.sh
```

## 日常运维

```bash
# 修改 .env 后重启生效(compose 会自动重建容器)
./start.sh

# 停止服务(保留数据)
./stop.sh

# 更新到最新版
./update.sh

# 更新到指定版本
./update.sh v6.4.2

# 手动立即备份一次
./backup.sh
```

## 说明

- **数据安全**:备份在传输和存储全程 AES-256 加密,增量去重,加密密码(`BACKUP_PASSWORD`)丢失将无法恢复数据,请妥善保管。
- **备份策略**:默认每 6 小时一次,保留 7 天每日 + 4 周每周快照,可在 `.env` 中通过 `BACKUP_INTERVAL` 调整。
- **配置数据**使用绑定挂载 `./data`(而非命名卷),便于直接查看和迁移。
