---
name: ai-kb
description: |
  本地 AI 会话知识库系统。从 ChatGPT、Codex、Claude Code 三源采集当天会话，提炼结构化知识，写入 Obsidian Vault。
  触发场景：用户询问今天聊了什么 / 让沉淀 AI 对话 / 跑 ai-kb / 整理知识库。
  用途：把 AI 对话变成可学习、可面试的知识库。
---

# AI 会话知识库 v2（ai-kb）

## 目标

每日 22:00 自动从三个数据源采集当天会话：
1. **ChatGPT**（网页端，通过 OpenClaw Chrome Relay 读取）
2. **Codex**（本机 `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`）
3. **Claude Code**（本机 `~/.claude/projects/<encoded-path>/<session-uuid>.jsonl`）

用 OpenClaw 模型（sessions_spawn 派 sub-agent）做知识提炼，写入 Obsidian Vault。

> **v2 升级（2026-10-10）**：所有知识按"面试可用"标准组织。daily 极简化只做索引，knowledge 8 章结构 + 去重 + 面试模板。

## Vault 结构

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Th obsidian/AI-KB/
├── daily/
│   └── YYYY-MM-DD.md         # 当日索引（极简，只放链接）
└── knowledge/                # 完整可学的知识（8 章结构）
    ├── 视频与编码/
    ├── iOS-基础/
    ├── iOS-UI/
    ├── Android-基础/
    ├── 工程化/
    ├── 面试-项目/
    └── _index.md             # 知识库总目录（人工维护）
```

工作区（中间产物）：
- `~/.openclaw/workspace/ai-kb/raw/` — 原始会话 JSON
- `~/.openclaw/workspace/ai-kb/logs/` — 运行日志
- `~/.openclaw/workspace/ai-kb/PLAN-2026-10-10.md` — v2 设计方案

## 设计原则（精简为执行清单）

执行时必须遵守：
1. **准确 > 完整 > 自动化**。宁可少生成一个知识，也不要生成错误知识。
2. **知识 > 对话总结**。目标是建立长期可用的知识库，不是聊天备份。
3. **关系必须有意义**。不为了 Graph 好看而大量创建 `[[xxx]]`。
4. **保持简洁**。知识文档让未来的自己快速理解。
5. **可追溯**。每个知识标注来源（ChatGPT 对话 / Codex / Claude Code）。
6. **不直接照抄 AI 结论**。区分：已确认 / 待验证 / 冲突。
7. **多源冲突时不要自行裁定**，明确标"待验证"。

---

## Daily 文件格式（v2：纯索引）

**目标**：3 屏看完当天所有内容，一键跳转到 knowledge。

```markdown
---
date: 2026-10-09
sources:
  chatgpt: 3
  codex: 0
  claude_code: 7
total_sessions: 10
new_knowledge: 5
updated_knowledge: 0
---

# 2026-10-09 学习日报

## 📚 今日新学（5 个）
- [[视频-分辨率帧率码率]] — 视频编码基础三件套
- [[iOS-AVFoundation-音视频全景]] — AVFoundation 入门框架
- [[iOS-文件格式全景]] — 容器/编码/元数据区分
- [[adb-安装与无线调试]] — Android 调试基础
- [[Xcode-工程结构与生成]] — iOS 工程从零创建

## 💼 今日项目实战（10 条会话）
### Claude Code（7 条）
- **21:30** [Android] 视频上传链路 CR → 沉淀 [[android-video-metadata-robustness]]
- **15:07** [iOS-MediaStore] 视频格式合规直传 CR → 沉淀 [[ios-video-direct-upload-rules]]
- ... (低价值 3 条已跳过)

### ChatGPT（3 条）
- **20:29** 生成xcproject方法 → 沉淀 [[Xcode-工程结构与生成]]
- **11:51** 视频三件套 + iOS 音视频课程 → 沉淀 [[视频-分辨率帧率码率]] + [[iOS-AVFoundation-音视频全景]]
- **10:23** Xcappdata + iOS 文件格式 → 沉淀 [[iOS-文件格式全景]] + [[adb-安装与无线调试]]

