#!/usr/bin/env bash
# brain-compile.sh — 夜間コンパイラ（exbrain 2.0 の心臓）
# raw層（daily/ clips/ raw/）を読み、wiki層（entities/ clients/ insights/ decisions/ open-loops / INDEX）を編纂する。
# launchd: com.YOURNAME.brain-compile（毎日23:30）。安価モデル（haiku）で実行 = 「routine work, routine tier」。
# 設計: LLMはRead/Write/Edit/Glob/Grepのみ。git操作はこのスクリプトが行う（暴走防止）。
set +e
VAULT="$HOME/vault"
LOG="$VAULT/.compile.log"
STATE="$VAULT/scripts/.compile-state"
LOCK="$VAULT/.compile.lock"
MODEL="${BRAIN_COMPILE_MODEL:-claude-haiku-4-5}"

cd "$VAULT" 2>/dev/null || exit 0

log(){ echo "[$(date '+%F %T')] compile: $*" >> "$LOG"; }

# 多重起動防止
if [ -f "$LOCK" ]; then
  pid=$(cat "$LOCK" 2>/dev/null)
  kill -0 "$pid" 2>/dev/null && { log "locked (pid=$pid), skip"; exit 0; }
fi
echo $$ > "$LOCK"; trap 'rm -f "$LOCK"' EXIT

# claude CLI 解決（cmux同梱 / homebrew / local を順に探す）
CLAUDE=""
for c in "$(command -v claude 2>/dev/null)" \
         "$HOME/.local/bin/claude" "/opt/homebrew/bin/claude" \
         "/Applications/cmux.app/Contents/Resources/bin/claude"; do
  [ -n "$c" ] && [ -x "$c" ] && CLAUDE="$c" && break
done
[ -z "$CLAUDE" ] && { log "ERROR: claude CLI not found"; exit 1; }

# 未コンパイル日を列挙（前回状態〜今日、最大3日分）
today=$(date +%F)
last=$(cat "$STATE" 2>/dev/null)
[ -z "$last" ] && last=$(date -v-1d +%F)
dates=""
d="$last"; n=0
while [ "$d" != "$today" ] && [ $n -lt 3 ]; do
  d=$(date -j -f %F -v+1d "$d" +%F 2>/dev/null) || break
  dates="$dates $d"; n=$((n+1))
done
[ -z "$dates" ] && { log "up to date ($last)"; exit 0; }

# 事前pull（クラウド側の当日ノートを取り込む）
bash "$VAULT/scripts/vault-sync.sh" --pull-only >/dev/null 2>&1

for DATE in $dates; do
  [ -f "$VAULT/daily/$DATE.md" ] || { log "$DATE: daily note無し、skip"; echo "$DATE" > "$STATE"; continue; }
  MONTH=$(echo "$DATE" | cut -c1-7)
  NEW_CLIPS=$(cd "$VAULT" && git log --since="$DATE 00:00" --until="$DATE 23:59" --name-only --pretty=format: -- clips/ 2>/dev/null | grep -v '^$' | sort -u | head -30)

  PROMPT="あなたは exbrain（~/vault）の夜間コンパイラ。対象日 $DATE の raw を読み、wiki層を差分最小で編纂せよ。

手順:
1. ~/vault/CLAUDE.md と ~/vault/INDEX.md を読み、ルールを確認
2. ~/vault/daily/$DATE.md を精読。当日の新規クリップ（下記）と ~/vault/raw/ 内の未処理ファイルも確認
3. 登場した顧客は ~/vault/clients/<kebab>.md、人物は ~/vault/entities/people/、ツール/組織は ~/vault/entities/{tools,orgs}/ の該当ページを更新（無ければ templates/entity.md 形式で新規作成）。**既存の記述は消さない（追記・訂正のみ）。全追記に出典 [[daily/$DATE]] を付ける**
3b. **当日のclips（下記）を"読んだ記憶"として編纂する**:
   - clipが事業/顧客/技術/自分の関心テーマに関連するなら、該当する entities/tools・clients・insights ページの「## 参考にした記事」等に [[clips/x/...]]（または articles/）形式でリンクし、なぜ関係するかを一言添える
   - frontmatter に fav: true（お気に入り）が付いたclipは、たとえ単発でも必ずどこかのwikiページに取り込む
   - 複数のclipが同じテーマに収束していたら insights/ に1教訓として編纂（出典に全clipリンク）
   - 単なるニュース・自分と無関係なものは取り込まない（clips/ に残るだけでよい。選別はこのcompileがやる＝人間は選ばなくてよい）
4. 意思決定（金額・契約・方針・人事）があれば ~/vault/decisions/$MONTH.md に追記（無ければ作成）
5. ~/vault/open-loops.md を更新: 新規の未解決事項を追加、完了が確認できた項目は [x] にして '## Closed' へ移動（出典付き）
6. 明確に繰り返しが確認できた新パターンのみ ~/vault/insights/ に1ファイル1教訓で追加（乱造禁止。確信が持てない場合は作らない）
7. ~/vault/INDEX.md の鮮度ダッシュボードと updated: を更新
8. clients/_index.md・entities/_index.md に新規ページのリンクを追加

制約:
- raw層（daily/ clips/ raw/）は読み取り専用。書き換え禁止
- MEMORY.md / DREAMS.md / SOUL.md / VOICE.md / RED-LINES.md / system/ / skills/ / memory/ に触れない
- 出典のない主張を書かない。報告前に各変更をツール結果と突き合わせ、実際に書いた変更だけを報告する

当日の新規クリップ:
$NEW_CLIPS

完了したら変更ファイルの一覧を1行ずつ出力して終了。"

  log "$DATE: start (model=$MODEL)"
  "$CLAUDE" -p "$PROMPT" \
    --model "$MODEL" --fallback-model claude-sonnet-5 \
    --allowedTools "Read" "Write" "Edit" "Glob" "Grep" \
    --permission-mode acceptEdits \
    >> "$LOG" 2>&1
  rc=$?
  log "$DATE: done rc=$rc"

  # wiki層のみコミット（raw層に触れていたら異常なので何もしない安全弁）
  changed=$(git status --porcelain -- daily/ clips/ raw/ MEMORY.md DREAMS.md SOUL.md VOICE.md RED-LINES.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$changed" -gt 0 ]; then
    log "$DATE: ABORT — raw/digest/identity層に変更検出。復元する"
    git checkout -- daily/ clips/ raw/ MEMORY.md DREAMS.md SOUL.md VOICE.md RED-LINES.md 2>/dev/null
  fi
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A && git commit -q -m "compile: $DATE (nightly wiki build)"
  fi
  [ $rc -eq 0 ] && echo "$DATE" > "$STATE"
done

# push（rebase pull込みの既存フロー）
bash "$VAULT/scripts/vault-sync.sh" >/dev/null 2>&1
log "batch done"
exit 0
