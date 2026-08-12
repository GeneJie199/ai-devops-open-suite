# AI 原生开发与运维开源工具套件总体计划书

版本：V0.1  
日期：2026-08-03  
状态：立项草案，可用于启动研发

> 注意：文中的“DevCycle、FleetScope、ReleaseGuard、InfraScout”均仅作为内部代号。公开发布前必须重新完成项目命名、GitHub 仓库名、域名和商标检索。

---

## 1. 项目愿景

建设一组面向 AI 开发时代的开源工具，覆盖从需求形成、AI 协作开发、代码变更理解、发布验收，到基础设施发现、运行监控、变更漂移和自动拓扑的完整周期。

四个项目必须满足：

1. 可以单独安装、单独使用；
2. 不要求用户同时部署整套系统；
3. 通过公开、版本化的数据协议互相协作；
4. AI 功能全部可选，用户自行配置模型 API；
5. 未配置 AI 时，所有确定性核心功能仍能正常运行；
6. 默认本地优先、隐私优先、证据优先；
7. 面向专业开发者，也要让非专业开发者看得懂。

完整链路：

```text
需求与验收标准
    ↓
AI 协作开发与 Git 变更
    ↓
发布前检查与上线验收
    ↓
机器实际部署状态
    ↓
运行指标、拓扑、漂移与故障
```

---

## 2. 四个项目的产品边界

### 2.1 项目 A：AI 开发周期管理工具

内部代号：DevCycle

#### 核心定位

面向 AI 辅助开发和非专业开发者的“需求—任务—AI 会话—Git 变更—验收证据”管理工具。

它不替代 Codex、Claude Code、Cursor、Gemini CLI 或 IDE，而是管理这些工具产生的工作过程和结果。

#### 主要回答

- 这个需求为什么做？
- 分配给了哪个 AI？
- AI 修改了什么？
- 这些 Git 变更用通俗语言怎么解释？
- 是否满足最初的验收标准？
- 哪些项目风险仍未解决？
- 是否可以进入发布候选状态？

#### MVP 功能

1. 导入本地 Git 仓库；
2. 创建需求、用户故事和验收标准；
3. AI 可选生成验收标准提示词；
4. 将需求拆分成任务；
5. 为任务创建 branch 和 Git worktree；
6. 通过适配器启动 Codex CLI、Claude Code 等外部 Agent；
7. 记录任务、Agent、会话、分支、提交之间的关系；
8. 显示文件级和提交级 Diff；
9. 生成通俗版变更解释；
10. 分析用户影响、接口影响、数据库影响、配置影响和风险；
11. 执行用户配置的 build、test、lint 命令；
12. 将测试结果、截图、日志和人工确认绑定到验收项；
13. 生成开发完成报告；
14. 输出发布候选清单，供发布工具读取。

#### 非专业用户模式

界面同时显示通俗名称和真实 Git 概念：

- 独立工作版本（Branch）
- 修改保存点（Commit）
- 本次改动（Diff）
- 合入主版本（Merge）
- 改动冲突（Conflict）
- 隔离开发目录（Worktree）
- 撤销本次修改（Revert）

#### 明确不做

- 不开发内置代码编辑器；
- 不重新实现一个 AI 编程 Agent；
- 不做完整 Jira 或项目管理平台；
- 不自动判断代码“绝对正确”；
- 不在用户未确认时自动合并或发布；
- 不把多 Agent 窗口当作主要差异点。

#### 核心差异点

1. 需求、验收、AI 会话、Git Diff 和证据的完整追踪；
2. 把代码变化翻译成产品和业务影响；
3. 面向非专业开发者设计 Git 可视化；
4. 验收项必须绑定证据，而不是只显示“AI 已完成”；
5. 支持多个 AI，但不绑定任何一家模型或客户端。

---

### 2.2 项目 B：基础设施发现与漂移工具

内部代号：InfraScout

#### 核心定位

发现机器上实际运行了什么、部署在哪里、使用什么方式部署、开放了哪些服务、依赖哪些数据库，并持续对比变化。

#### 主要回答

