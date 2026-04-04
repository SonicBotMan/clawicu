# ClawICU — OpenClaw Emergency Rescue System

<p align="center">
  <img src="https://img.shields.io/badge/version-0.1.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/shell-POSIX-orange.svg" alt="Shell">
</p>

<p align="center">
  <strong>English</strong> · <a href="#中文">中文</a>
</p>

---

## What is ClawICU?

ClawICU is an intelligent rescue system for [OpenClaw](https://github.com) — an AI-powered DevOps gateway. When OpenClaw breaks, ClawICU fixes it.

OpenClaw manages AI agent workflows, plugin systems, and gateway communications. When it fails — config corruption, port conflicts, plugin crashes, missing credentials — ClawICU steps in.

**One command to diagnose, repair, and revive:**

```bash
curl -fsSL https://xagent.icu/r | sh
```

---

## Features

### 🐚 Shell Rescue Scripts

17 diagnostic checks and 12 repair modules in pure POSIX shell.

| Category | Checks | Repairs |
|----------|--------|---------|
| **Config** | Syntax, schema validation | Restore from backup, reset fields |
| **Gateway** | Health, connectivity | Restart, regenerate certs |
| **Daemon** | Service registration | Reinstall systemd/launchd |
| **Plugins** | Manifest integrity | Disable broken, re-enable healthy |
| **Credentials** | API key presence | Interactive setup |
| **System** | Port, disk, memory, permissions | Kill zombies, free port, clean disk |

### 🌐 Website

| Page | Description |
|------|-------------|
| `/` | Landing page with 17 checks / 12 repairs stats |
| `/rescue` | Interactive 6-phase guided rescue process |
| `/docs` | 15 issue guides with diagnosis steps |
| `/download` | OS detection + offline package download |

### 🔧 API

- `GET /api/v1/rescue-script` — Generate customized rescue script for your OS
- `GET /api/v1/check-version?version=x.x.x` — Check OpenClaw version compatibility

---

## Quick Start

### One-Line Install

```bash
curl -fsSL https://xagent.icu/r | sh
```

### Interactive Menu

```bash
# Download and run
curl -fsSL https://xagent.icu/r -o rescue.sh
chmod +x rescue.sh
./rescue.sh

# Choose option 1 for full diagnosis
# Choose option 7 for Quick-Fix-All (auto-detect and repair)
```

### Offline Install

Download the offline package for your OS:

- [Linux amd64](https://xagent.icu/rescue.sh)
- [macOS arm64](https://xagent.icu/rescue.sh)

---

## Installation Methods

### npm

```bash
npm install -g https://xagent.icu/clawicu-openclaw-0.1.0.tgz
openclaw diagnose
```

### Docker

```bash
# Download image
curl -fsSL https://xagent.icu/openclaw-docker.tar -o /tmp/openclaw.tar
docker load -i /tmp/openclaw.tar

# Run diagnosis
docker run --rm clawicu/openclaw:0.1.0 diagnose
```

### Source

```bash
# Clone from bundle
curl -fsSL https://xagent.icu/openclaw.gitbundle -o /tmp/openclaw.bundle
git clone /tmp/openclaw.bundle openclaw-src
cd openclaw-src && npm install

# Run
node src/cli.js diagnose
```

---

## Architecture

```
clawicu/
├── rescue/
│   ├── lib/          # Shared shell libraries
│   │   ├── bootstrap.sh    # Initialization
│   │   ├── log.sh          # Logging
│   │   ├── ui.sh           # Terminal UI
│   │   ├── backup.sh       # Backup/restore
│   │   ├── state.sh        # State management
│   │   └── verify.sh       # Verification
│   ├── checks/       # 17 diagnostic modules
│   │   ├── check-binary.sh
│   │   ├── check-config.sh
│   │   ├── check-gateway.sh
│   │   └── ...
│   ├── repairs/      # 12 repair modules
│   │   ├── repair-config.sh
│   │   ├── repair-gateway.sh
│   │   └── ...
│   └── rescue.sh     # 6-phase orchestrator
├── src/
│   ├── app/         # Next.js 15 website
│   │   ├── page.tsx             # Landing
│   │   ├── rescue/page.tsx      # Guided rescue
│   │   ├── docs/[slug]/page.tsx # Issue docs
│   │   ├── download/page.tsx    # Downloads
│   │   └── api/                # API routes
│   └── components/   # React components
└── scripts/
    ├── build-rescue.sh      # Bundle modules
    └── package-offline.sh    # Create offline pkg
```

### 6-Phase Rescue Flow

```
Phase 1: Triage        → Run all checks, collect findings
Phase 2: Plan          → Select repair strategy based on findings
Phase 3: Backup        → Snapshot state before changes
Phase 4: Repair       → Execute repair modules
Phase 5: Verify        → Re-run checks to confirm fix
Phase 6: Report        → Summary of changes made
```

---

## Supported Issues

| Issue | Severity | Diagnosis | Repair |
|-------|----------|-----------|--------|
| Config File Corruption | Fatal | JSON5 syntax errors | Restore from .bak |
| Gateway Crash | Fatal | Port 18789 not listening | Restart gateway |
| Plugin Failures | Warn | Broken manifest | Disable .disabled |
| Port Conflict | Fatal | Another process on 18789 | Kill or reconfigure |
| Missing Credentials | Warn | Empty API key files | Interactive setup |
| Daemon Not Installed | Warn | Service not registered | Reinstall service |
| Memory Leak | Fatal | RSS growth over time | Restart + plugin bisect |
| Disk Space Full | Fatal | < 100MB free | Clear logs/sessions |
| Database Locked | Warn | Stale lock files | Remove lock files |
| Version Mismatch | Warn | Protocol incompatibility | Downgrade |

---

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Shell Script Development

```bash
# Run all unit tests
cd tests/unit && sh run-tests.sh

# Test a specific module
sh tests/unit/test-lib-log.sh

# Build bundled rescue script
./scripts/build-rescue.sh
```

---

## Contributing

Contributions are welcome! Please read the issue guides in `/docs` before submitting PRs.

---

## License

MIT License

---

<p align="center">
  <strong>ClawICU — 当 OpenClaw 遇到问题时，它是你的急救室。</strong>
</p>

---

# 中文版

<p align="center">
  <strong>English</strong> · <a href="#clawicu--openclaw-emergency-rescue-system">中文</a>
</p>

---

## 什么是 ClawICU？

ClawICU 是 [OpenClaw](https://github.com) 的急救系统 —— 一个 AI 驱动的 DevOps 网关。当 OpenClaw 出现故障时，ClawICU 来修复它。

OpenClaw 管理 AI agent 工作流、插件系统和网关通信。当它崩溃时 —— 配置损坏、端口冲突、插件崩溃、凭据丢失 —— ClawICU 介入。

**一行命令完成诊断、修复、重启：**

```bash
curl -fsSL https://xagent.icu/r | sh
```

---

## 功能特性

### 🐚 Shell 救援脚本

纯 POSIX shell 编写的 17 个诊断检查 + 12 个修复模块。

| 类别 | 检查模块 | 修复模块 |
|------|---------|---------|
| **配置** | 语法、schema 验证 | 从备份恢复、重置字段 |
| **网关** | 健康状态、连通性 | 重启、重建证书 |
| **守护进程** | 服务注册状态 | 重装 systemd/launchd |
| **插件** | Manifest 完整性 | 禁用损坏插件、重新启用健康插件 |
| **凭据** | API key 是否存在 | 交互式配置 |
| **系统** | 端口、磁盘、内存、权限 | 终止僵尸进程、释放端口、清理磁盘 |

### 🌐 网站

| 页面 | 描述 |
|------|------|
| `/` | 落地页，展示 17 项检查 / 12 项修复 |
| `/rescue` | 交互式 6 阶段引导救援流程 |
| `/docs` | 15 个故障排查指南，含诊断步骤 |
| `/download` | 系统检测 + 离线安装包下载 |

### 🔧 API 接口

- `GET /api/v1/rescue-script` — 根据操作系统生成定制化救援脚本
- `GET /api/v1/check-version?version=x.x.x` — 检查 OpenClaw 版本兼容性

---

## 快速开始

### 一键安装

```bash
curl -fsSL https://xagent.icu/r | sh
```

### 交互式菜单

```bash
# 下载并运行
curl -fsSL https://xagent.icu/r -o rescue.sh
chmod +x rescue.sh
./rescue.sh

# 选择 1 进行完整诊断
# 选择 7 进行 Quick-Fix-All（自动检测并修复）
```

### 离线安装

为你的操作系统下载离线包：

- [Linux amd64](https://xagent.icu/rescue.sh)
- [macOS arm64](https://xagent.icu/rescue.sh)

---

## 安装方式

### npm

```bash
npm install -g https://xagent.icu/clawicu-openclaw-0.1.0.tgz
openclaw diagnose
```

### Docker

```bash
# 下载镜像
curl -fsSL https://xagent.icu/openclaw-docker.tar -o /tmp/openclaw.tar
docker load -i /tmp/openclaw.tar

# 运行诊断
docker run --rm clawicu/openclaw:0.1.0 diagnose
```

### 源码

```bash
# 从 bundle 克隆
curl -fsSL https://xagent.icu/openclaw.gitbundle -o /tmp/openclaw.bundle
git clone /tmp/openclaw.bundle openclaw-src
cd openclaw-src && npm install

# 运行
node src/cli.js diagnose
```

---

## 项目架构

```
clawicu/
├── rescue/
│   ├── lib/          # 共享 shell 库
│   │   ├── bootstrap.sh    # 初始化
│   │   ├── log.sh          # 日志
│   │   ├── ui.sh           # 终端 UI
│   │   ├── backup.sh       # 备份/恢复
│   │   ├── state.sh        # 状态管理
│   │   └── verify.sh      # 验证
│   ├── checks/       # 17 个诊断模块
│   │   ├── check-binary.sh
│   │   ├── check-config.sh
│   │   ├── check-gateway.sh
│   │   └── ...
│   ├── repairs/      # 12 个修复模块
│   │   ├── repair-config.sh
│   │   ├── repair-gateway.sh
│   │   └── ...
│   └── rescue.sh     # 6 阶段编排器
├── src/
│   ├── app/         # Next.js 15 网站
│   │   ├── page.tsx             # 落地页
│   │   ├── rescue/page.tsx      # 引导救援
│   │   ├── docs/[slug]/page.tsx # 故障文档
│   │   ├── download/page.tsx    # 下载页
│   │   └── api/                # API 路由
│   └── components/   # React 组件
└── scripts/
    ├── build-rescue.sh      # 打包模块
    └── package-offline.sh    # 创建离线包
```

### 6 阶段救援流程

```
阶段 1: 分诊        → 运行所有检查，收集结果
阶段 2: 计划        → 根据结果选择修复策略
阶段 3: 备份        → 在修改前创建快照
阶段 4: 修复        → 执行修复模块
阶段 5: 验证        → 重新运行检查确认修复
阶段 6: 报告        → 变更摘要
```

---

## 支持的故障类型

| 故障 | 严重程度 | 诊断方式 | 修复方法 |
|------|---------|---------|---------|
| 配置文件损坏 | 致命 | JSON5 语法错误 | 从 .bak 恢复 |
| 网关崩溃 | 致命 | 18789 端口未监听 | 重启网关 |
| 插件加载失败 | 警告 | Manifest 损坏 | 禁用 .disabled |
| 端口冲突 | 致命 | 18789 被占用 | 终止或重配端口 |
| 凭据缺失 | 警告 | API key 文件为空 | 交互式配置 |
| 守护进程未安装 | 警告 | 服务未注册 | 重装服务 |
| 内存泄漏 | 致命 | RSS 持续增长 | 重启 + 插件二分排查 |
| 磁盘空间不足 | 致命 | 可用空间 < 100MB | 清理日志/会话 |
| 数据库锁定 | 警告 | 遗留锁文件 | 删除锁文件 |
| 版本不匹配 | 警告 | 协议不兼容 | 降级版本 |

---

## 开发

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 运行测试
npm test

# 生产构建
npm run build
```

### Shell 脚本开发

```bash
# 运行所有单元测试
cd tests/unit && sh run-tests.sh

# 测试特定模块
sh tests/unit/test-lib-log.sh

# 构建打包后的救援脚本
./scripts/build-rescue.sh
```

---

## 参与贡献

欢迎提交贡献！提交 PR 前请先阅读 `/docs` 中的故障排查指南。

---

## 许可证

MIT License

---

<p align="center">
  <strong>ClawICU — 当 OpenClaw 遇到问题时，它是你的急救室。</strong>
</p>
