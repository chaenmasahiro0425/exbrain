---
type: schema
---

# Obsidian Vault Schema — exbrain 2.0

> このファイルはLLMがvaultを読み書きする際のルール正本。**入口は [[INDEX]]**。
> 200行以下を維持する（毎セッション読み込まれる"常時課金"ゾーン。中身はvault側に置き、ここはポインタに徹する）。

## 4層モデル

| 層 | 場所 | 性質 | 所有者（書く人） |
|----|------|------|----------------|
| **raw** — 生ログ | `daily/` `clips/` `raw/` | 追記のみ。**コンパイラは書き換え禁止（ground truth）** | 自動キャプチャ + 人間 |
| **wiki** — 編纂知識 | `entities/` `clients/` `insights/` `research/` `decisions/` `open-loops.md` | rawから編纂。1ページ1実体/1教訓。全主張に出典リンク | **夜間compile** + Claude/人間 |
| **digest** — 意識の要約 | `MEMORY.md` `DREAMS.md` | 直近の文脈とパターン洞察 | **クラウド認知パイプラインのみ** |
| **identity** — 人格 | `SOUL.md` `VOICE.md` `RED-LINES.md` | 価値観・文体・越えない線 | **人間のみ**（自動更新禁止） |

ミラー層（`system/` `skills/` `memory/`）は Claude Code 内部の可視化。`<!-- SYNCED: DO NOT EDIT -->` 付きは手動編集禁止。

## 書き込み4原則（wiki層）

1. **1ファイル1実体・1教訓** — 冒頭に1行サマリ
2. **複製せず更新** — 既存ページがあればそこに追記。重複ページを作らない
3. **間違いは消す** — 誤りと確定したら削除・修正（rawは消さない）
4. **rawは不可侵** — wikiの全主張は `[[daily/YYYY-MM-DD]]` 等の出典リンクを持つ。出典のないページは信用しない

## 読み取りプロトコル（コンテキスト節約）

- 調べ物は **[[INDEX]] → リンクを辿る** 順。vault全体のフルスキャン禁止
- 大量読みが必要なら subagent に読ませて結論だけ受け取る

## 基本ルール

1. **frontmatter必須** — `type:` `updated:` を最低限含む（researchは `expires:` も）
2. **内部リンク** — `[[フォルダ/ファイル名]]`（拡張子なし）。双方向リンク推奨
3. **日付** — `YYYY-MM-DD`（ISO 8601）

## 命名規則

| コンテンツ | パターン | 例 |
|-----------|---------|-----|
| デイリーノート | `daily/YYYY-MM-DD.md` | `2026-07-04.md` |
| 顧客ページ | `clients/<kebab-case>.md` | `acme-corp.md` |
| 人物/ツール/組織 | `entities/{people,tools,orgs}/<name>.md` | `jane-doe.md` |
| インサイト | `insights/<テーマ>.md` | `deal-close-pattern.md` |
| リサーチ | `research/YYYY-MM-DD_<topic>.md` | `2026-07-04_model-pricing.md` |
| 判断ログ | `decisions/YYYY-MM.md`（月次追記） | `2026-07.md` |
| クリップ | `clips/{x,articles}/YYYY-MM-DD_<slug>.md` | `2026-07-04_llm-wiki.md` |

## 自動ループ（誰がいつ書くか）

| ループ | いつ | 何を | 実体 |
|-------|------|------|------|
| セッションprimer | 毎セッション開始 | 脳の状態をコンテキスト注入（読むだけ） | `scripts/session-primer.sh` (hook) |
| セッション記録 | 毎セッション終了 | daily雛形保証 + git sync | `scripts/on-session-end.sh` (hook) |
| 朝夕の目 | 07:00 / 18:30 | daily note生成・Evening Update | Cloud Scheduled Tasks |
| クリップ | 随時/4hおき | URL・ブックマーク → `clips/` | /clip + 常駐エージェント |
| **夜間compile** | 23:30 | raw → wiki編纂（entities/decisions/open-loops/INDEX） | `scripts/brain-compile.sh`（安価モデル） |
| **週次lint** | 日曜 09:00 | 壊れリンク・重複・陳腐化・期限切れ検出 | `scripts/brain-lint.sh`（LLMなし） |
| 週次Dreaming | 日曜 21:30 | 横断パターン統合 → DREAMS.md | Cloud Task（プレミアムモデル） |
| 毎時pull | 毎時 | クラウド更新の取込 | launchd `brain-pull` |

## フォルダ構成

```
vault/
├── INDEX.md        ← 玄関（全ページの地図+鮮度）★必ずここから
├── CLAUDE.md       ← このファイル（スキーマ正本）
├── SOUL.md / VOICE.md / RED-LINES.md   ← identity層（人間のみ）
├── MEMORY.md / DREAMS.md               ← digest層（クラウドのみ）
├── open-loops.md   ← 未解決ループ（compileが更新）
├── daily/  clips/  raw/                ← raw層
├── entities/  clients/  insights/  research/  decisions/  ← wiki層
├── memory/ system/ skills/ ← Claude Code内部のミラー（SYNCED）
├── templates/      ← entity / concept / research / daily-note / decision
└── scripts/        ← hooks・compile・lint・sync
```