- 这台机器部署了什么？
- 服务在哪个目录、容器或 systemd 单元中？
- 哪些进程正在对外监听？
- 哪些服务可能被公网或监控中心访问？
- 机器适合启用哪些监控采集器？
- 与上一次扫描相比发生了什么变化？
- 变化是预期、批准、临时允许、未知还是禁止？
- 数据库表、字段、索引、权限是否发生变化？

#### MVP 扫描范围

操作系统：Linux。

部署方式：

- Docker；
- Docker Compose；
- systemd；
- 普通直接运行进程；
- Node.js、Java、Python、PHP-FPM 常见运行方式。

服务识别：

- Nginx；
- PostgreSQL；
- MySQL；
- Redis；
- HTTP 服务；
- TLS 域名；
- 监听端口；
- Docker 网络和数据卷。

输出：

- 终端摘要；
- inventory.json；
- snapshot.json；
- drift-report.json；
- monitoring-plan.yaml；
- HTML 报告；
- 可选 AI 分析。

#### 快照与 Diff

扫描时生成标准化快照，过滤 PID、容器临时 ID、启动时间等易变噪声字段。

变化类型：

- 新增；
- 删除；
- 修改；
- 迁移；
- 暴露范围变化；
- 部署方式变化；
- 依赖关系变化；
- 数据库元数据变化。

变化分类：

1. expected：来自正式发布声明的预期变化；
2. approved：人工确认并接受的变化；
3. temporary：在时间窗口内临时允许；
4. unexpected：未找到来源的未知变化；
5. denied：违反明确禁止策略的变化。

#### 数据库元数据监控

PostgreSQL 和 MySQL 第一版至少覆盖：

- 数据库、Schema；
- 表和字段；
- 字段类型、NULL、默认值；
- 主键、索引、唯一约束、外键；
- 视图；
- 触发器；
- 函数或存储过程；
- 数据库用户和权限摘要；
- 字符集、排序规则和关键参数。

默认只采集结构和权限元数据，不采集业务表数据。

#### 明确不做

- 不做漏洞扫描器；
- 不做完整 SIEM；
- 不做全网段资产扫描；
- 不自动修改防火墙；
- 不默认读取完整环境变量值；
- 不自动执行修复；
- 第一版不支持 Kubernetes、Windows 和云账号扫描。

---

### 2.3 项目 C：多节点一体化监控与拓扑工具

内部代号：FleetScope

#### 核心定位

面向多机器、多节点、多数据库和多业务服务的“舰队式”监控平台，采集、存储、展示、拓扑、漂移、告警和 AI 分析一体化。

#### 主要回答

- 整个资源组现在是否健康？
- 哪几台机器最需要处理？
- 多个数据库实例横向比较有什么异常？
- 服务部署在哪里、依赖谁、影响谁？
- 最近发生了哪些基础设施、数据库和拓扑变化？
- 故障是否与发布或配置变化有关？
- 当前监控是否存在空白？

#### 架构模式

```text
FleetScope Agent（多台机器）
          ↓ 主动连接、mTLS
FleetScope Center
          ↓
指标、事件、快照、拓扑、告警和 AI 分析
```

Agent 默认主动连接中心端，不要求每台被监控机器开放新的入站端口。

#### MVP 采集范围

- Linux 主机；
- CPU、内存、负载、磁盘、网络；
- 进程和 systemd 状态；
- Docker 容器状态、资源、退出码、OOM 和事件；
- Nginx；
- PostgreSQL；
- MySQL；
- Redis；
- HTTP 可用性；
- TLS 证书；
- 基础部署事件；
- InfraScout 快照和 Diff。

#### 预置页面

1. 全局健康矩阵；
2. 多机器横向比较；
3. 多数据库横向比较；
4. 服务健康视图；
5. 异常优先列表；
6. 自动拓扑；
7. 基础设施变化中心；
8. 数据库元数据变化；
9. 告警和事件中心；
10. AI 分析报告。

首页不采用大量单机指针盘。默认按照严重程度排序，并突出“需要处理的对象”。

#### 自动拓扑

用户创建资源组，将若干机器、数据库、域名或外部服务加入资源组后，系统自动生成拓扑。

拓扑视角：

