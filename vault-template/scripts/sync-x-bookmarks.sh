#!/bin/bash
# sync-x-bookmarks.sh — X ブックマーク自動同期
# OpenClaw cron (4時間おき) または手動実行
# 最新ブックマークを取得して vault/clips/x/ に保存

set -euo pipefail

VAULT_DIR="$HOME/vault"
CLIPS_DIR="$VAULT_DIR/clips/x"
INDEX_FILE="$VAULT_DIR/clips/_index.md"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="$VAULT_DIR/.sync.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sync-x-bookmarks] $*" >> "$LOG_FILE"; }

# 依存コマンド確認
for cmd in xurl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    log "ERROR: $cmd not found in PATH"
    exit 1
  fi
done

log "Starting X bookmark sync for $TODAY"

# ブックマークを取得（--auth oauth2 が必須）
if ! BOOKMARKS=$(xurl bookmarks -n 20 --auth oauth2 2>&1); then
  log "ERROR: xurl bookmarks failed: $BOOKMARKS"
  exit 1
fi

if [ -z "$BOOKMARKS" ]; then
  log "No bookmarks found (empty response)"
  exit 0
fi

# JSONバリデーション + ブックマーク数カウント
if ! COUNT=$(echo "$BOOKMARKS" | jq -r '.data | length' 2>&1); then
  log "ERROR: invalid JSON from xurl: $COUNT"
  exit 1
fi

log "Found $COUNT bookmarks"

if [ "$COUNT" = "0" ]; then
  log "No bookmarks to process"
  exit 0
fi

# includes.users から author_id → username マッピングを構築
USER_MAP=$(echo "$BOOKMARKS" | jq -r '[.includes.users[]? | {(.id): .username}] | add // {}')

# 各ブックマークを処理
# スクリプト単体ではJSON出力のみ。要約・タグ生成はLLMが行う
NEW_COUNT=0
echo "$BOOKMARKS" | jq -c '.data[]' | while read -r tweet; do
  TWEET_ID=$(echo "$tweet" | jq -r '.id')
  TWEET_TEXT=$(echo "$tweet" | jq -r '.text // empty')
  AUTHOR_ID=$(echo "$tweet" | jq -r '.author_id // "unknown"')
  # includes.users からユーザー名を解決
  AUTHOR=$(echo "$USER_MAP" | jq -r --arg id "$AUTHOR_ID" '.[$id] // "unknown"')

  # 既にクリップ済みか確認
  if grep -rq "status/$TWEET_ID" "$CLIPS_DIR/" 2>/dev/null; then
    log "Skip: tweet $TWEET_ID already clipped"
    continue
  fi

  NEW_COUNT=$((NEW_COUNT + 1))
  log "New bookmark: $TWEET_ID by @$AUTHOR"
  echo "{\"id\":\"$TWEET_ID\",\"text\":$(echo "$TWEET_TEXT" | jq -Rs .),\"author\":\"@$AUTHOR\"}"
done

log "Sync complete (new: $NEW_COUNT)"
