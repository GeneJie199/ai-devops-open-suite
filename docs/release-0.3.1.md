# 0.3.1 稳定版发布审计

状态：已发布，下载产物验收通过

日期：2026-08-12

## 发布组成

- [Lifecycle Spec v0.1.1](https://github.com/GeneJie199/lifecycle-spec/releases/tag/v0.1.1) 提供离线 Schema、示例、生成类型和校验器。
- [DevCycle v0.3.1](https://github.com/GeneJie199/ai-dev-cycle-manager/releases/tag/v0.3.1) 提供需求、证据、任务、Git worktree、本地 AI 会话、异步验证和发布候选工作台。
- [InfraScout v0.3.1](https://github.com/GeneJie199/infrastructure-discovery/releases/tag/v0.3.1) 提供 Linux/容器/进程/端口/Nginx/数据库发现、基线、漂移、审核和报告。
- [FleetScope v0.3.1](https://github.com/GeneJie199/fleet-observability/releases/tag/v0.3.1) 使用自研 Agent、原生时序与事件存储、规则和告警作为默认数据平面；主流格式仅作为兼容输入。
- [ReleaseGuard v0.3.1](https://github.com/GeneJie199/release-validation/releases/tag/v0.3.1) 提供可恢复门禁、运行租约、原生指标回归、观察窗口、不可变报告和人工批准保护。

## 交付门禁

1. 五个 Go module 通过 test、vet、Staticcheck 和可达漏洞扫描；tag workflow 覆盖 Windows、macOS、Linux 测试与五个平台构建目标。
2. 四个产品的 `v0.3.1` Release 均非草稿、非 Pre-release，所有资产状态为 uploaded。
3. 从 GitHub 重新下载 36 个资产，全部匹配 GitHub SHA-256 digest；31 个业务产物同时匹配各 Release 的 `checksums.txt`。
4. 下载的四个 Windows amd64 产品二进制均实际输出 `0.3.1`，下载的 Lifecycle 校验器成功验证正式示例。
5. 下载的 Linux amd64 产物在 136 的随机 `/tmp` 目录和动态 loopback 端口连续执行两次，均为 `GO`：8 项门禁、4 次观察采样。
6. 每次远端验收结束后临时目录、进程和端口均已清理；未读取或修改松月阁目录、服务、容器和数据。
7. 四个控制台已经过 1440×900 桌面与 390×844 移动端浏览器验收，无整页横向溢出。

## 阻断与修复记录

- `v0.3.0` 发布物首次最终复验得到 `NO-GO`：FleetScope 将一次 200ms CPU 瞬时采样达到 95% 直接判为 `critical`。
- 四个 `v0.3.0` Release 随即统一标记为 Pre-release，标签和流水线记录均保留，未删除、强推或复用。
- `v0.3.1` 将单次高 CPU 采样调整为 `warning`，内存或磁盘达到 95% 仍为 `critical`；ReleaseGuard 继续阻断 critical、stale 和不可达节点。
- 回归测试直接覆盖 CPU 99%、内存 95% 和磁盘 95% 的健康分级，修复候选与最终下载产物均在 136 通过。

## 使用入口

各产品可独立安装和运行，也可按 DevCycle → InfraScout → FleetScope → ReleaseGuard 的证据链组合使用。部署、安全、运维和故障排查命令以各仓库 README 与 `docs/` 为准；套件级本地验收使用 `scripts/verify-suite.ps1` 或 `scripts/verify-suite.sh`。