- 部署拓扑：什么部署在哪里；
- 服务依赖拓扑：服务之间如何调用；
- 网络暴露拓扑：哪些端口和域名对外；
- 数据库拓扑：哪些应用依赖哪些数据库；
- 监控覆盖拓扑：哪些资源缺少采集器；
- 故障影响拓扑：某节点异常会影响什么。

关系发现证据：

- Docker Compose 标签和网络；
- systemd 配置；
- Nginx 反向代理；
- 监听端口；
- 进程网络连接；
- 应用配置摘要；
- OpenTelemetry Trace；
- 人工定义。

每条关系必须包含：

- 关系类型；
- 置信度；
- 发现来源；
- 首次发现时间；
- 最后发现时间；
- 用户确认状态。

#### 拓扑 Diff

需要监控：

- 节点新增或删除；
- 服务迁移；
- 新增依赖；
- 依赖消失；
- 数据库连接目标变化；
- 代理目标变化；
- 主从角色变化；
- 版本不一致；
- 监控覆盖变化。

#### 漂移中心

FleetScope 持续执行或接收 InfraScout 扫描结果，维护：

- Desired State：期望状态；
- Approved State：当前批准状态；
- Observed State：实际观察状态。

允许用户：

- 批准变化；
- 设置为新基线；
- 临时允许到指定时间；
- 忽略某类噪声；
- 关联发布或工单；
- 触发告警推送。

#### AI 分析

确定性程序负责发现异常、计算 Diff、关联资源和匹配规则；AI 只负责解释和建议。

AI 输入必须是经过压缩和脱敏的证据包，包括：

- 异常时间窗口；
- 指标变化；
- 相关日志摘要；
- 最近发布；
- 基础设施变化；
- 数据库变化；
- 拓扑关系；
- 已执行检查。

AI 输出必须包含：

- 结论；
- 依据；
- 不确定性；
- 建议检查步骤；
- 禁止把推测伪装成事实。

#### 明确不做

- 不做 Grafana 的自由拖拽克隆；
- 不在第一版实现完整日志平台；
- 不在第一版实现完整链路追踪后端；
- 不重新开发时序数据库；
- 不第一版支持 Kubernetes、Windows、SNMP；
- 不允许 AI 自动执行生产修复。

---

### 2.4 项目 D：发布验收与变更关联工具

内部代号：ReleaseGuard

#### 核心定位

管理发布前风险检查、发布清单、预期变化、上线验收、观察窗口和回滚准备，并把发布与开发记录、基础设施实际状态和监控异常关联起来。

#### 主要回答

- 这个版本包含什么变化？
- 数据库和环境变量是否变化？
- 是否具备回滚条件？
- 哪些变化是本次发布预期产生的？
- 所有目标节点是否运行同一版本？
- 上线后核心功能是否通过？
- 上线后的异常是否可能由本次发布引起？

#### MVP 功能

1. 读取 Git commit 范围；
2. 读取 DevCycle 导出的发布候选；
3. 检查数据库迁移、环境变量、Compose、健康检查；
4. 生成不可变发布清单；
5. 声明 expected changes；
6. 执行 HTTP、JSON、Shell、SQL 只读和 Playwright 冒烟测试；
7. 验证目标节点实际运行版本和镜像摘要；
8. 发布后进入观察窗口；
9. 从 FleetScope 获取发布前后指标和告警；
10. 输出 GO、HOLD、NO-GO 建议，但最终由用户确认；
11. 生成回滚清单和发布报告。

#### 明确不做

- 不自己实现完整 CI/CD Runner；
- 不替代 GitHub Actions、GitLab CI 或 Jenkins；
- 不自动执行数据库回滚；
- 不在缺乏证据时自动回滚生产环境；
- 不做制品安全扫描大而全平台。

---

## 3. 项目协作关系

四个项目不能互相强依赖。

```text
只使用开发周期工具：可以
只使用基础设施发现工具：可以
只使用监控工具：可以
只使用发布工具：可以

安装两个或多个：通过公开协议增强能力
```

协作链路：

```text
开发周期工具
输出需求、验收、提交和发布候选
       ↓
发布工具
输出发布清单、预期变化和观察窗口
       ↓
基础设施发现工具
输出实际部署、快照和变化
       ↓
监控工具
输出指标、拓扑、漂移、告警和事件
```

