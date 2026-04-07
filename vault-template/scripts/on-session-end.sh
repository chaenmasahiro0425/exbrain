#!/usr/bin/env bash
# on-session-end.sh — Claude Code Stop hook
# セッション終了時にdaily noteにサマリーを追記する
# 呼び出し元: ~/.claude/settings.json → hooks.Stop (async: true)
set +e

VAULT_DIR="$HOME/vault"
DAILY_DIR="$VAULT_DIR/daily"
LOG="$VAULT_DIR/.sync.log"
TODAY=$(date +%Y-%m-%d)
DAILY_FILE="$DAILY_DIR/$TODAY.md"
NOW=$(date +%H:%M)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] on-session-end" >> "$LOG"

# daily noteが存在しない場合は作成
if [ ! -f "$DAILY_FILE" ]; then
  WEEKDAY=$(TODAY="$TODAY" python3 -c "
import os, datetime
d = datetime.date.fromisoformat(os.environ['TODAY'])
print(d.strftime('%A'))
")
  printf -- "---\ndate: %s\nweekday: %s\n---\n\n## Schedule\n\n## Log\n\n## Thoughts\n\n## Links\n" "$TODAY" "$WEEKDAY" > "$DAILY_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created daily note: $DAILY_FILE" >> "$LOG"
fi

# stdinからJSONを読み取る（hookから渡される）
INPUT=$(cat 2>/dev/null || true)
CWD=$(echo "${INPUT:-{}}" | python3 -c "import sys,json;print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")
LABEL=$([ -n "$CWD" ] && basename "$CWD" || echo "unknown")

ENTRY="- $NOW セッション終了 (cwd: $LABEL)"

# ## Log セクションに追記（環境変数経由でPythonに渡す — シェル補間を避ける）
export DAILY_FILE ENTRY
python3 -c '
import os

f = os.environ["DAILY_FILE"]
e = os.environ["ENTRY"]

lines = open(f).readlines()
out = []
in_log = False
done = False

for l in lines:
    if l.strip() == "## Log":
        in_log = True
        out.append(l)
        continue
    if in_log and not done and l.startswith("## "):
        out.append(e + "\n\n")
        done = True
    out.append(l)

if in_log and not done:
    out.append(e + "\n\n")

open(f, "w").writelines(out)
' 2>/dev/null || echo "$ENTRY" >> "$DAILY_FILE"

exit 0
