#!/usr/bin/env bash
# ai-kb 卸载脚本

set -e
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

echo "=========================================="
echo "  ai-kb 卸载工具"
echo "=========================================="
echo

# 1. 删 cron
info "Step 1/4: 删除 cron 任务..."
CRON_ID=$(openclaw cron list 2>/dev/null | grep "ai-kb" | awk '{print $1}' | head -1 || true)
if [[ -n "$CRON_ID" ]]; then
    ask "确认删除 cron 任务 $CRON_ID？[Y/n]: "
    read -r CONFIRM
    if [[ "$CONFIRM" != "n" && "$CONFIRM" != "N" ]]; then
        openclaw cron rm "$CRON_ID" 2>&1 | tail -3
        log "Cron 已删除"
    fi
else
    warn "未找到 ai-kb cron 任务"
fi

# 2. 删 Skill
echo
info "Step 2/4: 删除 Skills..."
ask "确认删除 ~/.claude/skills/ai-kb/ 和 ~/.claude/skills/ai-kb-installer/？[Y/n]: "
read -r CONFIRM
if [[ "$CONFIRM" != "n" && "$CONFIRM" != "N" ]]; then
    rm -rf "$HOME/.claude/skills/ai-kb"
    rm -rf "$HOME/.claude/skills/ai-kb-installer"
    log "Skills 已删除"
fi

# 3. 删工作区
echo
info "Step 3/4: 删除工作区..."
ask "确认删除 ~/.openclaw/workspace/ai-kb/？[Y/n]: "
read -r CONFIRM
if [[ "$CONFIRM" != "n" && "$CONFIRM" != "N" ]]; then
    rm -rf "$HOME/.openclaw/workspace/ai-kb"
    log "工作区已删除（raw/logs 都在这里）"
fi

# 4. 删 Vault
echo
info "Step 4/4: 删除 Vault..."
ask "请输入 Vault 路径（留空跳过）: "
read -r VAULT_PATH
if [[ -n "$VAULT_PATH" && -d "$VAULT_PATH" ]]; then
    ask "确认删除整个 Vault '$VAULT_PATH'？（包含所有 daily/knowledge 数据）[y/N]: "
    read -r CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        rm -rf "$VAULT_PATH"
        log "Vault 已删除"
    else
        log "已跳过 Vault 删除（数据保留）"
    fi
else
    log "跳过 Vault 删除"
fi

echo
echo "=========================================="
log "卸载完成！"
echo "=========================================="
echo
info "已清理："
echo "  - OpenClaw cron 任务"
echo "  - ~/.claude/skills/ai-kb/"
echo "  - ~/.claude/skills/ai-kb-installer/"
echo "  - ~/.openclaw/workspace/ai-kb/"
echo "  - 用户指定的 Vault（如确认）"