---

## 4. 开放协议与共享数据模型

建立单独仓库：`lifecycle-spec`。

只包含：

- JSON Schema；
- Protobuf；
- 示例数据；
- 兼容性测试；
- 版本升级规则；
- 多语言生成代码；
- 协议文档。

### 4.1 核心对象

1. Project：项目；
2. Requirement：需求；
3. AcceptanceCriterion：验收项；
4. Task：开发任务；
5. AgentSession：AI 会话；
6. CodeChange：代码变化；
7. Evidence：证据；
8. Release：发布；
9. Resource：机器、服务、容器、数据库等资源；
10. Relationship：资源关系；
11. Observation：一次观察结果；
12. Snapshot：标准化快照；
13. ChangeEvent：变化事件；
14. Approval：批准或临时允许；
15. Incident：事件或故障；
16. MonitoringRecommendation：监控建议。

### 4.2 统一事件信封

```json
{
  "specVersion": "0.1.0",
  "eventId": "evt_xxx",
  "eventType": "database.schema.changed",
  "occurredAt": "2026-08-03T16:00:00+08:00",
  "source": {
    "product": "infrastructure-discovery",
    "instanceId": "scanner-prod-01"
  },
  "context": {
    "projectId": "songyuege",
    "environment": "production",
    "resourceGroupId": "rg_prod"
  },
  "subject": {
    "resourceId": "postgresql:mall-production",
    "resourceType": "postgresql.column",
    "path": "public.orders.expire_at"
  },
  "classification": "expected",
  "severity": "info",
  "releaseId": "release_2.5.0",
  "evidence": [],
  "payload": {}
}
```

### 4.3 协议原则

- 所有 ID 稳定且可跨项目引用；
- 事件不可原地修改，修正通过新事件完成；
- Schema 必须版本化；
- 新增字段默认向后兼容；
- 不在协议中包含明文密钥；
- 协议不要求使用某一种数据库或消息队列；
- 项目之间优先通过文件、Webhook 和 HTTP API 交换数据；
- 第一版不引入复杂消息总线。

---

> 历史说明：本文件记录最初立项思路。监控部分关于外部 Collector、VictoriaMetrics 和“时序存储不自研”的建议已被 [原生可观测架构决策](native-observability-architecture.md) 取代；当前实现与交付边界以该决策和各产品 README 为准。

## 5. 推荐技术架构

### 5.1 统一技术栈

为降低维护成本，后端、Agent 和 CLI 优先使用 Go。

前端统一使用：

- React；
- TypeScript；
- Vite；
- 统一组件和设计 Token，但不强制共享整个前端工程。

### 5.2 各项目技术选择

#### 开发周期工具

- 桌面端：Wails + Go + React；
- 本地数据库：SQLite；
- Git 操作：优先调用系统 Git CLI；
- Agent 终端：PTY；
- 本地任务和会话存储；
- 可选本地 HTTP API，供其他工具读取。

#### 基础设施发现工具

- Go CLI 和 Go Library；
- Linux `/proc`、systemd、Docker API、配置解析；
- 数据库元数据适配器；
- JSON、YAML 和 HTML 输出；
- 无中心端也能运行。

#### 监控工具

- Center API：Go；
- Agent：Go；
- Agent 通信：gRPC + Protobuf + mTLS；
- 业务和配置数据：PostgreSQL；
- 时序指标：VictoriaMetrics 单节点起步；
- Web：React + TypeScript；
- 告警：内置规则引擎，后续兼容 Prometheus 规则；
- 遥测兼容：Prometheus Remote Write、OpenTelemetry OTLP；
- 第一版不引入 Kafka。

#### 发布工具

- Go CLI + 可选 Server；
- SQLite 或 PostgreSQL；
- 可嵌入 GitHub Actions、GitLab CI、Jenkins；
- Playwright 测试通过外部命令执行；
- 输出发布清单和 expected changes。

### 5.3 不重复造轮子

