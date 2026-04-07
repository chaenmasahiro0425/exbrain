#!/usr/bin/env bash
# weekly-sync.sh — 週次Lintスクリプト
# 毎週日曜 03:00 に実行（cron or manual）
# vault内の整合性チェック・壊れたリンク検出・orphanページ検出
set +e

VAULT="$HOME/vault"
LOG="$VAULT/.sync.log"
ISSUES=""
IC=0

add() {
  ISSUES="${ISSUES}"$'\n'"- $1"
  IC=$((IC + 1))
}

echo "[$(date '+%F %T')] weekly-sync start" >> "$LOG"

# 1. 壊れたwikilinksを検出（grep -oE はmacOS互換）
echo "--- Checking broken wikilinks ---"
while IFS= read -r -d '' f; do
  # grep -oE で [[...]] リンクを抽出（-oP は macOS 非対応なので使わない）
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    [ ! -f "$VAULT/${link}.md" ] && add "Broken: [[${link}]] in $(basename "$f")"
  done < <(grep -oE '\[\[[^]|]+' "$f" 2>/dev/null | sed 's/\[\[//')
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/templates/*" -print0)

# 2. 過去7日のdaily noteが存在するかチェック
echo "--- Checking daily notes ---"
for i in $(seq 1 7); do
  d=$(date -v-"${i}d" +%Y-%m-%d 2>/dev/null || continue)
  [ ! -f "$VAULT/daily/${d}.md" ] && add "Missing daily: ${d}"
done

# 3. SYNCEDファイルのヘッダーチェック
echo "--- Checking SYNCED headers ---"
while IFS= read -r -d '' f; do
  FIRST_LINE=$(head -1 "$f")
  case "$FIRST_LINE" in
    "<!-- SYNCED: DO NOT EDIT -->") ;;
    *) add "Missing SYNCED header: $(basename "$f")" ;;
  esac
done < <(find "$VAULT/system" -name "*.md" -print0 2>/dev/null)

# 4. frontmatterのないファイルを検出
echo "--- Checking frontmatter ---"
while IFS= read -r -d '' f; do
  FIRST_LINE=$(head -1 "$f")
  case "$FIRST_LINE" in
    "---"|"<!-- SYNCED: DO NOT EDIT -->") ;;
    *) add "Missing frontmatter: $(basename "$f")" ;;
  esac
done < <(find "$VAULT" -name "*.md" -not -path "*/templates/*" -not -path "*/.obsidian/*" -print0 2>/dev/null)

# 5. CLAUDE.mdの総数をカウント
echo "--- Counting CLAUDE.md files ---"
CLAUDE_COUNT=0
while IFS= read -r -d '' _f; do
  CLAUDE_COUNT=$((CLAUDE_COUNT + 1))
done < <(find "$HOME/work" "$HOME/dev" "$HOME/content" -name "CLAUDE.md" -print0 2>/dev/null)

echo "[$(date '+%F %T')] weekly-sync done: $IC issues, $CLAUDE_COUNT CLAUDE.md files" >> "$LOG"

# サマリー出力
if [ "$IC" -gt 0 ]; then
  printf "Lint: %s issues%s\n" "$IC" "$ISSUES"
else
  echo "Lint: All clear! ($CLAUDE_COUNT CLAUDE.md files)"
fi

exit 0
