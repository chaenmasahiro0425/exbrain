#!/bin/bash
# sync-openclaw-to-vault.sh — OpenClawのJSON → vault/daily/ に追記
# Usage: bash sync-openclaw-to-vault.sh [morning|evening]
# OpenClaw cron: 07:30 (morning), 18:30 (evening)
# Cloud TaskがLayer 1でdaily noteを作成済み。このスクリプトはLayer 2でデータ追記。

set +e

MODE="${1:-morning}"
TODAY=$(date +%Y-%m-%d)
WEEKDAY=$(date +%A)
VAULT_DIR="$HOME/vault"
DAILY_FILE="$VAULT_DIR/daily/$TODAY.md"
JSON_FILE="$HOME/clawd/reports/data/daily/$TODAY.json"
LOG_FILE="$VAULT_DIR/.sync.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] sync-vault($MODE): $1" >> "$LOG_FILE"
}

# ロックファイルで同時実行を防止
LOCKFILE="$VAULT_DIR/.git-sync.lock"
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
  log "locked, skipping"; exit 0
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# まずGitHub最新を取得（Cloud Taskがpush済みの可能性）
cd "$VAULT_DIR" && git pull --rebase origin main 2>/dev/null

if [ ! -f "$JSON_FILE" ]; then
  log "JSON not found: $JSON_FILE (OpenClaw may not have generated yet)"
  exit 0
fi

log "Starting $MODE sync"

export DAILY_FILE JSON_FILE MODE TODAY WEEKDAY
python3 << 'PYEOF'
import os, json

mode = os.environ['MODE']
today = os.environ['TODAY']
weekday = os.environ['WEEKDAY']
daily_file = os.environ['DAILY_FILE']
json_file = os.environ['JSON_FILE']

with open(json_file) as f:
    d = json.load(f)

score = d.get('score', 0)
meetings = d.get('meetings', {})
emails = d.get('emails', {})
slack = d.get('slack', {})
deals = d.get('deals', {})
ai = d.get('aiAnalysis', {})
tomorrow = d.get('tomorrow', {})
highlights = d.get('highlights', [])

# daily noteが存在しない場合（Cloud Taskが未実行）→ 作成
if not os.path.exists(daily_file):
    lines = [
        '---', f'date: {today}', f'weekday: {weekday}', 'type: daily',
        f'score: {score}', '---', '',
    ]
    # 最低限のセクション
    for section in ['Schedule', 'Gmail', 'Slack Highlights', 'Salesforce',
                    'AI Analysis', 'Morning Reflection', 'Claude Code Session',
                    'Evening Update', 'Evening Reflection', 'Tomorrow',
                    'Thoughts', 'Links']:
        lines.append(f'## {section}')
        lines.append('')
    with open(daily_file, 'w') as f:
        f.write('\n'.join(lines))

content = open(daily_file).read()

# OpenClaw専用データを追記セクションとして構築
enrich_lines = []

# Salesforce
deal_items = deals.get('items', [])
if isinstance(deal_items, list) and deal_items:
    sf_lines = []
    for dl in deal_items:
        if isinstance(dl, dict):
            name = dl.get('name', dl.get('title', ''))
            stage = dl.get('stage', dl.get('status', ''))
            sf_lines.append(f'- {name}: {stage}')
    active = deals.get('active', 0)
    sf_lines.append(f'- アクティブ案件: {active}件')
    sf_text = '\n'.join(sf_lines)
    if '## Salesforce' in content and content.split('## Salesforce')[1].split('##')[0].strip() == '':
        content = content.replace('## Salesforce\n', f'## Salesforce\n{sf_text}\n', 1)

# AI Analysis
if isinstance(ai, dict) and ai:
    ai_lines = []
    for key, label in [('productivity','生産性'), ('responsiveness','対応力'), ('salesProgress','営業')]:
        info = ai.get(key, {})
        if isinstance(info, dict) and info:
            ai_lines.append(f'- {label}: {info.get("grade","")} — {info.get("comment","")}')
    recs = ai.get('recommendations', [])
    if recs:
        ai_lines.append('')
        for r in recs:
            ai_lines.append(f'- {r}')
    ai_text = '\n'.join(ai_lines)
    if '## AI Analysis' in content and content.split('## AI Analysis')[1].split('##')[0].strip() == '':
        content = content.replace('## AI Analysis\n', f'## AI Analysis\n{ai_text}\n', 1)

if mode == 'evening':
    # Evening Update
    completed = meetings.get('completed', 0)
    total = meetings.get('total', 0)
    sent = emails.get('sent', 0)
    pending = emails.get('pending', 0)
    ev_lines = [
        f'- 会議: {completed}/{total} 完了',
        f'- スコア: {score}',
        f'- メール送信: {sent}件 / 未対応: {pending}件',
    ]
    if highlights:
        for h in highlights:
            if isinstance(h, dict):
                ev_lines.append(f'- {h.get("emoji","")} {h.get("text","")}')
    ev_text = '\n'.join(ev_lines)
    content = content.replace(
        '<!-- sync-openclaw-to-vault.sh evening が自動追記 -->',
        ev_text
    )

    # Tomorrow
    t_lines = []
    t_items = tomorrow.get('items', [])
    if isinstance(t_items, list):
        for t in t_items:
            if isinstance(t, dict):
                time = t.get('time', '')
                title = t.get('title', '')
                warn = ' !!!' if t.get('warning') else ''
                t_lines.append(f'- {time} {title}{warn}')
    t_count = tomorrow.get('meetings', 0)
    t_lines.append(f'')
    t_lines.append(f'明日の会議: {t_count}件')
    advice = ai.get('tomorrowAdvice', '') if isinstance(ai, dict) else ''
    if advice:
        t_lines.append(f'')
        t_lines.append(advice)
    t_text = '\n'.join(t_lines)
    content = content.replace(
        '<!-- sync-openclaw-to-vault.sh evening が自動生成 -->',
        t_text
    )

with open(daily_file, 'w') as f:
    f.write(content)

print(f'{mode} enrichment done: {daily_file}')
PYEOF

# git commit & push
cd "$VAULT_DIR" && git add "daily/$TODAY.md" && git commit -m "enrich: $TODAY $MODE (OpenClaw data)" 2>/dev/null && git push 2>/dev/null

log "Completed $MODE sync"
exit 0