- 时序存储使用成熟 TSDB；
- 接收标准指标时兼容 Prometheus Remote Write；
- 接收标准遥测时兼容 OpenTelemetry；
- Docker 变化优先监听 Docker Events，并用周期快照校准；
- PostgreSQL DDL 可通过 Event Trigger 增强实时性；
- MySQL 第一版通过 INFORMATION_SCHEMA 快照 Diff；
- Git 多任务隔离使用 Git worktree；
- 数据库结构 Diff 可调用成熟解析器，但统一转换成自己的变化事件。

---

## 6. AI Provider 设计

建立统一但可复制实现的 Provider Interface，不让四个项目共享强耦合运行库。

### 6.1 第一版支持

- OpenAI Compatible；
- Anthropic；
- Gemini；
- OpenRouter；
- Ollama 或本地 OpenAI 兼容接口。

### 6.2 必须遵守

1. AI 功能默认关闭；
2. API Key 通过环境变量、系统密钥链或加密存储读取；
3. 发送前展示数据预览；
4. 默认脱敏密钥、Token、密码、私钥和连接串；
5. 用户可以禁止发送源代码；
6. 用户可以限制每日预算和最大输入 Token；
7. AI 结果必须保存模型、提示词版本和输入证据摘要；
8. AI 结果只能标记为建议，不得覆盖确定性事实；
9. AI 调用失败不能影响基础功能。

### 6.3 AI 功能分配

开发周期工具：

- 生成验收标准；
- 通俗解释 Diff；
- 识别可能风险；
- 生成 Agent 交接摘要。

基础设施发现工具：

- 解释资产结构；
- 分析监控缺口；
- 给出风险建议；
- 生成基础设施交接报告。

监控工具：

- 告警解释；
- 故障证据关联；
- 拓扑影响分析；
- 故障报告和排查建议。

发布工具：

- 发布风险摘要；
- 生成验收方案；
- 分析发布与异常关联；
- 生成回滚检查清单。

---

## 7. 安全与隐私要求

### Agent 权限

- 默认非 root 运行；
- 需要特权采集时单独声明；
- 每个采集器独立权限；
- 不默认提供远程命令执行；
- Agent 不保存中心端管理密码；
- 中心端不能任意读取主机文件。

### 数据保护

- Agent 到中心端使用 mTLS；
- 敏感字段在 Agent 侧先脱敏；
- 环境变量默认只采集名称，不采集值；
- 数据库监控账号默认只读；
- 数据库结构监控与业务数据采集严格分离；
- 所有批准、基线修改和告警关闭必须保留审计记录。

---

## 8. 仓库规划

建议建立一个 GitHub Organization，使用独立仓库：

```text
lifecycle-spec             公共协议和 Schema
ai-dev-cycle-manager       AI 开发周期管理工具
infrastructure-discovery   基础设施发现和 Drift CLI
fleet-observability        多节点监控、拓扑和变化中心
release-validation         发布验收和观察工具
project-docs               总体文档和演示环境，可选
```

各仓库内部统一：

```text
/docs
  vision.md
  architecture.md
  security.md
  data-model.md
  roadmap.md
  adr/
/specs
  requirements/
  acceptance/
/examples
/internal 或 src
/tests
/scripts
```

每个仓库必须包含：

- README；
- LICENSE；
- SECURITY.md；
- CONTRIBUTING.md；
- CODE_OF_CONDUCT.md；
- Issue 模板；
- Pull Request 模板；
- 架构决策记录模板；
- 自动测试和构建工作流；
- 示例配置；
- 演示截图或录屏脚本。

---

## 9. 开源和许可策略

公开前必须确定商业模式，再选择许可证。

建议选项：

### 方案 A：优先传播

- 所有项目 Apache-2.0；
- 企业能力通过托管服务、支持、定制和插件收费。

### 方案 B：防止云厂商直接闭源托管

- 协议、Agent、CLI、SDK：Apache-2.0；
- FleetScope Center 和 Web：AGPL-3.0；
- 企业插件采用商业许可证。

不要在首个公开版本之后频繁更改许可证。

---

## 10. 研发里程碑

不按时间估算，按可验收的垂直切片推进。

### M0：项目治理与协议基础

交付：

