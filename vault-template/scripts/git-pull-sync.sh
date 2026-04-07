#!/bin/bash
# git-pull-sync.sh — GitHub から最新を取得して iCloud に反映
# launchd で毎時実行。Cloud Taskがpushした変更をローカルに取り込む。

set +e

VAULT_DIR="$HOME/vault"
LOG_FILE="$VAULT_DIR/.sync.log"
LOCKFILE="$VAULT_DIR/.git-sync.lock"

cd "$VAULT_DIR" || exit 0

# ロックファイルで同時実行を防止
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
  echo "[$(date '+%F %T')] git-pull: locked, skipping" >> "$LOG_FILE"; exit 0
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY" -gt "0" ]; then
  git stash 2>/dev/null
  if ! git pull --rebase origin main 2>/dev/null; then
    git rebase --abort 2>/dev/null
    echo "[$(date '+%F %T')] git-pull: rebase failed, aborted" >> "$LOG_FILE"
  fi
  if ! git stash pop 2>/dev/null; then
    echo "[$(date '+%F %T')] git-pull: stash pop FAILED — manual resolution needed" >> "$LOG_FILE"
    git checkout -- . 2>/dev/null
    git stash drop 2>/dev/null
  fi
  echo "[$(date '+%F %T')] git-pull: pulled with stash (dirty=$DIRTY)" >> "$LOG_FILE"
else
  RESULT=$(git pull --rebase origin main 2>&1)
  if ! echo "$RESULT" | grep -q "Already up to date"; then
    echo "[$(date '+%F %T')] git-pull: $RESULT" >> "$LOG_FILE"
  fi
fi

exit 0
