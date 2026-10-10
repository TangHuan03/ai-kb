---
name: ai-kb-installer
description: |
  ai-kb 自部署工具。用户说"安装 ai-kb"或"部署 ai-kb"或"配置 ai-kb"时触发。
  自动检测环境、询问参数、复制 Skill、创建 Vault、注册 cron、测试运行。
---

# ai-kb 自部署工具 (ai-kb-installer)

## 目标

让用户**通过对话**完成 ai-kb 全套部署：
- 检测环境（OpenClaw / Obsidian / Claude Code / Codex）
- 询问关键参数（Vault 路径 / cron 时间 / 飞书通知）
- 自动复制 Skill 文件
- 创建 Vault 模板（6 个分类文件夹 + 2 个示例）
- 注册 cron 任务（每天自动跑）
- 第一次测试运行
- 报告结果

## 触发场景

用户说以下任何一种时触发：
- "安装 ai-kb"
- "部署 ai-kb"
- "配置 ai-kb"
- "ai-kb 一键安装"
- "我想用 ai-kb 知识库"

## 部署步骤

### Step 1：环境检测

并行检查：
1. `command -v openclaw` — OpenClaw CLI
2. `ls -la /Applications/Obsidian.app` — Obsidian 安装
3. `ls -la ~/.claude` — Claude Code 配置目录
4. `ls -la ~/.codex` — Codex 配置目录
5. `ls -la ~/.claude/skills/ai-kb/SKILL.md` — ai-kb 是否已装

**输出**：
```
检测结果：
  ✅ OpenClaw: openclaw 2026.2.23-cn
  ✅ Obsidian: 已安装
  ✅ Claude Code: 已配置
  ❌ Codex: 未检测到
  ❌ ai-kb: 未安装（首次部署）
```

### Step 2：询问关键参数

**用 AskUserQuestion 一次性问完**（避免多轮）：

| 问题 | 选项 | 默认 |
|---|---|---|
| Obsidian Vault 路径 | 自定义 | `~/Documents/AI-KB` 或 iCloud 默认 |
| 每天运行时间 | 22:00 / 23:00 / 21:00 / 自定义 | 22:00 |
| 启用飞书通知 | 是 / 否 | 是 |
| OpenClaw 投递目标 | 自定义 / 默认 | 默认（最后活跃 channel）|

### Step 3：执行部署

**用 exec 运行 bash 脚本**：

```bash
# 直接运行 install.sh
bash /path/to/ai-kb-v2.0/install.sh
```

或自己手动执行：

```bash
# 1. 复制 Skill
mkdir -p ~/.claude/skills/ai-kb/
cp SKILL.md ~/.claude/skills/ai-kb/SKILL.md

# 2. 创建 Vault 结构
mkdir -p "$VAULT_PATH"/{daily,knowledge}
for d in 视频与编码 iOS-基础 iOS-UI Android-基础 工程化 面试-项目; do
  mkdir -p "$VAULT_PATH/knowledge/$d"
done
cp -r templates/vault-template/. "$VAULT_PATH/knowledge/"

# 3. 创建工作区
mkdir -p ~/.openclaw/workspace/ai-kb/{raw,logs}

# 4. 注册 cron
openclaw cron add \
  --name "ai-kb-daily" \
  --cron "0 22 * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --timeout 600 \
  --message "..." \
  --announce
```

### Step 4：测试运行

```bash
# 找 cron ID
CRON_ID=$(openclaw cron list | grep "ai-kb" | awk '{print $1}' | head -1)
# 跑一次
openclaw cron run "$CRON_ID"
# 等 30-60s
# 查日志 / 飞书通知
```

### Step 5：报告结果

成功：
```
✅ ai-kb 部署完成！

- Skill: ~/.claude/skills/ai-kb/SKILL.md
- Vault: ~/Documents/AI-KB
- 工作区: ~/.openclaw/workspace/ai-kb/
- Cron: 每天 22:00 Asia/Shanghai 自动跑

下一步：
1. 在 Obsidian 中打开 ~/Documents/AI-KB
2. 今晚 22:00 后看 daily
3. 有问题对说「ai-kb 帮助」
```

失败：
```
❌ 部署失败：{原因}

可能的原因：
1. OpenClaw 未启动 → openclaw gateway start
2. 飞书未配置 → 检查 ~/.openclaw/openclaw.json
3. 权限不足 → 手动检查路径

要重试吗？[Y/n]
```

## 卸载

用户说「卸载 ai-kb」时：

```bash
# 1. 删 cron
openclaw cron rm <cron-id>

# 2. 删 Skill
rm -rf ~/.claude/skills/ai-kb/
rm -rf ~/.claude/skills/ai-kb-installer/

# 3. 删工作区（保留数据）
rm -rf ~/.openclaw/workspace/ai-kb/

# 4. 删 Vault（询问用户）
# rm -rf ~/Documents/AI-KB/
```

## 常见问题

| 问题 | 答案 |
|---|---|
| 部署后 cron 没跑 | 检查 `openclaw cron list`，看 status |
| 飞书无通知 | 检查 channel 配置 |
| 知识没生成 | 看 raw/<date>.json 看哪源失败 |
| 知识重复 | 已在 v2 加去重，写前读所有概要 |
| 链接不跳转 | Obsidian 缓存，reload 一下 |

## ⚠️ 不要做的事

- 不要直接 rm -rf 用户 Vault（先询问）
- 不要修改用户的 ~/.openclaw/openclaw.json
- 不要在用户没确认前创建 cron
- 不要跳过环境检测

## 关联 Skill

- `ai-kb` — 主 skill（被部署的核心）
- `feishu-cli` — 飞书工具（如需要）
