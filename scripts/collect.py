#!/usr/bin/env python3
"""ai-kb daily collection - fast & fail-tolerant"""
import json, glob, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

DATE = "2026-10-08"
TZ_OFFSET = 8  # Asia/Shanghai
RAW_DIR = Path("~/.openclaw/workspace/ai-kb/raw")
LOG_DIR = Path("~/.openclaw/workspace/ai-kb/logs")
RAW_DIR.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)

# Compute today range in UTC
local_midnight = datetime(2026, 10, 8, 0, 0, 0)
local_next = datetime(2026, 10, 9, 0, 0, 0)
utc_start = local_midnight - timedelta(hours=TZ_OFFSET)
utc_end = local_next - timedelta(hours=TZ_OFFSET)
TS_START = utc_start.timestamp()
TS_END = utc_end.timestamp()
print(f"[time] UTC range for {DATE}: {utc_start} → {utc_end}", flush=True)
print(f"[time] epoch: {TS_START} → {TS_END}", flush=True)

result = {
    "date": DATE,
    "collected_at": datetime.now(timezone.utc).isoformat(),
    "sources": {
        "codex": {"status": "pending", "conversations": []},
        "claude_code": {"status": "pending", "conversations": []},
        "chatgpt": {"status": "skipped", "conversations": []},
    }
}

# ========== Codex ==========
try:
    codex_pattern = f"~/.codex/sessions/2026/10/08/rollout-*.jsonl"
    codex_files = glob.glob(codex_pattern)
    print(f"[codex] glob: {len(codex_files)} files", flush=True)
    if not codex_files:
        # also try any rollout newer than today
        codex_files = [
            f for f in glob.glob("~/.codex/sessions/2026/10/*/rollout-*.jsonl")
        ]
    for fp in codex_files:
        try:
            with open(fp) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    # Codex format: {"type": "session_meta", "payload": {...}}
                    if obj.get("type") == "response_item":
                        payload = obj.get("payload", {})
                        if payload.get("type") == "message":
                            role = payload.get("role")
                            content_parts = payload.get("content", [])
                            text = ""
                            for part in content_parts:
                                if isinstance(part, dict) and part.get("type") in ("text", "input_text", "output_text"):
                                    text += part.get("text", "")
                            ts = obj.get("timestamp") or payload.get("timestamp")
                            result["sources"]["codex"]["conversations"].append({
                                "file": os.path.basename(fp),
                                "role": role,
                                "text": text[:2000],
                                "timestamp": ts,
                            })
        except Exception as e:
            print(f"[codex] file err: {e}", flush=True)
    result["sources"]["codex"]["status"] = "ok"
    print(f"[codex] messages: {len(result['sources']['codex']['conversations'])}", flush=True)
except Exception as e:
    result["sources"]["codex"]["status"] = "failed"
    result["sources"]["codex"]["reason"] = str(e)
    print(f"[codex] FAILED: {e}", flush=True)

# ========== Claude Code ==========
try:
    cc_files = glob.glob("~/.claude/projects/*/*.jsonl")
    # exclude subagents
    cc_files = [f for f in cc_files if "/subagents/" not in f]
    print(f"[cc] candidate files: {len(cc_files)}", flush=True)
    
    kept_sessions = {}  # session_id -> {first_ts, last_ts, messages, project, mtime}
    for fp in cc_files:
        try:
            st = os.stat(fp)
            # Quick reject by mtime (faster than reading)
            if st.st_mtime < TS_START - 86400 or st.st_mtime > TS_END + 86400:
                continue
            session_id = os.path.basename(fp).replace(".jsonl", "")
            project_dir = os.path.basename(os.path.dirname(fp))
            msgs = []
            min_ts = None
            max_ts = None
            with open(fp) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    ts = obj.get("timestamp")
                    msg = obj.get("message", {})
                    if not isinstance(msg, dict):
                        continue
                    role = msg.get("role")
                    if role not in ("user", "assistant"):
                        continue
                    content = msg.get("content", "")
                    text = ""
                    if isinstance(content, str):
                        text = content
                    elif isinstance(content, list):
                        for part in content:
                            if isinstance(part, dict):
                                if part.get("type") == "text":
                                    text += part.get("text", "")
                                elif part.get("type") == "tool_use":
                                    text += f"\n[tool:{part.get('name')}] "
                                elif part.get("type") == "tool_result":
                                    inner = part.get("content", "")
                                    if isinstance(inner, str):
                                        text += f"\n[result] {inner[:500]}"
                                    elif isinstance(inner, list):
                                        for p in inner:
                                            if isinstance(p, dict) and p.get("type") == "text":
                                                text += p.get("text", "")[:500]
                    if not text.strip():
                        continue
                    if ts:
                        try:
                            t = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                            if min_ts is None or t < min_ts:
                                min_ts = t
                            if max_ts is None or t > max_ts:
                                max_ts = t
                        except Exception:
                            pass
                    msgs.append({
                        "role": role,
                        "text": text[:3000],
                        "timestamp": ts,
                    })
            if not msgs:
                continue
            # Filter: session must have at least one message within today
            in_range = False
            for m in msgs:
                if m.get("timestamp"):
                    try:
                        t = datetime.fromisoformat(m["timestamp"].replace("Z", "+00:00"))
                        epoch = t.timestamp()
                        if TS_START <= epoch < TS_END:
                            in_range = True
                            break
                    except Exception:
                        pass
            if not in_range:
                # fallback: check mtime
                if TS_START <= st.st_mtime < TS_END:
                    in_range = True
            if not in_range:
                continue
            kept_sessions[session_id] = {
                "id": session_id,
                "project": project_dir,
                "mtime": st.st_mtime,
                "messages": msgs,
                "first_ts": min_ts.isoformat() if min_ts else None,
                "last_ts": max_ts.isoformat() if max_ts else None,
            }
        except Exception as e:
            print(f"[cc] file err {fp}: {e}", flush=True)
    result["sources"]["claude_code"]["conversations"] = list(kept_sessions.values())
    result["sources"]["claude_code"]["status"] = "ok"
    print(f"[cc] sessions kept: {len(kept_sessions)}", flush=True)
    total_msgs = sum(len(s["messages"]) for s in kept_sessions.values())
    print(f"[cc] total messages: {total_msgs}", flush=True)
except Exception as e:
    result["sources"]["claude_code"]["status"] = "failed"
    result["sources"]["claude_code"]["reason"] = str(e)
    print(f"[cc] FAILED: {e}", flush=True)

# ========== Write raw ==========
out_path = RAW_DIR / f"{DATE}.json"
with open(out_path, "w") as f:
    json.dump(result, f, ensure_ascii=False, indent=2, default=str)
print(f"[raw] wrote {out_path}", flush=True)

# ========== Quick summary ==========
print("\n=== SUMMARY ===")
for src, info in result["sources"].items():
    if src == "codex":
        n_msgs = len(info["conversations"])
        print(f"{src}: status={info['status']}, messages={n_msgs}")
    elif src == "claude_code":
        n_sess = len(info["conversations"])
        n_msgs = sum(len(s["messages"]) for s in info["conversations"])
        print(f"{src}: status={info['status']}, sessions={n_sess}, messages={n_msgs}")
    else:
        print(f"{src}: status={info['status']}")
