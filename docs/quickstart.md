# 安装与快速开始

AI DevOps Open Suite 的四个产品页面和协议校验器可以一次安装，也可以继续独立部署。套件安装器不会安装 Prometheus、Node.js、数据库服务或外部采集器；运行所需的 Web 资源已嵌入二进制。

## 支持平台

- Windows 10/11、Windows Server，x86-64。
- Linux，x86-64 或 ARM64。
- macOS，Intel 或 Apple Silicon。

在线安装需要能够访问 GitHub Releases。安装器会下载每个仓库发布的 `checksums.txt`，校验 SHA-256 后再替换本地二进制。

## 一次安装并启动

从项目的 [Releases](https://github.com/GeneJie199/ai-devops-open-suite/releases) 下载 ZIP 或 TAR 包并解压。

套件版本 `0.3.3` 默认安装产品组件 `0.3.2` 和协议校验器 `0.1.1`。`--version` / `-Version` 用于选择产品组件版本；`--suite-version` / `-SuiteVersion` 仅用于自定义套件控制器显示版本，通常不需要设置。

Windows PowerShell：

```powershell
.\scripts\install-suite.ps1 -Start
```

需要登录后自动恢复全部模块时，用一条命令完成安装、启用自启动并立即启动：

```powershell
.\scripts\install-suite.ps1 -EnableAutostart
```

Linux 或 macOS：

```bash
chmod +x scripts/*.sh
./scripts/install-suite.sh --start
```

Linux/macOS 的安装与自启动：

```bash
./scripts/install-suite.sh --enable-autostart
```

默认安装目录：

| 平台 | 目录 |
|---|---|
| Windows | `%LOCALAPPDATA%\ai-devops-suite` |
| Linux / macOS | `~/.local/share/ai-devops-suite` |

安装完成后，四个入口分别是：

| 模块 | 默认地址 |
|---|---|
| DevCycle | `http://127.0.0.1:8766` |
| InfraScout | `http://127.0.0.1:8765` |
| FleetScope | `http://127.0.0.1:8770` |
| ReleaseGuard | `http://127.0.0.1:8771` |

首次启动会创建本机 Fleet Agent 身份和随机写入令牌。Windows 首次运行 InfraScout 展示安全的示例数据；Linux 会直接建立本机资产基线并持续采集。ReleaseGuard 使用随安装包提供的示例报告作为起始页面，真实发布运行后可替换它。

## 日常管理

Windows：

```powershell
$suite = "$env:LOCALAPPDATA\ai-devops-suite\bin\suitectl.ps1"
powershell -ExecutionPolicy Bypass -File $suite status
powershell -ExecutionPolicy Bypass -File $suite doctor
powershell -ExecutionPolicy Bypass -File $suite open
powershell -ExecutionPolicy Bypass -File $suite logs
powershell -ExecutionPolicy Bypass -File $suite restart
powershell -ExecutionPolicy Bypass -File $suite enable
powershell -ExecutionPolicy Bypass -File $suite disable
powershell -ExecutionPolicy Bypass -File $suite stop
```

Linux 或 macOS：

```bash
suite="$HOME/.local/share/ai-devops-suite/bin/suitectl"
"$suite" status
"$suite" doctor
"$suite" open
"$suite" logs
"$suite" restart
"$suite" enable
"$suite" disable
"$suite" stop
```

`doctor` 会检查五个二进制、数据目录、Fleet 凭据、依赖和端口占用，并用非零退出码报告阻塞项。`enable` 会保存当前端口配置、启用当前用户的开机/登录自启动并立即启动套件；`disable` 只取消后续自启动，不会突然停止正在使用的页面。Windows 使用当前用户启动项，Linux 使用 user systemd，macOS 使用 LaunchAgent，均不要求套件以管理员身份运行。Linux 服务器若需要在用户登录前启动，管理器会尝试启用 linger；系统策略不允许时会打印一条交给管理员执行的命令。

重复执行安装器即可升级或修复二进制；`data/`、`config/` 和已有凭据不会被删除。若套件正在运行，安装器会在全部下载与校验通过后统一停止服务，原子替换二进制，并自动恢复原来的运行状态。下载、校验或替换失败时不会留下混合版本，替换失败还会恢复先前的二进制。

## 自定义目录和端口

Windows 可使用 `-Prefix D:\ai-devops`，Linux/macOS 可使用 `--prefix /opt/ai-devops`。管理器也接受 `AI_DEVOPS_HOME`。

端口可以在启动前通过环境变量覆盖：

```text
AI_DEVOPS_DEVCYCLE_PORT
AI_DEVOPS_INFRASCOUT_PORT
AI_DEVOPS_FLEETSCOPE_PORT
AI_DEVOPS_RELEASEGUARD_PORT
```

首次 `init`、`start` 或 `enable` 会把生效端口写入 `config/ports.env`，后续 `status`、`doctor`、`open` 和自启动会自动沿用；再次提供环境变量即可更新保存值。产品默认只绑定 loopback；需要团队访问时，推荐使用 SSH 隧道或带认证与 TLS 的反向代理，不要直接将服务暴露到公网。

## 离线安装

将五个仓库的发布资产和各自 `checksums.txt` 放成下面的结构：

```text
release-assets/
  lifecycle-spec/
  ai-dev-cycle-manager/
  infrastructure-discovery/
  fleet-observability/
  release-validation/
```

Windows：

```powershell
.\scripts\install-suite.ps1 -SourceRoot D:\release-assets -Start
```

Linux 或 macOS：

```bash
./scripts/install-suite.sh --source-root /mnt/release-assets --start
```

离线模式执行完全相同的 SHA-256 校验，不会因为资产来自本地目录而跳过完整性检查。

## 数据与排障

- `bin/`：经过校验的五个可执行文件和套件管理器。
- `config/`：版本、持久端口、Fleet 写入令牌和自启动引导等本机配置。
- `data/`：SQLite、资产基线、漂移、时序和发布报告。
- `logs/`：每个后台进程的标准输出和错误日志。
- `run/`：仅保存当前由管理器启动的进程 PID。

启动是事务式的：任一模块未就绪，管理器会关闭本次已经拉起的其他模块并清理 PID 文件。PID 文件会与实际二进制路径交叉验证，过期 PID 不会误杀无关进程。先运行 `doctor` 排除安装与端口问题，再运行 `status` 和 `logs` 查看运行状态与最近日志。端口冲突时，停止占用程序或覆盖相应的端口环境变量后执行 `restart`。