### Codex（0 条）
- 10/09 无新 session（最近一次仍是 09/28）

## ⏭️ 跳过（低价值）
- 异形卡 1pt/1dp 调整 ×2
- debug_upload 路径查找

## ❓ 待验证
- iOS `VideoCaptureTools.m` bitrate 无效绕过压缩 bug 是否已修
- Xcode 27+ `.xcproj` JSON 格式是否普及
```

**关键约束**：
- 全文 30 行以内
- 不重复 knowledge 内容（只放链接 + 一句"是什么"）
- 待验证必须列出（面试前必看）

---

## Knowledge 文件格式（v2：8 章结构）

**目标**：小白能读懂 + 面试能用 + 零错误。

### 强制 8 章结构

```markdown
---
title: <主题>
status: confirmed | pending | conflict
tags: [<领域>, <技术>, <场景>]  ← 至少 2 个标签
source: <chatgpt://uuid> | <claude_code://project/session-id> | <codex://session-id>
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## 一句话概要
> <用 1-2 句话概括这个知识的核心，写给未来的自己和 AI 读>
> 例：视频三件套——分辨率=像素格子数 / 帧率=每秒帧数 / 码率=每秒数据量。同分辨率帧率下，码率决定画质。

# <主题>

## 1. 背景：为什么要学这个？
<1-2 段说明这个知识解决什么问题、在什么场景下用得到>

## 2. 核心概念
<详细对比表、关键洞察、图示>

## 3. 底层原理（面试加分项）
<为什么这样设计？底层机制是什么？>

## 4. 关键代码 / API
<代码示例 + 注释 + 边界情况>

## 5. 项目实战（本业务）
<在业务实战里怎么用？解决了什么问题？结果数据？>

## 6. 面试回答模板
<3-5 个高频面试题 + 标准答案，可用 STAR 法则>

## 7. 常见误区
<容易答错或理解错的点>

## 8. 关联知识
[[related-topic-1]] — 关系说明
[[related-topic-2]] — 关系说明

## 来源
- ChatGPT 对话 `<id>`（YYYY-MM-DD HH:MM）
- Claude Code 会话 `<project>/<id>`

## 待验证
- <模糊的概念/数据，需要进一步确认>
```

### 三类知识的差异化组织

| 来源 | 面试考点 | 重点章节 |
|---|---|---|
| **ChatGPT**（概念/入门） | "什么是 X？X 和 Y 区别？" | 概念、原理、误区、面试模板 |
| **Claude Code**（项目实战）★ | "项目里你做过 X 吗？怎么做的？" | 业务背景、技术选型、实施过程、结果数据、复盘反思（必须含 5 段） |
| **Codex**（代码细节） | "X 怎么实现？底层原理？" | 代码、原理、性能、边界 case |

### Claude Code 知识必含 5 段

> 这是用户**最有价值的素材**——直接反映工作能力，面试官会追问细节。

```
第 5 章「项目实战」必须含：
1. 业务背景：这个需求为什么出现？（性能问题 / 体验优化 / 排期 / 老板要求）
2. 技术选型：为什么选 A 不选 B？（对比 2-3 个方案）
3. 实施过程：关键代码点、踩过的坑
4. 结果数据：性能提升多少、bug 修了几个、上线后效果
5. 反思 / 复盘：如果重做会怎么做？行业更优解是什么？
```

**面试话术模板**：
> "我们在本业务做 [号码迁移业务] 时，遇到 [账号冲突 / DAO 崩溃 / 视频上传慢] 的问题。
> 调研后选了 [方案 A]，原因是 [对比]...
> 实施中踩了 [坑 1] / [坑 2]...
> 上线后 [数据：崩溃率从 X 降到 Y / 上传成功率从 A% 升到 B%]。
> 复盘来看，更优解可能是 [xxx]。"

---

## 去重流程（写新 knowledge 前必做）

> 核心：避免 [[iOS-AVFoundation-音视频全景]] 和 [[iOS-音视频学习-课程笔记]] 重复生成的问题。

### Step 1：扫描已有知识

AI 拿到一个新主题后，先读 `knowledge/` 下所有分类文件夹的 .md 文件：
- 读 frontmatter 的 `title`
- 读正文开头的「一句话概要」

### Step 2：判断重复程度

| 情况 | 操作 |
|---|---|
| **完全重复** | 引用，不创建：在 daily 里加 `[[xxx]]` 链接即可 |
| **部分重复** | 创建新文件，正文开头加引用块：`> 本文件与 [[xxx]] 相关，开头请先读` |
| **30%+ 新内容** | 更新已有文件，`updated: <date>`，文末加 `## 增量更新（YYYY-MM-DD）` 段 |
| **完全不重复** | 按 8 章结构创建新文件 |

