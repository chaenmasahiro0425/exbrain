#!/usr/bin/env bash
# on-session-end.sh — Claude Code Stop hook
# 役割（再設計 2026-06-14）:
#   1) 本日の daily note が無ければ最小テンプレで作成（クラウドが後で enrich する）
#   2) liveness を .sync.log に1行記録
#   3) ローカル変更をクラウドへ双方向同期（デバウンス付き vault-sync.sh）
# 旧版がやっていた「## Log への セッション終了 連打」と「MEMORY.md 直接追記」は撤去。
#   理由: MEMORY/DREAMS/日報の enrich はクラウド認知パイプラインが所有する。
#         ローカルが書くと (a) スパム化 (b) クラウド再生成と競合 を招くため。
# 呼び出し元: ~/.claude/settings.json → hooks.Stop (async: true)
set +e

VAULT="$HOME/vault"
LOG="$VAULT/.sync.log"
T=$(date +%Y-%m-%d)
DAILY="$VAULT/daily/$T.md"

echo "[$(date '+%F %T')] session-end" >> "$LOG"

if [ ! -f "$DAILY" ]; then
  WD=$(python3 -c "import datetime;print(datetime.date.today().strftime('%A'))" 2>/dev/null || echo "")
  printf -- "---\ndate: %s\nweekday: %s\n---\n\n## Schedule\n\n## Sessions\n\n## Thoughts\n\n## Links\n" "$T" "$WD" > "$DAILY"
  echo "[$(date '+%F %T')] created daily note (cloud will enrich)" >> "$LOG"
fi

# ローカル→クラウド同期（バックグラウンド・デバウンス）
( bash "$VAULT/scripts/vault-sync.sh" >/dev/null 2>&1 & )
exit 0