- 建立 Organization 和仓库；
- 确定正式命名；
- 确定许可证；
- 建立 `lifecycle-spec`；
- 定义 Resource、ChangeEvent、Evidence、Release、Relationship；
- 提供 Schema 校验和示例；
- 建立 CI、代码规范和 ADR 流程。

验收：

- 示例 JSON 全部通过 Schema 校验；
- Go 和 TypeScript 能生成类型；
- 协议升级有兼容性测试；
- 四个项目都能引用协议，但不依赖彼此运行。

### M1：开发周期工具首个闭环

交付：

- 导入 Git 项目；
- 创建需求和验收标准；
- 创建 branch/worktree；
- 启动一个 Codex CLI 适配器；
- 显示 Diff；
- 通俗解释变更；
- 执行测试命令；
- 绑定验收证据；
- 导出开发完成报告。

验收场景：

使用一个真实项目完成“新增邀请码注册”功能，工具能够从需求一直追踪到 Diff、测试和人工验收。

### M2：基础设施发现首个闭环

交付：

- Linux 主机扫描；
- Docker、Compose、systemd、进程和端口识别；
- Nginx、PostgreSQL、MySQL、Redis 识别；
- 生成 inventory、snapshot 和 HTML 报告；
- 两次快照生成结构化 Diff；
- 生成监控接入建议。

验收场景：

在一台包含 Nginx、API、MySQL 和 Redis 的服务器上，正确识别部署位置、运行方式、端口、数据卷和建议采集器。

### M3：监控平台基础闭环

交付：

- Center 和 Agent；
- Agent 注册和 mTLS；
- 主机、Docker、数据库基础指标；
- 多机器健康矩阵；
- 多数据库横向视图；
- 预置告警；
- 邮件和 Webhook 推送；
- 用户自配 AI API；
- 单次告警 AI 解释。

验收场景：

五台机器和三个数据库接入后，用户在一个页面能快速识别最严重的节点和原因。

### M4：漂移和数据库元数据

交付：

- InfraScout 定期快照；
- FleetScope 变化中心；
- expected、approved、temporary、unexpected、denied 分类；
- 人工批准和临时允许；
- PostgreSQL/MySQL Schema Diff；
- Docker 和 systemd 变化聚合；
- 变化告警推送；
- AI 变化解释。

验收场景：

手工删除数据库字段、开放新端口、修改 Docker 镜像后，系统能发现、分类、显示证据并推送告警。

### M5：自动拓扑

交付：

- 资源组；
- 节点和关系图模型；
- Docker、Nginx、进程连接和数据库依赖自动发现；
- 关系置信度和证据；
- 部署、服务、暴露、数据库、监控覆盖视角；
- 用户确认或修正关系；
- 拓扑 Diff；
- 故障影响分析。

验收场景：

将五台机器加入资源组后，自动生成“入口—网关—API—数据库—缓存—对象存储”拓扑，并能显示新增依赖和版本不一致。

### M6：发布验收闭环

交付：

- 发布候选导入；
- Git、迁移和环境变量检查；
- expected changes；
- 发布清单；
- 冒烟测试；
- 实际版本核对；
- 发布观察窗口；
- 监控基线对比；
- GO、HOLD、NO-GO 报告。

验收场景：

发布一个包含数据库字段新增和 API 镜像升级的版本，系统正确识别预期变化，并将额外出现的未知端口标记为异常。

### M7：四项目协作演示

完整演示：

1. 创建需求；
2. Codex 完成代码；
3. 生成验收报告；
4. 创建发布候选；
5. 发布到三台 API 节点；
6. InfraScout 确认实际部署；
7. FleetScope 观察指标和拓扑；
8. 模拟一个节点版本未更新；
9. 系统关联需求、提交、发布、拓扑和异常；
10. 输出故障原因和回滚建议。

---

## 11. 第一批开发任务

### Foundation

- FND-001：创建公共术语表；
- FND-002：定义资源 ID 规范；
- FND-003：定义统一事件信封；
- FND-004：定义 Evidence Schema；
- FND-005：定义 ChangeEvent Schema；
- FND-006：建立 Schema 兼容性测试；
- FND-007：建立 Go 和 TypeScript 类型生成；
- FND-008：编写安全和脱敏规范。

### AI 开发周期工具