### Step 3：写入分类文件夹

- iOS 基础概念 → `iOS-基础/`
- iOS 音视频/视频相关 → `视频与编码/`
- iOS UI 相关 → `iOS-UI/`
- Android 基础 → `Android-基础/`
- 工具/工程化 → `工程化/`
- 业务实战实战 → `面试-项目/` ← 最重要的素材

### 已有重复案例的处理建议

| 旧文件 | 处理 |
|---|---|
| `iOS-音视频学习-课程笔记.md`（如果存在） | 与 [[iOS-AVFoundation-音视频全景]] 重复，**删除并入** |
| `iOS-UITextField-resignFirstResponder-栈崩溃.md` | bug case，**合并入** `iOS-基础/iOS-多线程-主线程陷阱.md` |
| `Claude-Code-Codex-OpenClaw-区别.md` | 工具对比，**保留**，结构升级到 8 章 |

---

## 执行流程（每日 22:00 cron 触发）

### Step 1：采集（≤30s/源，无重试）

**ChatGPT**（30s 硬超时）
```
browser(action=open, profile=openclaw, targetUrl=https://chatgpt.com)
# 通过 Chrome relay 复用用户已登录 session
# 从 sidebar 提取今天 (YYYY-MM-DD) 的会话列表
# UUIDv7 前 12 位 16 进制 → unix 秒 → 本地日期
# 遍历每个会话，提取对话内容（5s/会话）
```

**Codex**（30s 预算）
```python
import glob, json
files = glob.glob(f'~/.codex/sessions/{YYYY}/{MM}/{DD}/rollout-*.jsonl')
# 解析每个 jsonl，按 type 字段过滤 user/assistant 消息
```

**Claude Code**（30s 预算）
```python
import glob, json
files = glob.glob(f'~/.claude/projects/*/*.jsonl')
# 按文件内容 JSON `timestamp` 字段过滤当天（不是 mtime）
```

### Step 2：去重 + 标准化

将三个源统一成 `Conversation` 结构：
```python
@dataclass
class Message:
    role: str  # user | assistant | tool
    content: str
    timestamp: datetime
    tool_name: str | None = None

@dataclass
class Conversation:
    source: str  # chatgpt | codex | claude_code
    id: str
    title: str
    url: str | None
    messages: list[Message]
```

存入 `~/.openclaw/workspace/ai-kb/raw/<date>.json`。

### Step 3：AI 分析 + 去重 + 写文件

调用 OpenClaw sub-agent（`write` 不用 `edit`，避免 "Edit failed" 警告）：

```
任务：
1. 读 raw/<date>.json
2. 对当天所有会话做：
   - 摘要：每条会话一句话总结
   - 价值判断：是否有新知识（error correction / new concept / 便利澄清）
   - 知识提炼：明确知识（已确认）、待验证、冲突
3. **去重检查（必做）**：
   - 读 knowledge/ 下所有 .md 的 [title + 一句话概要]
   - 重复 → 引用，不创建
   - 部分重复 → 创建但加引用块
4. **写文件**：
   - daily/YYYY-MM-DD.md：v2 极简索引
   - knowledge/<分类>/<新文件>.md：v2 8 章结构（如有）
5. **跳过**低价值会话（仅润色、闲聊、UI 微调、文件查找）
```

**输出文件路径**：
- Daily: `Th obsidian/AI-KB/daily/<date>.md`
- Knowledge: `Th obsidian/AI-KB/knowledge/<分类>/<slug>.md`

