# 下一阶段：Linux 基础扫描 Demo 打磨计划

**专业名称：** Linux Baseline Scan Demo Hardening  
**通俗解释：** 先把「扫一遍机器 → 出清单 → 对比两次」做成别人 5 分钟能看懂的演示，再上 Docker/K8s。

## 1. 为何这是下一个功能（而不是新开大模块）

| 考量 | 结论 |
|------|------|
| 对 FleetScope 的基础价值 | 中心侧最终要吃「主机/进程/端口/服务」类资源与快照；现在打磨输出形状 = 以后 Agent 上报的雏形 |
| 快速验证架构 | 已有 CLI + 夹具测试；验证「本地 JSON + 稳定 ID + Diff」闭环成本低 |
| 可独立测试 | `go test` + fixture；Linux 实机可选 |
| 可展示 Demo | 一条命令出 `inventory.json` / `snapshot.json` / drift |
| 现状 | **INF-001～004 已实现主体**；缺口在「演示完整度」与协议对齐，而非从零采集 |

因此：**下一阶段不是从零写扫描，而是把现有扫描做成可对外演示的垂直切片**，并明确不碰 Docker/K8s/数据库元数据。

## 2. 目标用户故事

> 运维在一台 Linux 上运行两次扫描（或用夹具模拟变更），得到：  
> - 资产清单 `inventory.json`  
> - 标准化快照 `snapshot.json`  
> - Diff：新增 / 删除 / 变化，并带**风险提示**与**证据引用**（至少指向两次快照文件与关键资源 ID）

## 3. 已有 vs 缺口

| 项 | 状态 |
|----|------|
| 主机 / CPU / 内存 / 磁盘 / 网卡 | 已有 |
| 进程 / 监听端口 / 关联 | 已有 |
| systemd | 已有 |
| inventory + snapshot 输出 | 已有 |
| Diff 新增/删除/变更 + 噪声过滤 | 已有 |
| 终端可读摘要（非专业友好） | 弱 / 待加强 |
| 风险等级（risk / severity） | **未进入 DriftReport** |
| Evidence 对象或证据指针 | **未产出** |
| 与 lifecycle-spec ChangeEvent 导出 | **未做** |
| 故意制造夹具「前后差异」的 Demo 剧本 | 建议补第二套 fixture |

## 4. 建议任务拆分（实现阶段再用）

1. **DEMO-001** 可读 CLI 摘要：扫描结束打印主机名、进程数、监听端口数、服务数  
2. **DEMO-002** Drift 增加 `severity`/`risk` 启发式（确定性规则，非 AI）：如新增对外 `0.0.0.0` 监听 → medium/high  
3. **DEMO-003** Diff 输出附带 `evidence`：基线/候选 snapshotId、文件路径或内容 digest  
4. **DEMO-004** 可选：导出 1～N 条 `change-event` JSON（符合 lifecycle-spec）  
5. **DEMO-005** 增加 `testdata/host-sample-v2` 制造真实差异，写 `docs/demo.md` 五分钟剧本  

**明确不做：** Docker、K8s、数据库、远程执行、AI 解释、FleetScope 中心。

## 5. 验收标准（建议）

- [ ] 夹具路径下 `scan` + `diff` 文档化剧本 5 分钟可完成  
- [ ] Drift JSON 含新增/删除/变化，且至少一类变化带 severity  
- [ ] 证据字段可追溯到两次 snapshotId  
- [ ] 单测覆盖启发式与证据结构  
- [ ] README 快速开始与真实命令一致（不夸大）  

## 6. 风险

- 风险启发式过粗可能误报 → 文档标注「建议级、非策略引擎」  
- 与 lifecycle-spec 字段若不一致 → 先 ADR 再改协议，或产品侧先用扩展字段  
