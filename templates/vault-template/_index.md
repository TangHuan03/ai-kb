---
title: ai-kb 知识库总目录
status: confirmed
created: 2026-10-10
updated: 2026-10-10
---

# 📚 AI-KB 知识库总目录

> 本目录是 ai-kb 系统沉淀的所有**可面试**知识的索引。
> 每天 22:00 由 cron 自动从 ChatGPT / Codex / Claude Code 三源采集并提炼。
> 
> 详细规范见 `~/.claude/skills/ai-kb/SKILL.md`

## 🎯 使用方式

1. **每天看 daily**：`daily/YYYY-MM-DD.md` — 一眼看完今天学了什么
2. **遇到问题找知识**：用搜索或按下方分类跳转
3. **面试前看「面试-项目」**：所有业务实战实战，可直接用 STAR 法则讲

---

## 📂 分类索引

### 🎬 视频与编码
（暂无 — 现有 `视频-分辨率帧率码率.md` / `iOS-AVFoundation-音视频全景.md` 待迁移到 8 章结构）

### 📱 iOS-基础
- `iOS-基础/iOS-AVFoundation-音视频全景.md` — 采集/播放/处理/实时四大方向，AVPlayer 三件套
- `iOS-基础/iOS-多线程-主线程陷阱.md` — 回调内改 firstResponder 栈崩溃 + 通用反模式
- `iOS-基础/WebSocket-协议原理与iOS实战.md` — WebSocket 协议原理 + iOS URLSessionWebSocketTask

### 🎨 iOS-UI
- `iOS-UI/UICollectionView-布局排查.md` — 五大常见症状 + 5 步排查顺序

### 🤖 Android-基础
（暂无 — 待 Phase 4 回填）

### 🛠 工程化
（暂无 — 待 Phase 4 回填）

### 💼 面试-项目（★ 最重要）
**业务实战实战 — 面试必背**

- `面试-项目/视频上传链路-实战案例.md` — 视频上传按需转码 3 规则 + 跨端语义对齐
- `面试-项目/iOS-埋点CR-检查清单.md` — 4 维清单（完整性/准确性/性能/数据一致性）+ 实战数据

---

## 📊 当前已有知识（旧结构，待升级）

### ✅ Confirmed
- [[Claude-Code-Codex-OpenClaw-区别]] — 三个 AI 工具对比
- [[OpenClaw-飞书通道-排查]] — 飞书消息通道排查
- [[iOS-埋点CR-检查清单]] — 埋点 CR 注意事项
- [[视频-分辨率帧率码率]] — 视频三件套基础（v2 缺原理/面试模板）
- [[iOS-AVFoundation-音视频全景]] — AVFoundation 入门（v2 待升级）
- [[iOS-文件格式全景]] — 容器/编码/元数据（v2 待升级）
- [[adb-安装与无线调试]] — Android 调试基础（v2 待升级）
- [[ai-kb-skill-概览]] — ai-kb 系统说明

### ⏳ Pending（待确认）
- [[WebSocket-原理]] — 协议原理
- [[HTML-video-双浏览器兼容-playback]] — 浏览器视频播放兼容
- [[UICollectionView-contentInset-排查]] — iOS 布局排查
- [[ios-video-direct-upload-rules]] — iOS 视频上传规则（v2 待升级为 [[视频上传链路-实战案例]]）
- [[android-needcompress-bitrate-semantics]] — Android 压缩语义
- [[android-video-metadata-robustness]] — Android 视频元数据健壮性
- [[ios-needcompress-bitrate-semantics]] — iOS 压缩语义

### 📜 历史（待合并/删除）
- [[iOS-UITextField-resignFirstResponder-栈崩溃]] — bug case，v2 合并入 [[iOS-多线程-主线程陷阱]]
- [[视频转码-元数据保留-分类与陷阱]] — 实战总结，v2 升级

---

## 🗓 升级计划

| 阶段 | 内容 | 状态 |
|---|---|---|
| Phase v2.0 | SKILL.md 升级 + 分类文件夹 | ✅ 已完成（2026-10-10） |
| Phase 2 | 首批 3 个 8 章样例 | ✅ 已完成（2026-10-10） |
| Phase 3 | cron prompt 改版 | ✅ 已完成（2026-10-10） |
| Phase 4 | 批量回填 | 🔄 进行中（3/10） |
| Phase 5 | 知识库 _index.md 完善 | ⏳ 待批量回填后 |

---

## 📖 如何阅读知识

每个 knowledge 文件按 **8 章结构**组织：
1. **一句话概要**（开头必读 — AI 去重 + 你快速判断是否相关）
2. **背景**：为什么学这个
3. **核心概念**：详细对比表
4. **底层原理**：面试加分项
5. **关键代码 / API**：代码示例
6. **项目实战**（本业务）：业务背景 + 选型 + 实施 + 数据 + 复盘
7. **面试回答模板**：3-5 题 + 标准答案
8. **常见误区 + 关联知识**

**面试前推荐阅读顺序**：
1. 读「一句话概要」+「面试回答模板」+「项目实战」
2. 时间紧只看第 6 章和第 7 章
3. 有时间通读全部