- DEV-001：创建 Wails + React 项目；
- DEV-002：实现本地项目导入；
- DEV-003：实现 Git 状态和提交读取；
- DEV-004：实现 worktree 创建、列出和删除；
- DEV-005：定义 Requirement、Task、Acceptance 数据库模型；
- DEV-006：实现 Codex CLI Adapter；
- DEV-007：实现 Agent 会话与任务关联；
- DEV-008：实现 Diff 解析和文件分类；
- DEV-009：实现确定性变更摘要；
- DEV-010：实现 AI Provider 和发送预览；
- DEV-011：实现测试命令执行和证据记录；
- DEV-012：实现验收报告导出。

### 基础设施发现工具

- INF-001：定义 Inventory 和 Snapshot 模型；
- INF-002：采集 Linux 主机基础信息；
- INF-003：采集进程、端口和进程目录；
- INF-004：识别 systemd 服务；
- INF-005：识别 Docker 和 Compose；
- INF-006：解析 Nginx 反向代理；
- INF-007：识别 PostgreSQL、MySQL、Redis；
- INF-008：实现快照标准化；
- INF-009：实现 Diff 引擎；
- INF-010：实现监控推荐规则；
- INF-011：输出 JSON、YAML 和 HTML。

第一轮只同时启动 Foundation、DEV-001 至 DEV-005、INF-001 至 INF-004。其他任务必须等待基础模型稳定，避免多个 Agent 同时修改核心 Schema。

---

## 12. 多 AI 协作开发规则

1. 每个任务使用独立 branch 和 worktree；
2. 一个 Agent 一次只负责一个任务；
3. Agent 不得自行修改公共 Schema；
4. 修改公共 Schema 必须先建立 ADR；
5. 每个任务必须写明输入、输出和验收标准；
6. 不允许以 TODO、Mock 或空实现冒充完成；
7. 提交必须小而清晰；
8. 每个提交附带通俗变更说明；
9. 核心逻辑必须有单元测试；
10. 解析器必须提供真实样例测试；
11. 安全相关功能必须有负面测试；
12. AI 生成结果不得直接作为确定性测试依据；
13. 合并前由另一个 Agent 或人工执行 Review；
14. 不允许多个 Agent 同时修改同一个核心文件；
15. 每个里程碑必须完成端到端演示后才能扩展范围。

---

## 13. Definition of Done

一个任务只有同时满足以下条件才算完成：

- 功能代码已实现；
- 测试已通过；
- 错误处理完整；
- 不包含已知明文密钥；
- 文档已更新；
- 示例可以运行；
- 验收标准逐项有证据；
- Git Diff 已审查；
- 没有无说明的依赖升级；
- 没有超出任务范围的大规模重构；
- 对外 Schema 和 API 有兼容性说明；
- 用户可见文字提供通俗表达。

---

## 14. 当前最优开工顺序

```text
第一步：公共协议和术语
       ↓
第二步：AI 开发周期工具的最小闭环
       ↓
第三步：基础设施发现和快照 Diff
       ↓
第四步：FleetScope Center、Agent 和多节点矩阵
       ↓
第五步：漂移、数据库元数据和告警
       ↓
第六步：自动拓扑
       ↓
第七步：发布验收和四项目联动
```

不要同时开发四个完整产品。先让开发周期工具管理后续项目，再让基础设施发现核心成为 FleetScope Agent 的发现模块，最后用发布工具把开发和运行数据连接起来。

---

## 15. 立项成功标准

首个公开可用版本不以功能数量判断，而以以下结果判断：

1. 非专业开发者能看懂一次 AI 代码修改；
2. 用户能把验收标准与真实证据绑定；
3. 一条命令能发现 Linux 机器的主要部署；
4. 多机器和多数据库能在一个页面横向比较；
5. 系统能发现基础设施和数据库元数据变化；
6. 系统能区分预期变化和未知变化；
7. 多台机器能够自动生成可解释的资源拓扑；
8. 用户自己的 AI API 能基于证据分析，而不是胡乱猜测；
9. 四个项目在没有彼此的情况下仍能独立工作；
10. 四个项目组合后能追踪“需求—代码—发布—部署—运行—故障”的完整链路。
