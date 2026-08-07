# AI DevOps Open Suite

**一句话定位：** AI 原生时代的本地优先开发运维套件——发现机器上真实在跑什么、追踪变化、并把开发到上线的证据串起来。

**专业名称：** AI DevOps Open Suite（开源工具套件）  
**通俗解释：** 一组可以单独安装的小工具；合在一起能回答「改了什么、部署了什么、现在和上次比差在哪」。

> 早期公开开发中。已有可运行的协议、开发周期后端 CLI、Linux 基础设施扫描与快照对比。桌面 UI、多节点监控中心、发布验收工具仍在路线图上。

---

## 为什么需要这个项目

很多团队并不缺监控图表，缺的是**说得清楚的变化与证据**：

- 公司有很多服务器，但没人说得清每台机器**实际**跑了哪些服务、开了哪些端口；
- 项目上线或热修之后，生产环境到底变了什么，常常靠聊天记录和印象；
- 数据库结构或二进制路径悄悄变了，没有可复查的记录；
- 服务迁了机器或改了部署方式，监控和文档跟不上；
- AI 很适合帮忙解释变更，但企业**不希望**把敏感数据默认上传到别人的云。

这个套件的目标是：先用确定性规则把「事实」采下来、对比出来；AI 只作为可选的解释层，并且数据默认留在你自己这边。

---

## 核心能力

用使用者能听懂的话说，这套工具要帮你：

| 你想搞清楚的事 | 我们怎么帮你（通俗） | 对应专业能力 |
|----------------|----------------------|--------------|
| 这台机器上有什么？ | 扫一遍主机、进程、端口、systemd 服务，写出清单 | Inventory / Snapshot（资产清单与标准化快照） |
| 和上次比变了啥？ | 对比两次快照：新增、删除、修改（过滤 PID 等噪声） | Infrastructure Drift（基础设施漂移检测） |
| 这次变化算不算正常？ | 把变化记成可追踪事件，并可挂上证据与发布关联（协议层已定义） | ChangeEvent + Evidence + Classification |
| AI 改了哪些代码？ | 管理需求、验收项、任务，并对应 Git 分支与隔离目录 | Dev cycle：Requirement / Task / Worktree |
| 多个工具如何协作？ | 不互相绑死代码，只交换公开、版本化的数据格式 | lifecycle-spec（开放生命周期协议） |

**现在就能试用的：** Linux（或夹具）扫描 → `inventory.json` / `snapshot.json` → 两次快照 Diff；以及本地 Git 需求/任务/worktree CLI。  
**协议已定义、产品侧待加深的：** 风险等级展示、证据自动绑定、发布关联、多机拓扑。

---

## 设计理念

1. **本地优先** — 默认在你的机器或内网跑，不为「必须上云」而设计。  
2. **数据自主控制** — 清单、快照、证据文件你看得见、管得住；密钥不得进事件明文。  
3. **AI 可选** — 不配模型也能扫描、对比、管 Git；配了模型只做建议，不冒充事实。  
4. **确定性检测优先** — 先解析 `/proc`、systemd、Git 等可复现结果，再谈智能分析。  
5. **变化必须有证据** — 「看起来完成了」不够；验收与变更应能指向测试、日志、确认记录等 Evidence（证据）。

---

## 与传统监控的区别

| | 传统监控 | 本套件（目标能力） |
|--|----------|-------------------|
| 关注点 | CPU、内存、磁盘用量等指标 | **系统里有什么、相对上次变了什么** |
| 视角 | 多为单机指标曲线 | 资源及其关系（主机—服务—端口—进程） |
| 配置方式 | 大量人工配采集与仪表盘 | **自动发现**实际部署，再谈接入监控 |
| AI | 通常没有，或绑定厂商 | 用户自备 API，可选分析；默认关闭 |
| 变化追踪 | 弱，或靠日志海选 | **核心能力**：快照 Diff / 漂移与分类 |
| 与研发关系 | 往往断裂 | 协议打通需求 → 变更 → 发布 → 部署（路线图） |

传统监控仍然重要；本套件不替代 Prometheus 一类时序系统，而是补上「资产与变更事实层」。

---

## 项目组成

四个产品可**单独使用**；需要协作时只依赖开放协议，不依赖彼此内部代码。

