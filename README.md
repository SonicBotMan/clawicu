# ClawICU

### OpenClaw Emergency Rescue System

<p align="center">

![Version](https://img.shields.io/badge/version-0.2.0-2564eb?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-22c55e?style=for-the-badge)
![OpenClaw](https://img.shields.io/badge/OpenClaw-v2026.4-8b5cf6?style=for-the-badge)
![Issues](https://img.shields.io/badge/Issues-24-ef4444?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-64748b?style=for-the-badge)

</p>

<p align="center">

**[Website](https://xagent.icu)** ·
**[Docs](https://xagent.icu/docs)** ·
**[Rescue Script](https://xagent.icu/rescue.sh)** ·
**[GitHub](https://github.com/SonicBotMan/clawicu)**

</p>

---

<p align="center">

```
██╗    ██╗ █████╗ ███████╗███████╗██╗     ██╗███╗   ██╗███████╗
██║    ██║██╔══██╗██╔════╝██╔════╝██║     ██║████╗  ██║██╔════╝
██║ █╗ ██║███████║███████╗███████╗██║     ██║██╔██╗ ██║█████╗
██║███╗██║██╔══██║╚════██║╚════██║██║     ██║██║╚██╗██║██╔══╝
╚███╔███╔╝██║  ██║███████║███████║███████╗██║██║ ╚████║███████╗
 ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
```

**When OpenClaw breaks, ClawICU rushes in.**

</p>

---

## What

ClawICU is a **rescue system for [OpenClaw](https://github.com/openclaw/openclaw)** — the local-first AI assistant gateway.

OpenClaw manages AI agents, plugins, channels, and system commands. When it fails — pairing errors, cron not running, channel auth issues — ClawICU diagnoses and fixes it.

| | |
|---|---|
| **One command** | `curl -fsSL https://xagent.icu/rescue.sh \| sh` |
| **Or download** | `curl -fsSL https://xagent.icu/rescue.sh -o rescue.sh && chmod +x rescue.sh` |
| **Documentation** | [xagent.icu/docs](https://xagent.icu/docs) — 24 issue guides |
| **Live site** | [xagent.icu](https://xagent.icu) |

---

## How

### 6-Phase Rescue Protocol

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1 · Doctor Check                                          │
│  openclaw doctor + openclaw doctor --fix (auto-applied)          │
├─────────────────────────────────────────────────────────────────┤
│  Phase 2 · Diagnostics                                            │
│  Binary · Process · Config · Disk · Network · State            │
├─────────────────────────────────────────────────────────────────┤
│  Phase 3 · Triage                                                 │
│  Critical ████ or Warning ████ or Stable ████                  │
├─────────────────────────────────────────────────────────────────┤
│  Phase 4 · Treatment Plan                                         │
│  [a] Auto · [1] Quick · [2] Full · [3] Nuclear                 │
├─────────────────────────────────────────────────────────────────┤
│  Phase 5 · Execute                                                │
│  Apply openclaw doctor --fix repairs                            │
├─────────────────────────────────────────────────────────────────┤
│  Phase 6 · Report                                                │
│  Summary + restart instructions                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What `openclaw doctor --fix` Does

| Category | Fixes |
|----------|-------|
| **Legacy Migration** | Sessions, agent, WhatsApp auth state |
| **Config Paths** | xAI / Firecrawl config migration |
| **Channel Config** | Compatibility fixes across platforms |
| **Plugins** | Auto-enable + dependency resolution |
| **Gateway** | Auth token generation |
| **Shell** | Bash / Zsh / Fish completion setup |
| **System** | systemd linger, cron store repair |

---

## 24 Documented Issues

The [issue encyclopedia](https://xagent.icu/docs) covers real OpenClaw problems with diagnosis steps and solutions.

| Severity | Issues |
|----------|--------|
| 🔴 Fatal | Config corruption · Gateway crash · Disk full |
| 🟠 Warning | Pairing not approved · Channel auth failed · Cron not executing |
| 🟡 Info | Browser tool not working · Exec requires approval · Heartbeat not sent |

---

## Architecture

```
clawicu/
│
├── rescue.sh                    # Standalone POSIX shell script
│                                 # No dependencies — curl + sh only
│
└── src/
    ├── app/
    │   ├── page.tsx             # Landing page
    │   └── docs/
    │       ├── page.tsx         # 24-issue grid
    │       └── [slug]/          # Issue detail pages
    │
    └── components/
        ├── Hero.tsx             # ICU Specialist banner
        ├── PatientSymptoms.tsx   # Issue grid with severity badges
        ├── TreatmentPlan.tsx     # 6-phase accordion
        ├── ExaminationProcess.tsx # 4-step flow
        └── QuickStartGuides.tsx  # Links to OpenClaw docs
```

---

## Development

```bash
git clone https://github.com/SonicBotMan/clawicu.git
cd clawicu
npm install
npm run dev      # → localhost:3000
npm run build    # Static export → /out
```

---

## Contributing

Found an unlisted issue? **[Open an issue](https://github.com/SonicBotMan/clawicu/issues)** — contributions welcome.

---

<p align="center">

MIT License · [github.com/SonicBotMan/clawicu](https://github.com/SonicBotMan/clawicu)

**ClawICU — OpenClaw's emergency room.**

</p>

---

# 中文版

<p align="center">

```
██╗    ██╗ █████╗ ███████╗███████╗██╗     ██╗███╗   ██╗███████╗
██║    ██║██╔══██╗██╔════╝██╔════╝██║     ██║████╗  ██║██╔════╝
██║ █╗ ██║███████║███████╗███████╗██║     ██║██╔██╗ ██║█████╗
██║███╗██║██╔══██║╚════██║╚════██║██║     ██║██║╚██╗██║██╔══╝
╚███╔███╔╝██║  ██║███████║███████║███████╗██║██║ ╚████║███████╗
 ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
```

**当 OpenClaw 遇到问题时，ClawICU 紧急救援。**

</p>

---

## 核心功能

| 一键启动 | `curl -fsSL https://xagent.icu/rescue.sh \| sh` |
|---|---|
| 文档站点 | [xagent.icu/docs](https://xagent.icu/docs) — 24 个故障排查指南 |
| 在线访问 | [xagent.icu](https://xagent.icu) |

### 6 阶段救援流程

```
阶段 1 · 医生检查   →  openclaw doctor + openclaw doctor --fix
阶段 2 · 诊断检查   →  二进制 · 进程 · 配置 · 磁盘 · 网络
阶段 3 · 分诊评估   →  危险 / 警告 / 稳定
阶段 4 · 治疗方案   →  自动 / 快速 / 完整 / 重置
阶段 5 · 执行修复   →  应用 openclaw doctor --fix
阶段 6 · 出院报告   →  变更摘要 + 重启指导
```

### openclaw doctor --fix 自动处理

- Legacy state 迁移（sessions、agent、WhatsApp auth）
- xAI / Firecrawl 配置路径迁移
- 通道配置兼容性修复
- 插件自动启用和依赖解析
- Gateway 认证令牌生成
- Shell 补全设置
- systemd linger 配置
- Legacy cron store 修复

---

## 24 个已文档化的问题

[xagent.icu/docs](https://xagent.icu/docs) 记录了真实 OpenClaw 故障的诊断步骤和解决方案。

---

## 开发

```bash
git clone https://github.com/SonicBotMan/clawicu.git
cd clawicu
npm install
npm run dev
```

---

## 参与贡献

发现问题？**[提交 Issue](https://github.com/SonicBotMan/clawicu/issues)** — 欢迎贡献。

---

<p align="center">

MIT License · [github.com/SonicBotMan/clawicu](https://github.com/SonicBotMan/clawicu)

**ClawICU — OpenClaw 的急救室。**

</p>