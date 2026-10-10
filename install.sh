#!/usr/bin/env bash
# ============================================================
# ai-kb 一键安装脚本
# 用法：bash install.sh
# 效果：
#   1. 检测环境（OpenClaw / Obsidian / Claude Code / Codex）
#   2. 询问 Vault 路径等关键参数
#   3. 复制 Skill 到 ~/.claude/skills/ai-kb/
#   4. 创建 Vault 模板结构
#   5. 注册 cron（每天 22:00 Asia/Shanghai 自动跑）
#   6. 第一次测试运行
# ============================================================

set -e

# ---------- 颜色 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${BLUE}[i]${NC} $*"; }
ask()  { echo -ne "${BLUE}[?]${NC} $*"; }

# ---------- 路径 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_TARGET="$HOME/.claude/skills/ai-kb"
INSTALLER_TARGET="$HOME/.claude/skills/ai-kb-installer"
WORKSPACE="$HOME/.openclaw/workspace/ai-kb"

# ---------- 0. 检查工具 ----------
echo "=========================================="
echo "  ai-kb 自部署工具 v2.0"
echo "=========================================="
echo

# OpenClaw
if ! command -v openclaw >/dev/null 2>&1; then
    err "未检测到 openclaw 命令"
    err "请先安装 OpenClaw: https://docs.openclaw.ai"
    exit 1
fi
log "OpenClaw 已安装: $(openclaw --version 2>&1 | head -1)"

# Obsidian (可选)
if [[ -d "/Applications/Obsidian.app" ]]; then
    log "Obsidian 已安装"
    HAS_OBSIDIAN=true
else
    warn "未检测到 Obsidian（可选）— 你可以稍后安装"
    HAS_OBSIDIAN=false
fi

# Claude Code (可选)
if [[ -d "$HOME/.claude" ]]; then
    log "Claude Code 已安装"
    HAS_CLAUDE=true
else
    warn "未检测到 Claude Code（可选）— ChatGPT 仍可用"
    HAS_CLAUDE=false
fi

# Codex (可选)
if [[ -d "$HOME/.codex" ]]; then
    log "Codex 已安装"
    HAS_CODEX=true
else
    warn "未检测到 Codex（可选）— ChatGPT/Claude Code 仍可用"
    HAS_CODEX=false
fi

echo

# ---------- 1. 询问用户参数 ----------
info "请提供以下信息："
echo

# Vault 路径
DEFAULT_VAULT="$HOME/Documents/AI-KB"
if [[ "$OSTYPE" == "darwin"* ]]; then
    DEFAULT_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/AI-KB"
fi
ask "Obsidian Vault 路径 [回车使用: $DEFAULT_VAULT]: "
read -r VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"

# cron 时间
ask "每天运行时间（cron 格式，24h，Asia/Shanghai）[回车使用: 0 22 * * *]: "
read -r CRON_TIME
CRON_TIME="${CRON_TIME:-0 22 * * *}"

# 飞书通知
ask "是否启用飞书通知（每天跑完报告）[y/N]: "
read -r USE_FEISHU
USE_FEISHU="${USE_FEISHU:-N}"

# OpenClaw cron 投递目标
DEFAULT_TO="${OPENCLAW_TO:-user:me}"
ask "OpenClaw 投递目标 [回车使用: $DEFAULT_TO]: "
read -r TO_TARGET
TO_TARGET="${TO_TARGET:-$DEFAULT_TO}"

echo
info "配置汇总："
echo "  Vault 路径: $VAULT_PATH"
echo "  Cron 时间:  $CRON_TIME Asia/Shanghai"
echo "  飞书通知:   $USE_FEISHU"
echo "  投递目标:   $TO_TARGET"
echo
ask "确认安装？[Y/n]: "
read -r CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" ]]; then
    err "已取消"
    exit 1
fi

# ---------- 2. 复制 Skill ----------
echo
info "Step 1/6: 复制 ai-kb Skill..."
mkdir -p "$SKILL_TARGET"
cp -f "$SCRIPT_DIR/SKILL.md" "$SKILL_TARGET/SKILL.md"
log "  → $SKILL_TARGET/SKILL.md"

info "Step 1/6: 复制 ai-kb-installer Skill..."
mkdir -p "$INSTALLER_TARGET"
cp -f "$SCRIPT_DIR/installer/SKILL.md" "$INSTALLER_TARGET/SKILL.md"
log "  → $INSTALLER_TARGET/SKILL.md"

# ---------- 3. 创建 Vault 结构 ----------
info "Step 2/6: 创建 Vault 模板..."
mkdir -p "$VAULT_PATH"/{daily,knowledge}
for dir in 视频与编码 iOS-基础 iOS-UI Android-基础 工程化 面试-项目; do
    mkdir -p "$VAULT_PATH/knowledge/$dir"
done

# 复制 vault 模板
cp -rf "$SCRIPT_DIR/templates/vault-template/." "$VAULT_PATH/knowledge/"
log "  → $VAULT_PATH/ (含 6 个分类文件夹 + _index.md + 2 个示例)"

# ---------- 4. 创建工作区 ----------
info "Step 3/6: 创建工作区..."
mkdir -p "$WORKSPACE"/{raw,logs}
log "  → $WORKSPACE/"

