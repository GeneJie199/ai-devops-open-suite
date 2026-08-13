# 0.3.2 发布审计

日期：2026-08-13

状态：四个产品仓的 `v0.3.2` Release 已发布并完成下载资产复验；套件 `v0.3.2` 标签因发布脚本语法错误未生成 Release，标签保留审计且不复用，修复由 `v0.3.3` 交付。

## 本次交付

- DevCycle 提供可直接开始工作的首屏引导，并统一套件模块标识。
- InfraScout 保持高密度风险驾驶舱，同时补齐统一的模块视觉识别。
- FleetScope 为首次接入、空资源组和 Agent 全部失联提供可执行恢复路径，并强化监控域图标与刷新控制。
- ReleaseGuard 将缺失报告从死路改为可重试、可查看历史、可返回 DevCycle 的恢复界面。
- Open Suite 增加带 SHA-256 校验的在线/离线安装、事务式升级回滚、统一控制器、持久端口、环境自检和当前用户自启动。
- DevCycle 的实时轮询保留展开输出与阅读位置，就绪度只用各验收标准的最新证据表达当前状态；FleetScope 刷新不再打断告警和变化分诊；InfraScout 风险总数可与暴露、漂移和折叠项完整对账。
- ReleaseGuard 只接受与当前 `release_id` 和报告 SHA-256 同时匹配的人工批准；固定报告路径被后续发布复用时，旧批准继续留存审计，新报告使用独立的摘要绑定 sidecar。

## 已完成门禁

1. 五个 Go module 的 `go test ./...` 与 `go vet ./...` 全部通过。
2. 四个前端脚本通过 `node --check`，四个真实页面无控制台错误和横向溢出。
3. Windows 完成空目录安装、五进程启动、Fleet Agent 真实上报、运行中升级、失败回滚、自启动冷恢复、端口持久化、Doctor、自启动禁用和干净停止。
4. 136 Linux 仅在随机 `/tmp` 目录与动态 loopback 端口执行隔离验收，完成安装、Agent 采集、运行中升级、Doctor、端口持久化、过期 PID 防误杀、user-systemd 单元生成和清理；未访问或修改松月阁服务。
5. PowerShell 解析、Bash 语法、示例 JSON、文档本地链接和 `git diff --check` 全部通过。

## 发布顺序

1. 分别在 `ai-dev-cycle-manager`、`infrastructure-discovery`、`fleet-observability`、`release-validation` 创建 `v0.3.2` 标签。
2. 等待四个仓库的跨平台测试、静态分析、漏洞扫描、构建、checksums 和 GitHub Release 全部成功。
3. 下载并复核四个仓库的 `v0.3.2` 发布资产；`lifecycle-spec` 继续使用已发布且未变更的 `v0.1.1`。
4. 使用下载资产重新执行 Windows 与 136 Linux 安装验收，不使用本地构建替代发布资产。
5. 将套件仓库正式命名为 `ai-devops-open-suite`，确认旧地址重定向和新 origin 后创建 `v0.3.2` 标签，发布 ZIP/TAR 启动包和 `checksums.txt`。

任何产品 Release 资产缺失、checksum 不一致、版本输出错误、安装回滚失败或隔离验收失败，均停止套件标签发布并修复后使用新的补丁版本，绝不复用标签。
