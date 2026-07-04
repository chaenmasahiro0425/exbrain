#!/usr/bin/env bash
# session-primer.sh — SessionStart hook 用。現在の「脳の状態」を stdout に出力し、
# Claude Code が additionalContext として注入する。READ-ONLY（git 操作なし）。
# 目的: どのプロジェクトで開いても、セッションが「あなたの今」を知った状態で始まる（分身化の核）。
set +e
VAULT="$HOME/vault"
T=$(date +%F)

echo "## 🧠 exbrain — 今の文脈 ($(date '+%Y-%m-%d (%a) %H:%M'))"

# 今日の予定
D="$VAULT/daily/$T.md"
if [ -f "$D" ]; then
  sched=$(awk '/^## *(Schedule|スケジュール|予定)/{f=1;next} f&&/^## /{exit} f&&NF{print}' "$D" | head -8)
  [ -n "$sched" ] && { echo; echo "### 今日の予定"; echo "$sched"; }
fi

# 直近の出来事（クラウドが維持する MEMORY ダイジェスト）
if [ -f "$VAULT/MEMORY.md" ]; then
  rec=$(awk '/## Recent/{f=1;next} f&&/^## /{exit} f&&/^- /{print; c++} c>=6{exit}' "$VAULT/MEMORY.md" | cut -c1-220)
  [ -n "$rec" ] && { echo; echo "### 直近の出来事"; echo "$rec"; }
fi

# 未解決ループ
if [ -f "$VAULT/open-loops.md" ]; then
  ol=$(grep '^- \[ \]' "$VAULT/open-loops.md" | head -8)
  [ -n "$ol" ] && { echo; echo "### 未解決ループ（要対応）"; echo "$ol"; }
fi

# 直近の意思決定
if [ -d "$VAULT/decisions" ]; then
  last=$(ls -t "$VAULT/decisions"/*.md 2>/dev/null | head -1)
  [ -n "$last" ] && { dec=$(grep -m3 '^- ' "$last"); [ -n "$dec" ] && { echo; echo "### 直近の意思決定"; echo "$dec"; }; }
fi

echo
echo "_入口: ~/vault/INDEX.md（4層地図）。文体・境界は VOICE.md / RED-LINES.md。詳しい照会は /ask-brain。_"
exit 0