| 内部代号 | 公开定位 | GitHub 仓库 | 当前阶段 |
|----------|----------|-------------|----------|
| **DevCycle** | AI 开发生命周期管理：需求、验收、任务、Git 分支与隔离目录（Worktree） | [ai-dev-cycle-manager](https://github.com/GeneJie199/ai-dev-cycle-manager) | 后端 CLI 可用；桌面 UI 待做 |
| **InfraScout** | 基础设施发现与漂移检测：扫主机、出清单/快照、对比变化 | [infrastructure-discovery](https://github.com/GeneJie199/infrastructure-discovery) | Linux 扫描 + Diff 可用 |
| **FleetScope** | 多节点监控、自动拓扑与持续变化观察 | （尚未建仓） | 规划中 |
| **ReleaseGuard** | 发布检查、上线验收与变更关联 | （尚未建仓） | 规划中 |

公共协议仓库：

| 名称 | 作用 | 仓库 |
|------|------|------|
| **lifecycle-spec** | 版本化数据语言（JSON Schema）：资源、证据、快照、变化事件等 | [lifecycle-spec](https://github.com/GeneJie199/lifecycle-spec) |

> 代号仅用于沟通；对外请优先使用上表「公开定位」与仓库名。正式商标/域名检索完成前，代号不等于最终商品名。

---

## 当前状态

**这是早期开发阶段（Foundation / M0–M1 起步），API 与 Schema 在 `0.x` 仍可能调整。**

### 已经完成

- 开放协议 `lifecycle-spec` v0.1：术语、稳定 ID、事件信封、Evidence / ChangeEvent 等 Schema、示例、校验与脱敏测试、Go/TS 类型
- `infrastructure-discovery`：主机 / 进程 / 端口 / systemd 采集，`inventory.json` + `snapshot.json`，快照 Diff（过滤 PID 等噪声），夹具测试可在非 Linux 运行
- `ai-dev-cycle-manager`：导入本地 Git、状态/分支/提交、worktree、需求/验收/任务 SQLite 存储、Diff 读取、Codex 适配器**接口**、CLI demo

### 正在 / 即将推进

- 把 Linux 基础扫描做成**可演示的完整故事**（可读报告、风险提示、证据字段对齐协议）
- DevCycle 桌面前端（Wails + React，由前端同学接手）
- 协议与扫描输出在字段级进一步对齐、减少手写漂移

### 计划中（尚未开始）

- Docker / Compose / 数据库元数据发现  
- FleetScope 多节点中心与 Agent  
- ReleaseGuard 发布验收  
- 多 AI Provider 实现（仅接口预留）

---

## 快速开始

按你关心的问题选一个仓库即可，**不必一次装齐**。

### A. 体验「这台机器有什么 / 和上次比变了什么」（InfraScout）

需要：Go 1.22+。Linux 可实机扫描；Windows/macOS 请用自带夹具。

```bash
git clone https://github.com/GeneJie199/infrastructure-discovery.git
cd infrastructure-discovery
go test ./...
go build -o infra-discovery ./cmd/infra-discovery

# 任意系统：用夹具演示
./infra-discovery scan --fixture ./testdata/host-sample --out ./out1
./infra-discovery scan --fixture ./testdata/host-sample --out ./out2
./infra-discovery diff --baseline ./out1/snapshot.json --candidate ./out2/snapshot.json --out ./drift.json

# 仅 Linux 实机：
# ./infra-discovery scan --out ./out
```

输出：`inventory.json`（资产清单）、`snapshot.json`（标准化快照）、Diff 报告中的新增 / 删除 / 变更。

### B. 体验「需求—任务—Git 隔离目录」（DevCycle 后端）

需要：Go 1.22+、系统已安装 `git`。

```bash
git clone https://github.com/GeneJie199/ai-dev-cycle-manager.git
cd ai-dev-cycle-manager
go test ./...
go run ./cmd/devcycle demo
```

### C. 阅读 / 校验开放协议（lifecycle-spec）

```bash
git clone https://github.com/GeneJie199/lifecycle-spec.git
cd lifecycle-spec
go test ./...
```

---

## 架构说明（稍后阅读）

```text
                    lifecycle-spec（协议）
                           ▲
           仅 JSON 文件 / HTTP，不共享内部包
     ┌─────────────────────┼─────────────────────┐
     │                     │                     │
 DevCycle            InfraScout            FleetScope / ReleaseGuard
（开发过程）          （发现与漂移）            （规划中）
```

要点：

- 产品独立可运行；组合时通过协议增强  
- 第一版不引入 Kafka 等消息总线  
- 时间统一 RFC 3339（带时区）；资源使用稳定 ID（不用 PID 当身份证）  
- 详细设计见各仓 `docs/` 与 [lifecycle-spec 架构](https://github.com/GeneJie199/lifecycle-spec/blob/main/docs/architecture.md)

总体立项草案（内部计划书，非用户手册）见文档仓 [`docs/plan-v0.1.md`](https://github.com/GeneJie199/project-docs/blob/main/docs/plan-v0.1.md)。

---

## 贡献指南

欢迎 Issue 与 PR。请先阅读对应仓库的 `CONTRIBUTING.md`（若有）和本约定：

### 如何提交 Issue

- **Bug：** 复现步骤、期望/实际结果、OS、命令行、相关 JSON 片段（**打码密钥**）  
- **功能建议：** 要解决的场景、是否必须 AI、是否可单机完成  
- **协议变更：** 先讨论；改 Schema 需要 ADR

### 如何贡献代码

1. Fork 目标仓库，**一个任务一条分支**（可用 Git worktree 隔离）  
2. 不要多个 PR 同时改同一核心 Schema 文件  
3. 核心逻辑附带测试；解析器用真实样例/夹具  
4. 用户可见文案尽量同时给**专业名称 + 通俗解释**  
5. 小步提交，说明「为什么」

### 如何报告安全问题

不要在公开 Issue 里贴真实密钥或私钥。参见各仓 `SECURITY.md`（lifecycle-spec 已提供）。

### 行为准则

保持专业、就事论事。恶意或骚扰内容的贡献不予合并。

---

## 许可证

各产品与协议仓库当前采用 **Apache-2.0**（以各仓 `LICENSE` 为准）。

---

## 维护者

- GitHub：[@GeneJie199](https://github.com/GeneJie199)
