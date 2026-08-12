# 0.3.0 RC.2 发布审计

状态：RC.2 已发布并完成下载产物验收；稳定版发布门禁已满足

候选：`v0.3.0-rc.2`

日期：2026-08-12

## 本次发布

- DevCycle 增加持久化异步验证任务、实时有界输出、停止、失败证据和异常重启恢复。
- InfraScout 增加变更审核、选择性基线提升、数据库元数据、Nginx 路由与 FleetScope 原生采集计划。
- FleetScope 以自研 Agent、节点身份、可恢复磁盘队列、分段时序/事件存储、查询、规则和告警组成默认数据平面；采集周期可独立配置，中心限制序列、样本、事件和节点历史容量，并能从数据段恢复去重序号。Prometheus 文本、Influx Line 和 OTLP JSON 仅作为兼容输入。
- ReleaseGuard 增加恢复前置门禁、原生指标回归、可恢复观察窗口、运行租约、运行历史和不可变批准保护。
- 四个控制台使用一致的套件顶栏、模块切换和上下文交接，并完成桌面/手机浏览器验收。

## 发布门禁

1. Windows PowerShell 与 Bash 套件 E2E 均输出 `GO`。
2. 五个 Go module 通过 test、vet、Staticcheck 和可达漏洞扫描。
3. 四个产品与 Lifecycle Spec 的 tag workflow 在 Windows、macOS、Linux 上先测试，再构建并发布校验和。
4. 在 136 的独立临时目录和 loopback 端口复验，不读取或修改松月阁的目录、服务、容器和数据。
5. 下载 RC 产物、核对 SHA-256，并用下载产物再跑一次套件 E2E 后，才允许发布稳定 `v0.3.0`。

## RC 验收结果

- Windows PowerShell 与 Git Bash 五模块 E2E 均为 `GO`：8 项门禁、4 次观察采样。
- 136 使用随机 `/tmp` 目录与动态 loopback 端口执行 Linux amd64 预编译候选，最终为 `GO`：8 项门禁、4 次观察采样。
- 从 GitHub Release 重新下载 36 个上传资产，全部通过 GitHub SHA-256 digest；其中 31 个业务产物同时通过各仓库发布的 `checksums.txt`。
- 使用下载回来的 RC.2 Linux amd64 二进制在 136 再次执行五模块链路，结果为 `GO`：8 项门禁、4 次观察采样，满足稳定版放行条件。
- 远端验收结束后，临时目录、进程与监听端口均已清理；未读取或修改松月阁目录、服务、容器和数据。
- 四个控制台完成 1440×900 产品截图与 390×844 移动端复验，均无整页横向溢出。

## 不可变发布记录

- `lifecycle-spec v0.1.0` 的首次 tag workflow 因 Windows checkout 行尾误判而停止；标签未复用，修复后由 `v0.1.1` 完成三平台门禁和发布。
- 三个产品的 `rc.1` 已生成 Pre-release，ReleaseGuard 的 `rc.1` 因候选版本与稳定版 Changelog 章节做逐字匹配而停止；所有标签均未强推或复用。
- 四个产品统一升级到 `v0.3.0-rc.2`，使用当前发布 Actions，明确标记 Pre-release，并全部完成测试、构建、校验和与发布。

## 发布顺序

已先发布 [lifecycle-spec v0.1.1](https://github.com/GeneJie199/lifecycle-spec/releases/tag/v0.1.1)，再发布 DevCycle、InfraScout、FleetScope 和 ReleaseGuard 的统一 `v0.3.0-rc.2` Pre-release，最后创建 `ai-devops-open-suite` 同版本快照。RC 下载产物复验通过后，允许按相同顺序推进稳定 `v0.3.0`；任何仓库门禁失败都停止整套推进，不强推、不复用标签。
