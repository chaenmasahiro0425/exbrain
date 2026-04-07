# Claude Code × Obsidian Wiki — Your AI Remembers, Reflects, and Evolves

> AIが勝手に記憶し、整理し、毎朝振り返ってくれるナレッジシステム
>
> Inspired by [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) + OpenClaw's Dreaming pattern

Claude Codeの中に眠っている記憶（Memory）、設定ファイル（CLAUDE.md）、スキル（Skills）を
Obsidianで可視化し、毎朝・毎夕のDreamingで自動振り返りを行う仕組み。

PC閉じてても動く。iPhoneからも見える。人間はObsidianを開いて読むだけ。

## コンセプト

```
┌─ Claude Code の世界（普段は .claude/ に隠れている）───────────┐
│                                                              │
│   CLAUDE.md ×N   ←──┐                                      │
│   CC Memory ×N   ←──┤── 自動同期 ──→  ~/vault/              │
│   Skills ×N      ←──┤                  (Obsidian)           │
│   Cron jobs      ←──┘                  人間が見る窓          │
│                                                              │
│   + 日記（daily/）は Obsidian にだけ存在                       │
│   + Dreaming（朝夕の自動振り返り）で知見が複利で増える           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 3つの性格を持つハイブリッド設計

```
vault/
├── system/, skills/, memory/
│   → 静的ミラー（ダッシュボード）
│   → Claude Codeの中身を自動同期、人間は読むだけ
│   → <!-- SYNCED: DO NOT EDIT --> ヘッダー付き
│
├── daily/
│   → 自動ログ + 手書き日記
│   → Calendar + Slack + Gmail + AI Analysis
│   → 朝夕2回のDreaming（パターン検出・振り返り）
│
└── meetings/, clients/, insights/
    → Karpathyパターン（知識が複利で増える）
    → 議事録を処理するたびに顧客ページに自動蓄積
    → 12回の議事録を読み返す必要がない
```

## アーキテクチャ

```
┌─ Layer 1: Cloud Scheduled Tasks（PC不要）──────────────────┐
│                                                             │
│  毎朝 07:00  vault-daily-morning                            │
│  ├── Google Calendar → 今日の予定                            │
│  ├── Slack → 昨夜〜今朝のハイライト                           │
│  ├── Gmail → 未読・重要メール                                │
│  ├── Morning Dreaming（昨日の振り返り→今日の注目）            │
│  └── GitHub push                                            │
│                                                             │
│  毎夕 18:30  vault-daily-evening                            │
│  ├── Evening Dreaming（今日+7日分→パターン検出）             │
│  ├── 日曜は週次Dreaming + Lint + Slack通知                   │
│  └── GitHub push                                            │
│                                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ push
                       ▼
┌─ GitHub (private repo) ─────────────────────────────────────┐
│  vault/ の全ファイル                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │ pull (launchd 毎時)
                       ▼
┌─ Layer 2: ローカル自動化 ───────────────────────────────────┐
│                                                             │
│  Claude Code Hooks (async: true)                            │
│  ├── PostToolUse → ファイル変更をログ記録                      │
│  └── Stop → セッション終了をdaily noteに自動追記              │
│                                                             │
│  OpenClaw Cron（PCオン時の追加データ）                         │
│  ├── SF/Stripe/HERP/YouTube等の専門データ追記                 │
│  └── PCオフなら単にスキップ（Layer 1だけで完成）               │
│                                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ iCloud
                       ▼
              Obsidian (Mac + iPhone)
