<div align="center">

# ai-kb

**把每天的 AI 对话变成可面试的本地知识库**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![OpenClaw](https://img.shields.io/badge/Built%20for-OpenClaw-orange.svg)](https://docs.openclaw.ai)
[![Obsidian](https://img.shields.io/badge/Writes%20to-Obsidian-7c3aed.svg)](https://obsidian.md)

[English](#english) | [中文](#中文)

</div>

---

## 中文

**ai-kb** 是一个本地 AI 会话知识库工具——每天 22:00 自动从 **ChatGPT / Codex / Claude Code** 三源抓取当天对话，按 8 章结构（背景 / 核心概念 / 底层原理 / 关键代码 / 项目实战 / 面试回答模板 / 常见误区）提炼为可复用的技术文档，自动写入 Obsidian Vault 并按 6 大分类（视频与编码 / iOS / Android / 工程化 / 面试项目）归档、内置去重机制，专为开发者打造，把"每天和 AI 聊的技术细节"变成"面试能讲出来的项目经验和基础知识"。提供 **bash 一键安装** + **OpenClaw 对话式部署**两种方式，5 分钟完成部署、零运维跑起来。

### ✨ 核心特性

- 🗣️ **对话式部署** — 在 OpenClaw 对话说"安装 ai-kb"即可完成全套配置
- ⏰ **全自动运行** — 每天 22:00 (Asia/Shanghai) cron 自动跑
- 🔍 **智能去重** — 写新知识前必读所有概要，30%+ 重叠自动合并
- 📚 **8 章结构** — 背景→概念→原理→代码→实战→面试→误区，零错误模板
- 🎯 **面试导向** — 强制含 3-5 题面试回答模板 + 项目实战 5 段
- 📂 **6 大分类** — 视频与编码 / iOS-基础 / iOS-UI / Android-基础 / 工程化 / 面试-项目
- 📱 **飞书通知** — 跑完自动 DM 报告（可选）
- 🛡️ **失败降级** — 任何源失败写 `status:failed` 不阻塞整体流程

### 🚀 快速开始

#### 方式一：bash 一键安装（推荐）

```bash
git clone https://github.com/TangHuan03/ai-kb.git
cd ai-kb
bash install.sh
```

跟着提示走（自动检测环境 + 询问参数 + 部署 + 测试运行）。

#### 方式二：OpenClaw 对话式安装

在 OpenClaw 对话中：

> "安装 ai-kb"

AI 会自动完成环境检测、参数询问、部署、测试。

#### 方式三：手动安装

```bash
# 1. 复制 Skill
mkdir -p ~/.claude/skills/ai-kb/
cp SKILL.md ~/.claude/skills/ai-kb/SKILL.md

# 2. 复制 installer Skill
mkdir -p ~/.claude/skills/ai-kb-installer/
cp installer/SKILL.md ~/.claude/skills/ai-kb-installer/SKILL.md

# 3. 创建 Vault
mkdir -p ~/Documents/AI-KB/{daily,knowledge}
for d in 视频与编码 iOS-基础 iOS-UI Android-基础 工程化 面试-项目; do
    mkdir -p ~/Documents/AI-KB/knowledge/$d
done
cp -r templates/vault-template/. ~/Documents/AI-KB/knowledge/

# 4. 创建工作区
mkdir -p ~/.openclaw/workspace/ai-kb/{raw,logs}

# 5. 注册 cron
openclaw cron add --name "ai-kb-daily" --cron "0 22 * * *" --tz "Asia/Shanghai" \
    --session isolated --timeout 600 --message "$(cat PLAN-2026-10-10.md)" --announce
```

### 📖 使用

#### 查看每日总结

打开 Obsidian，Vault = 你配置的路径。
- `daily/YYYY-MM-DD.md` — 极简索引（30 行内）
- 点击 `[[xxx]]` 链接跳转到 knowledge

#### 面试前复习

1. 打开 `knowledge/面试-项目/` 目录
2. 看每个文件第 6 章"项目实战"——STAR 法则话术
3. 看第 7 章"面试回答模板"——3-5 题标准答案

#### 手动跑一次

```bash
# 找 cron ID
CRON_ID=$(openclaw cron list | grep "ai-kb" | awk '{print $1}' | head -1)

# 跑
openclaw cron run "$CRON_ID"
```

#### 卸载

```bash
bash uninstall.sh
```

或在 OpenClaw 对话说"卸载 ai-kb"。

### 📂 目录结构

```
ai-kb/
├── README.md                  ← 本文件
├── LICENSE                    ← MIT
├── .gitignore                 ← 防止用户数据被提交
├── SKILL.md                   ← ai-kb 主 skill（核心规范）
├── PLAN-2026-10-10.md         ← v2 设计方案
├── install.sh                 ← 一键安装脚本
├── uninstall.sh               ← 卸载脚本
├── installer/
│   └── SKILL.md               ← 对话式部署 skill
├── scripts/
│   └── collect.py             ← Python 收集脚本（参考实现）
├── templates/
│   └── vault-template/        ← Vault 模板
│       ├── _index.md
│       ├── 视频与编码/
│       │   └── 视频-分辨率帧率码率.md
│       └── 面试-项目/
│           └── 视频上传链路-实战案例.md
└── examples/
    └── (更多示例待补充)
```

### 🧠 8 章知识结构

每条 knowledge 按统一结构：

1. **一句话概要** — 30 字内，AI 去重用
2. **背景** — 为什么学这个？
3. **核心概念** — 是什么？
4. **底层原理** — 为什么这样？（面试加分项）
5. **关键代码 / API** — 怎么用？
6. **项目实战** — ★ Claude Code 类必含 5 段（业务 / 选型 / 实施 / 数据 / 复盘）
7. **面试回答模板** — 3-5 题 + 标准答案
8. **常见误区 + 关联知识** — 避坑 + 拓展

### 🔌 三源数据

| 源 | 路径 / 方式 | 时间预算 |
|---|---|---|
| **ChatGPT** | OpenClaw Chrome Relay 抓 chatgpt.com | ≤ 30s |
| **Codex** | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | ≤ 60s |
| **Claude Code** | `~/.claude/projects/*/*.jsonl` | ≤ 60s |

任意一源失败不影响其他源采集。

### 🎯 设计原则

1. **准确 > 完整 > 自动化** — 宁可少生成，不要错误知识
2. **知识 > 对话总结** — 目标是长期可用，不是聊天备份
3. **关系必须有意义** — 不为了 Graph 而滥用链接
4. **保持简洁** — 让未来的自己快速理解
5. **可追溯** — 每条知识标注来源

### 🐛 故障排查

| 现象 | 原因 | 解决 |
|---|---|---|
| Cron 没跑 | 调度器问题 | `openclaw cron status` |
| 飞书无通知 | channel 没配 | 检查 `~/.openclaw/openclaw.json` |
| 知识没生成 | 采集失败 | 看 `~/.openclaw/workspace/ai-kb/raw/` |
| 链接不跳转 | Obsidian 缓存 | 在 Obsidian 中 reload |
| 知识重复 | 去重机制失效 | 手动合并 |

### 🛠️ 高级配置

修改 cron 消息：

```bash
openclaw cron edit <id> --message "$(cat your-custom-prompt.md)"
```

手动跑一次采集（不经过 AI）：

```bash
python3 ~/.openclaw/workspace/ai-kb/collect.py
```

### 🤝 贡献

- 提 Issue：bug 报告 / 功能建议
- 提 PR：改进 SKILL.md 规范 / 新增模板
- 分享：你的 daily/knowledge 给其他用户

### 📜 许可

MIT © 2026 ai-kb contributors

---

## English

**ai-kb** is a local AI conversation knowledge base that automatically captures daily conversations from **ChatGPT, Codex, and Claude Code**, distills them into 8-chapter interview-oriented documents (background / concepts / principles / code / real-world practice / interview Q&A templates / common misconceptions), and writes them to an Obsidian Vault with built-in deduplication and 6-category organization. Built for developers, it turns daily AI chats into interview-ready project experiences and foundational knowledge. Ships with both a **one-command bash installer** and an **OpenClaw conversational deployer** — set up in 5 minutes, runs itself.

### Features

- **Conversational setup** — Just say "install ai-kb" in OpenClaw
- **Fully automated** — Cron job at 22:00 (Asia/Shanghai) daily
- **Smart deduplication** — Reads all existing summaries before writing
- **8-chapter structure** — Strict template: background → concepts → principles → code → practice → interview → misconceptions
- **Interview-oriented** — 3-5 Q&A templates per knowledge + 5-segment project case (required for Claude Code projects)
- **6 categories** — Video & Encoding / iOS / Android / Engineering / Interview-Project
- **Feishu notification** — Daily DM report (optional)
- **Failure-resilient** — Any source failure writes `status:failed` without blocking

### Quick Start

```bash
git clone https://github.com/TangHuan03/ai-kb.git
cd ai-kb
bash install.sh
```

Or in OpenClaw: say "install ai-kb".

### Documentation

- [Design doc (v2)](./PLAN-2026-10-10.md)
- [Main skill spec](./SKILL.md)
- [Installer skill spec](./installer/SKILL.md)
- [Example knowledge files](./templates/vault-template/)

### License

MIT
