# 命名与文档审计备忘

**专业名称：** Naming & Documentation Audit  
**通俗解释：** 把对外说法统一，避免访客看到任务编号或互相矛盾的名字。

审计日期：2026-08-07

## 1. 统一命名表

| 对外/沟通名（代号） | GitHub 仓库 | 协议 `source.product` | 说明 |
|---------------------|-------------|------------------------|------|
| DevCycle | `ai-dev-cycle-manager` | `dev-cycle` | AI 开发生命周期 |
| InfraScout | `infrastructure-discovery` | `infra-discovery` | 基础设施发现与漂移 |
| FleetScope | （未建仓） | `fleet-observability` | 多节点监控与拓扑 |
| ReleaseGuard | （未建仓） | `release-validation` | 发布验收 |
| lifecycle-spec | `lifecycle-spec` | `lifecycle-spec` | 开放协议 |

规则：README 首屏用代号 + 一句话定位；集成代码用 `source.product` 短名；仓库 URL 用 GitHub 名。

## 2. 发现的问题与处理

| 问题 | 处理 |
|------|------|
| 各仓 README 偏任务编号（FND/DEV/INF） | 已改写为场景化对外 README |
| `checkpoint-*.md` 像产品文档 | 已标注「内部里程碑备忘」 |
| 架构图仅写短名 | 已改为代号 + 短名对照 |
| CONTRIBUTING 过简且英文任务口吻 | lifecycle-spec 已重写 |
| 套件无对外主页仓 | 新建 `project-docs` |
| DriftReport 尚无风险等级/证据字段 | 记入下一阶段计划，不在文档中宣称已具备 |
| 立项计划书偏长、内部向 | 放入 `docs/plan-v0.1.md`，README 不链为首要入口 |

## 3. 仍待清理（不阻塞）

- 各仓尚无统一的 Issue / PR 模板  
- DevCycle / InfraScout 尚无独立 `docs/architecture.md`（可链到套件与协议仓）  
- 正式产品商标名未定，代号可能更换  
- `project-docs` 与本地 `ai-devops/README.md` 需保持同步（同源复制）

## 4. 术语书写约定

对外首次出现时使用：

> **Infrastructure Drift（基础设施漂移）**：服务器、服务、数据库等**实际状态**偏离基线或预期状态。

禁止仅甩 Schema 类型名而不解释。