# 复制 collect.py
cp -f "$SCRIPT_DIR/scripts/collect.py" "$WORKSPACE/collect.py"
chmod +x "$WORKSPACE/collect.py"
log "  → $WORKSPACE/collect.py"

# ---------- 5. 生成 cron 消息 ----------
info "Step 4/6: 生成 cron 任务消息..."

# 用模板替换变量
CRON_MSG=$(cat <<EOF
执行 ai-kb skill（~/.claude/skills/ai-kb/SKILL.md，v2 规范）。

**硬性时间预算**：每源 ≤ 60s；任何一步失败立刻跳过进下一步，不要重试。
**工具约束**：写文件必须用 write，不用 edit（避免"Edit failed"假错误）。

## 1. 采集（带超时与降级）

**Codex**（必做）
- glob ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
- 解析 user/assistant 消息，超时 60s

**Claude Code**（必做）
- glob ~/.claude/projects/*/*.jsonl
- 按 JSON 内 timestamp 字段过滤今天，超时 60s

**ChatGPT**（默认开启，但有硬性超时）
- 先检查 browser(profile=openclaw) 状态
- 不可用 → 标 status=unavailable，写入 raw，跳过
- 可用：打开 chatgpt.com，等 3s 加载；从 sidebar 提取今天的会话（UUIDv7 前缀转秒判断日期）
- 整源总超时 30s（不是 60s），超时即停
- 单条会话 extract ≤ 5s，超时跳过下一条
- 任何失败 → 标 status=failed + reason，**不要重试**

## 2. 去重检查（v2 必做，写任何 knowledge 前必做）

**先读 $VAULT_PATH/knowledge/ 下所有 .md 的 frontmatter.title + 开头「一句话概要」段**

判断重复：
- 完全重复 → 引用，不创建
- 部分重复 → 创建新文件，正文开头加引用块
- 30%+ 新内容 → 更新已有文件
- 不重复 → 创建新文件

## 3. 写 raw（用 write 工具）

## 4. 写 daily（v2 极简索引，30 行内）

## 5. 写 knowledge（v2 强制 8 章结构，分类文件夹必填）

- 视频/编码相关 → 视频与编码/
- iOS 基础 → iOS-基础/
- iOS UI → iOS-UI/
- Android 基础 → Android-基础/
- 工程化 → 工程化/
- 业务实战实战 → 面试-项目/

## 6. 总结输出

简报今日 stats + 关键知识点 1-3 条 + 任何源失败的原因。
**不要全文转储 daily，不要通过飞书发消息（系统自动投递）**。

## ⚠️ 不要做的事
- 不要用 edit 工具
- 不要重试任何步骤
- 不要在 ChatGPT 单源超过 30s
- 不要在 daily 里写摘要/代码
- 不要创建没有 8 章结构的 knowledge
- 不要漏掉一句话概要
- 不要漏掉面试回答模板（v2 强制 3-5 题）
EOF
)

# ---------- 6. 注册 cron ----------
info "Step 5/6: 注册 OpenClaw cron..."

# 解析 cron 时间
CRON_HOUR=$(echo "$CRON_TIME" | awk '{print $2}')
CRON_MIN=$(echo "$CRON_TIME" | awk '{print $1}')

# 检查是否已存在
EXISTING_JOB=$(openclaw cron list 2>/dev/null | grep -E "ai-kb" | head -1 || true)
if [[ -n "$EXISTING_JOB" ]]; then
    warn "已存在 ai-kb cron 任务，跳过创建"
else
    # 创建 cron
    openclaw cron add \
        --name "ai-kb-daily" \
        --cron "$CRON_MIN $CRON_HOUR * * *" \
        --tz "Asia/Shanghai" \
        --session isolated \
        --timeout 600 \
        --message "$CRON_MSG" \
        --announce \
        --channel last \
        --to "$TO_TARGET" \
        2>&1 | tail -5
    log "  → Cron 已注册: $CRON_TIME Asia/Shanghai"
fi

# ---------- 7. 测试运行 ----------
echo
info "Step 6/6: 第一次测试运行..."
ask "是否立即跑一次（看效果）？[Y/n]: "
read -r RUN_NOW
RUN_NOW="${RUN_NOW:-Y}"
if [[ "$RUN_NOW" == "Y" || "$RUN_NOW" == "y" ]]; then
    info "正在触发 cron..."
    CRON_ID=$(openclaw cron list 2>/dev/null | grep "ai-kb" | awk '{print $1}' | head -1)
    if [[ -n "$CRON_ID" ]]; then
        openclaw cron run "$CRON_ID" 2>&1 | tail -10
        log "测试运行已触发，请等待 30-60s 后查看结果"
    else
        warn "未找到 cron ID，请手动验证"
    fi
fi

# ---------- 完成 ----------
echo
echo "=========================================="
log "ai-kb 安装完成！"
echo "=========================================="
echo
info "后续操作："
echo "  1. 在 Obsidian 中打开: $VAULT_PATH"
echo "  2. 每天 $CRON_TIME Asia/Shanghai 自动跑"
echo "  3. 通过 OpenClaw 对话说「重新配置 ai-kb」可以重新部署"
echo "  4. 通过 OpenClaw 对话说「卸载 ai-kb」可以卸载"
echo
info "故障排查："
echo "  - 看日志:    tail -f $WORKSPACE/logs/"
echo "  - 看 cron:   openclaw cron list"
echo "  - 跑一次:    openclaw cron run <id>"
echo
