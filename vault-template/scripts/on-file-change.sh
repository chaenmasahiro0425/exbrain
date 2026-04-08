#!/usr/bin/env bash
# on-file-change.sh — Claude Code PostToolUse hook (Write|Edit)
# ファイル変更時にvaultの関連ページを更新する
# 呼び出し元: ~/.claude/settings.json → hooks.PostToolUse (async: true)
set +e

LOG="$HOME/vault/.sync.log"

# stdinからJSON（tool_input）を読み取る
INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

# 変更されたファイルパスを抽出
FP=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', d)
    print(ti.get('file_path', ti.get('path', '')))
except (json.JSONDecodeError, AttributeError, TypeError, KeyError):
    print('')
" 2>/dev/null || echo "")

[ -z "$FP" ] && exit 0

# パスに基づいて同期対象を判定（case文でgrepを避ける）
case "$FP" in
  */vault/*)
    # vault内のファイル変更は無視（再帰防止）
    ;;
  */CLAUDE.md)
    echo "[$(date '+%F %T')] CLAUDE.md changed: $FP" >> "$LOG"
    ;;
  */.claude/projects/*/memory/*|*/memory/*)
    echo "[$(date '+%F %T')] Memory changed: $FP" >> "$LOG"
    ;;
  */.claude/skills/*|*/skills/*)
    echo "[$(date '+%F %T')] Skill changed: $FP" >> "$LOG"
    ;;
  */clients/*/minutes/*)
    echo "[$(date '+%F %T')] Minutes changed: $FP" >> "$LOG"
    ;;
  *)
    # 同期対象外
    ;;
esac

exit 0