```

## AIの記憶システム（Memory）

Claude Codeは `.claude/projects/*/memory/` に記憶を保存する。
この記憶がObsidianに自動ミラーされ、人間が読める形になる。

```
memory/
├── feedback/ (21件) ← AIへの行動指針
│   ├── never-send-email.md      「メール送信は絶対禁止。下書きのみ」
│   ├── gas-version-control.md   「GAS編集後は毎回git commit」
│   └── minutes-include-sf.md    「議事録にはSF+Slack報告も含める」
│
├── reference/ (7件) ← 外部システムへのポインタ
│   ├── wordpress-api.md         「APIの認証情報はここ」
│   └── typefully-api.md         「X投稿はTypefully経由」
│
├── project/ (4件)   ← プロジェクト状況
│   └── personal-budget.md       「月間支出目標¥3,000,000」
│
└── user/ (1件)      ← ユーザープロファイル
    └── user-profile.md          「シェル環境にまだ詳しくない」
```

AIが過去の失敗や指示を覚えていて、次から同じミスをしない。
その記憶が全部Obsidianで見える。「何を覚えてるの？」が一目瞭然。

## Dreaming（朝夕の自動振り返り）

OpenClawのSOUL/MEMORY/DREAMSパターンを参考に設計。

```
毎朝 07:00 — Morning Dreaming
├── 昨日のdaily noteを読み返す
├── 決定事項・未解決タスクを抽出
└── 「今日の注目ポイント」を3行で生成

毎夕 18:30 — Evening Dreaming
├── 今日のSlack/Gmail/Calendarを振り返り
├── 直近7日とのパターン比較
│   例: 「火曜は会議密度が高い（3週連続）」
│   例: 「メール返信が午後に集中」
├── 未解決の問いを抽出
└── パターンが見つかったら insights/ にページ作成

毎週日曜 — Weekly Dreaming
├── 1週間分のdailyから洞察を抽出
├── DREAMS.md に成長軌跡を記録
├── Lint（壊れたリンク・orphanページ検出）
└── Slackでサマリー通知
```

DREAMS.mdに蓄積される内容:
- Current Insights（最新の内省結果）
- Emerging Patterns（浮かび上がるパターン）
- Growth Trajectory（成長の軌跡）
- Open Questions（未解決の問い）

## Vault構造

```
~/vault/
├── CLAUDE.md              ← Schema（LLM向けルール定義）
├── DREAMS.md              ← Dreaming蓄積ファイル
│
├── daily/                 ← デイリーノート
│   └── 2026-04-07.md      　 Schedule / Gmail / Slack / AI Analysis /
│                              Morning Reflection / Evening Reflection /
│                              Claude Code Session / Thoughts
│
├── system/                ← Claude Codeシステムのミラー（SYNCED）
│   ├── claude-md-tree.md  　 全CLAUDE.mdの階層ツリー
│   ├── global-rules.md    　 ルール・禁止事項の要約
│   ├── api-inventory.md   　 保有API一覧（キーは除外）
│   ├── tech-stack.md      　 技術スタック
│   └── cron-jobs.md       　 稼働中ジョブ一覧
│
├── skills/                ← 全スキル一覧 + 個別ページ（SYNCED）
│   ├── _index.md          　 カテゴリ別テーブル
│   └── auto-minutes.md    　 各スキルの説明・コマンド
│
├── memory/                ← CC Memory完全ミラー（SYNCED）
│   ├── _index.md          　 全メモリ一覧（タイプ別）
│   ├── feedback/          　 行動指針
│   ├── reference/         　 外部参照
│   ├── project/           　 プロジェクト状況
│   └── user/              　 ユーザープロファイル
│
├── clients/               ← 顧客ナレッジ蓄積（Karpathyパターン）
│   ├── _index.md          　 全顧客一覧
│   └── naoru.md           　 議事録のたびに自動蓄積
│
├── meetings/              ← 議事録要点（/auto-minutes連携）
├── decisions/             ← 経営判断ログ
├── insights/              ← 学び・パターン + 週次Dreaming
├── templates/             ← daily-note, meeting, decision
└── scripts/               ← hookスクリプト + 同期スクリプト
```

## セットアップ手順

### 前提条件
- Claude Code（Pro or Max）
- Obsidian（無料）
- GitHub アカウント
- （オプション）Slack / Google Calendar / Gmail の Connector

### Step 1: Vault作成

```bash
# フォルダ作成
mkdir -p ~/vault/{daily,system,skills,memory/{feedback,reference,project,user},clients,meetings,decisions,insights,templates,scripts}

# iCloud同期（iPhone対応する場合）
mv ~/vault ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/claude-code
ln -s ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/claude-code ~/vault
```

### Step 2: テンプレートファイルをコピー

このリポジトリの `vault-template/` をコピー:

```bash
cp -r vault-template/* ~/vault/
```

### Step 3: Claude Code Hooks 設定

`~/.claude/settings.json` に追加:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash ~/vault/scripts/on-file-change.sh",
        "async": true
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "bash ~/vault/scripts/on-session-end.sh",
        "async": true
      }]
    }]
  }
}
```

### Step 4: 初回同期

Claude Codeで実行:

```
/wiki-sync-init
```

または手動:

```bash
# Skills同期
for d in ~/.claude/skills/*/; do
  name=$(basename "$d")
  # SKILL.md を読んで vault/skills/ にページ作成
done

# Memory同期
find ~/.claude/projects -name "*.md" -path "*/memory/*" ! -name "MEMORY.md" | while read src; do
  # vault/memory/ にミラー作成
done
```

### Step 5: GitHub + 自動pull

```bash
cd ~/vault
git init && git add -A && git commit -m "Initial vault"
gh repo create my-vault --private --source=. --push
```

### Step 6: Cloud Scheduled Tasks（オプション、PC不要にする場合）

claude.ai/code/scheduled で:
- **vault-daily-morning**: 毎朝07:00、Calendar+Slack+Gmail→daily note生成
- **vault-daily-evening**: 毎夕18:30、Evening Dreaming+パターン検出

## デイリーノートの完成形

```markdown
---
date: 2026-04-07
weekday: Monday
type: daily
score: 74
---

## Schedule
| 時間 | 予定 | 備考 |
|------|------|------|
| 09:00 | 経営管理部 定例 | |
| 10:00 | 開発営業 定例 | |
| 14:00 | デジライズ定例 | |

## Gmail
| From | Subject | Action |
|------|---------|--------|
| freee 上野 | セミナー開催打合せ | 要返信 |

## Slack Highlights
- **#経営**: 人事部長アサイン議論
- **#開発営業**: チャットbot進捗、SF議事録デモ依頼
- **#日報_柴田**: エイジス様研修225万円受注ほぼ確定

## AI Analysis
- 生産性: B — 会議完了率100%
- 対応力: B — 未読メール6件
- 営業: B- — 商談0件

## Morning Reflection
- 昨日の決定: スクール料金改定を決定
- 今日の注目: freeeセミナー返信、金成さんMTG

## Evening Reflection
- 今日のハイライト: エイジス225万円ほぼ確定
- パターン: 月曜は会議が10件超で最多（3週連続）
- 未解決: freeeセミナー返信

## Thoughts
<!-- 自分で一言 -->
```

## 参考

- [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 設計思想の原点
- [obsidian-wiki (Ar9av)](https://github.com/Ar9av/obsidian-wiki) — Karpathyパターンのフレームワーク
- [QMD](https://github.com/tobi/qmd) — Markdownセマンティック検索（100ページ超で導入検討）
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks-guide) — async hookの公式ドキュメント
- [Cloud Scheduled Tasks](https://code.claude.com/docs/en/web-scheduled-tasks) — PC不要の自動化

## License

MIT
