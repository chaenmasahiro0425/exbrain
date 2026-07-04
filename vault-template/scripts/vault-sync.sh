#!/usr/bin/env bash
# vault-sync.sh — exbrain vault の双方向 git 同期（hook 駆動 = Claude の FDA コンテキストで動くため iCloud TCC を踏まない）
# 使い方: vault-sync.sh [--pull-only]
#   --pull-only : ローカルをコミットして取り込むが push はしない（SessionStart用）
# 設計原則:
#   - rebase 前に必ずローカルをコミット（unstaged だと rebase 不可のため）
#   - 競合は「本物の content 競合」だけ検知 → abort して通知（既存データを絶対に壊さない / data-repair-safety）
set +e

VAULT="$HOME/vault"
LOG="$VAULT/.sync.log"
LOCK="$VAULT/.git-sync.lock"

cd "$VAULT" 2>/dev/null || exit 0
log(){ echo "[$(date '+%F %T')] vault-sync: $*" >> "$LOG"; }

# 多重起動防止（PIDロック）
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then exit 0; fi
echo $$ > "$LOCK"; trap 'rm -f "$LOCK"' EXIT

pullonly=0
for a in "$@"; do [ "$a" = "--pull-only" ] && pullonly=1; done

# 1) ローカル変更をコミット（rebase のためツリーを常にクリーンにする）
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "auto(vault): $(date '+%F %T')" && log "committed local changes"
fi

# 2) クラウドから rebase pull。
#    daily/ のみの競合はクラウド版を正本として自動採用（cloud が日報の所有者）。
#    それ以外の競合は既存データを壊さないよう安全に abort + 通知（手動解決へ）。
out=$(git pull --rebase origin main 2>&1)
if echo "$out" | grep -qiE 'CONFLICT|Merge conflict|needs merge|unmerged'; then
  tries=0
  while [ -n "$(git diff --name-only --diff-filter=U 2>/dev/null)" ] && [ $tries -lt 20 ]; do
    # 非daily競合が1つでもあれば自動解決しない（macOSのgrep -qvは不安定なので行数で判定）
    if [ "$(git diff --name-only --diff-filter=U | grep -cv '^daily/' | tr -d ' ')" -gt 0 ]; then break; fi
    # rebase中は --ours = リベース先(origin/main=クラウド)。日報はクラウドを正本として採用。
    git diff --name-only --diff-filter=U | while IFS= read -r f; do
      [ -n "$f" ] && git checkout --ours -- "$f" 2>/dev/null && git add -- "$f" 2>/dev/null
    done
    GIT_EDITOR=true git rebase --continue >/dev/null 2>&1 || break
    tries=$((tries + 1))
  done
  if [ -n "$(git diff --name-only --diff-filter=U 2>/dev/null)" ] || [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    git rebase --abort 2>/dev/null
    log "REBASE CONFLICT — aborted（非daily or 解決不能）, 手動確認が必要"
    osascript -e 'display notification "vault同期に競合。手動確認が必要です" with title "exbrain ⚠️" sound name "Basso"' 2>/dev/null
  else
    log "auto-resolved daily conflict（cloud版採用, ${tries}step）"
  fi
elif echo "$out" | grep -qi 'up to date'; then
  :
else
  log "pulled: $(echo "$out" | tail -1)"
fi

# 3) push（pull-only時は除く）
if [ "$pullonly" = 0 ]; then
  ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
  if [ "${ahead:-0}" -gt 0 ]; then
    git push -q origin main 2>>"$LOG" && log "pushed ${ahead} commit(s)" || log "PUSH FAILED (offline?)"
  fi
fi

# 4) ログ・ローテーション
if [ "$(wc -l < "$LOG" 2>/dev/null || echo 0)" -gt 800 ]; then
  tail -n 400 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
fi
exit 0