**关键约束**：
- 不照搬 AI 错误结论
- 不为了关联而滥用 [[xxx]]
- 多源冲突标 `status: conflict`
- 低价值会话（仅润色、闲聊）跳过
- **Claude Code 知识必含 5 段（业务背景/选型/实施/数据/复盘）**

### Step 4：失败处理（无重试）

- 抓取失败 / 超时：写 `status: failed` 进 raw，继续
- 浏览器不可用：写 `status: unavailable` 进 raw，继续
- AI 分析失败：raw 仍保留，下次手动重跑
- **不再重试** — 避免 cron 失败时阻塞后续源

### Step 5：cron 报告

- 飞书 DM 简短报告：当日新增/更新 N 个知识 + 关键会话链接
- 失败时明确说明哪个源失败、原因是什么

---

## 时间预算（v2 严格）

| 阶段 | 预算 |
|---|---|
| ChatGPT 整源 | ≤ 30s（硬超时） |
| Codex 整源 | ≤ 30s |
| Claude Code 整源 | ≤ 30s |
| ChatGPT 单会话提取 | ≤ 5s |
| AI 分析（sub-agent） | ≤ 120s |
| 写文件 | ≤ 30s |
| **总预算** | ≤ 4 分钟（从 cron 触发到飞书通知） |

**总超时**：600s（10 分钟）— 超过则 cron 报错。

---

## CLI（待实现）

```bash
ai-kb sync           # 同步所有源
ai-kb sync chatgpt   # 仅 ChatGPT
ai-kb sync codex
ai-kb sync claude
ai-kb daily          # 生成今日总结
ai-kb rebuild        # 重新构建知识库
ai-kb status         # 查看同步状态
ai-kb conflicts      # 查看冲突知识
ai-kb dedupe         # 扫描重复知识
```

---

## 开发阶段

- [x] Phase 0: skill + cron scaffold
- [x] Phase v2.0: 8 章结构 + 去重 + 面试模板（2026-10-10）
  - [x] SKILL.md 升级
  - [x] 分类文件夹创建（视频与编码/ iOS-基础/ iOS-UI/ Android-基础/ 工程化/ 面试-项目/）
  - [ ] 现有 knowledge 文件回填（不强制，渐进式）
  - [ ] 现有 daily 文件回填（不强制，渐进式）
- [ ] Phase 2: 首批 8 章 knowledge 样例（2-3 个）
  - [ ] `面试-项目/视频上传链路-实战案例.md`（升 ios-video-direct-upload-rules）
  - [ ] `iOS-基础/iOS-AVFoundation-音视频全景.md`（升 iOS-AVFoundation-音视频全景）
  - [ ] `iOS-基础/iOS-多线程-主线程陷阱.md`（合并多个 bug case）
- [ ] Phase 3: cron prompt 改版（按 v2 规范生成）
- [ ] Phase 4: 批量回填其他 knowledge
- [ ] Phase 5: 知识库 _index.md
- [ ] Phase 6: 每周复盘机制
- [ ] Phase 7: Phase 1 统一数据模型 + 测试（Python）
- [ ] Phase 8: SQLite 索引
- [ ] Phase 9: CLI

---

## 附：v1 → v2 改动清单

| 维度 | v1 | v2 |
|---|---|---|
| Daily 长度 | 100+ 行（含摘要） | 30 行（纯索引） |
| Daily 内容 | 摘要 + 链接 | 只有链接 |
| Knowledge 结构 | 自由（4-5 段） | 强制 8 章 |
| Knowledge 开头 | 无 | **一句话概要**（AI 去重用） |
| 知识分类 | 扁平 | 6 大分类文件夹 |
| 去重机制 | 无 | 写前必读所有概要 |
| 面试导向 | 无 | 强制含 3-5 题面试模板 |
| Claude Code 类 | 普通知识 | **必含 5 段（业务/选型/实施/数据/复盘）** |
| 重复案例 | [[iOS-音视频学习-课程笔记]] 与 [[iOS-AVFoundation-音视频全景]] 重复 | 去重流程禁止再发生 |
