<p align="center">
  <img src="assets/banner.png" alt="Exbrain Banner" width="800">
</p>

<h1 align="center">Exbrain 2.0 — 自律成長する外付けのAI脳</h1>

<p align="center">
  <b>記憶し、編纂し、検証し、自ら進化するAIナレッジシステム</b><br>
  Claude Code × Obsidian × 4層アーキテクチャ<br><br>
  <a href="README.md">🇺🇸 English</a> · <a href="https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f">Karpathy's LLM Wiki</a> にインスパイア
</p>

## Exbrainとは？

最強のAIモデルが平凡なアウトプットしか出さない理由はひとつ — **あなたのことを何も知らない**から。

Exbrainは、Claude Codeが読み書きする「外付けの脳」をObsidian（＝ただのMarkdownフォルダ）の上に作る。あなたの日々・顧客・意思決定・学びが自動で蓄積・編纂され、**すべてのセッションが「あなたの今」を知った状態で始まる**。

- 記憶はあなたのディスクの上、プレーンテキスト。ベンダーロックインなし
- PCを閉じても動く（クラウド側の自動タスク）。iPhoneでも読める（iCloud同期）
- モデルが何に替わっても、脳は生き残る

## v2で何が変わったか

v1（SOUL/MEMORY/DREAMS + クリップ）を3ヶ月運用して分かった最大の教訓:

> **「生ログは勝手に貯まるが、編纂された知識は勝手に腐る」**

daily noteとクリップ（raw層）は自動化で毎日太るのに、顧客ページや索引（wiki層）は数週間で陳腐化した。v2はこの問題を「**夜間コンパイラ**」で解決する。

| | v1 | v2 |
|---|---|---|
| 構造 | SOUL/MEMORY/DREAMS + フォルダ群 | **4層モデル**（raw → wiki → digest → identity） |
| 玄関 | なし（CLAUDE.mdのみ） | **INDEX.md**（地図+鮮度ダッシュボード） |
| raw→知識の編纂 | 手動（すぐ止まる） | **夜間compile**が毎晩自動編纂（安価モデル） |
| 品質管理 | weekly-sync.sh（実際は未稼働） | **週次lint**（launchd登録済み・LLM不使用） |
| リサーチ | チャットで消える | **research/**（検証済み・出典・賞味期限付き） |
| 出典 | 任意 | **全主張に出典リンク必須**（レシート原則） |

## 4層アーキテクチャ

```
┌─ identity ────────────────────────────────────────────┐
│  SOUL.md / VOICE.md / RED-LINES.md                    │
│  価値観・文体・越えない線 — 人間だけが書く              │
└───────────────────────────────────────────────────────┘
┌─ digest ──────────────────────────────────────────────┐
│  MEMORY.md（直近の文脈） / DREAMS.md（パターン洞察）    │
│  クラウド認知パイプラインだけが書く（朝夕+週次）         │
└───────────────────────────────────────────────────────┘
                        ▲ 統合
┌─ wiki（編纂知識）──────────────────────────────────────┐
│  entities/ clients/ insights/ research/ decisions/    │
│  1ページ1実体・1教訓。全主張に出典リンク                │
│  ★ 夜間compileが毎晩ここを更新する                     │
└───────────────────────────────────────────────────────┘
                        ▲ 編纂（compile）
┌─ raw（生ログ・不可侵）─────────────────────────────────┐
│  daily/（日次ログ） clips/（ブックマーク） raw/（投込み）│
│  追記のみ。書き換え禁止 = ground truth                 │
└───────────────────────────────────────────────────────┘
```

**rawを不可侵にする理由**: 同じエージェントが同じノートを読み書きし続けると、ディテールが溶けて誤りが複利で増える。生ログを凍結しておけば、wiki層は何度でも作り直せる。

**所有権の分離が肝**: クラウドがraw+digestを書き、ローカルの夜間compileがwikiを書き、人間がidentityを書く。書き手が層ごとに一人なので、同期競合が構造的に起きない。

## 自動ループ — 脳を生かし続ける仕組み

覚えている時だけ餌をやる脳は3週間で死ぬ。だから全部スケジュールに載せる:

| ループ | いつ | 何を | コスト |
|-------|------|------|-------|
| セッションprimer | 毎セッション開始 | 今日の予定・直近の出来事・未解決ループをコンテキスト注入 | ゼロ（読むだけ） |
| セッション記録 | 毎セッション終了 | daily雛形保証 + git同期 | ゼロ |
| 朝夕の目 | 07:00 / 18:30 | Calendar/Slack/Gmail → daily note生成・更新 | クラウド |
| クリップ | 4時間おき | Xブックマーク → clips/ に要約保存 | 安価 |
| **夜間compile** | 23:30 | **rawを読み、entities/decisions/open-loops/INDEXを編纂** | **安価モデル（haiku）** |
| **週次lint** | 日曜 09:00 | 壊れリンク・重複・陳腐化・期限切れresearch検出 | ゼロ（シェルのみ） |
| 週次Dreaming | 日曜 21:30 | vault横断でパターン統合 → DREAMS.md | プレミアムモデル（週1のみ） |

> 💰 **コスト設計**: プレミアムモデルが登場するのは週1回の統合だけ。編纂はルーティンワークなので安価モデルに回す。「routine work, routine tier」。

### 夜間compile（brain-compile.sh）— v2の心臓

```
23:30 launchd発火
  │
  ├─ 1. 未コンパイル日を検出（最大3日分キャッチアップ）
  ├─ 2. claude -p をheadless起動（haiku・Read/Write/Edit/Glob/Grepのみ）
  │     「daily/{日付}.md と新規クリップを読み、
  │      登場した顧客・人物・ツールのページを更新せよ。
  │      全追記に出典 [[daily/{日付}]] を付けよ。
  │      rawとdigestには触るな」
  ├─ 3. 安全弁: raw/digest/identity層に変更があれば自動復元
  ├─ 4. git commit "compile: {日付}"
  └─ 5. push
```

LLMにgitを触らせない（スクリプトが握る）、書ける場所を層で制限する、変更は差分最小 — 暴走防止を仕組みで担保する。

### 週次lint（brain-lint.sh）— 腐敗検出

メンテされないwikiは必ず腐る。日曜朝、LLMなしの決定論チェックで検出:

- 壊れたwikilink（wiki層のみ）
- iCloud競合コピー（`ファイル名 2.md`）と byte-identical 重複
- 陳腐化（直近のdailyに登場するのに30日以上更新されていないエンティティ）
- 期限切れリサーチ（`expires:` 超過）
- daily欠落・ほぼ空のノート（自動化の停止検知）

結果は `system/lint-report.md` へ。クリティカルがあればOS通知。

## INDEX.md — 玄関とコンテキスト課金

コンテキストウィンドウは「入るもの全てに課金される高い部屋」。だから:

- **CLAUDE.mdは200行以下**を維持し、vaultを**指す**だけ（毎セッション読み込まれる常時課金ゾーン）
- 調べ物は **INDEX.md → リンクを辿る**。フルフォルダスキャンは絶対にしない
- 大きい質問は**subagentに読ませて結論だけ**受け取る（高い部屋には決定を、図書館は外に）

INDEX.mdには全セクションの地図と**鮮度ダッシュボード**（compileが毎晩更新）が載る。どの層がいつ更新されたか一目で分かり、腐敗が見える化される。

## research/ — 噂と検証済みを混ぜない

チャットで消えるリサーチを資産にする。リサーチスキルの流れ:

```
質問 → 3〜5のサブクエスチョンに分解
     → 並列エージェントが別々の面を調査（Web/公式/実践者の声）
     → 全発見をレシート化（主張+出典URL+日付）
     → ★スケプティックエージェントが全主張を攻撃
        ├─ 単一ソース → "single-source" に格下げ
        ├─ 矛盾 → 両論併記 or 棄却
        └─ 出典が辿れない → 棄却
     → 生存者だけが research/YYYY-MM-DD_topic.md に保存
        （frontmatterに expires: 賞味期限。lintが期限切れを検出）
```

検証を分離するのは、**新規コンテキストのチェッカーは自分の仕事をレビューするモデルより強い**から。

## Vault構造

```
~/vault/
├── INDEX.md        ← 玄関（地図+鮮度）★必ずここから
├── CLAUDE.md       ← スキーマ正本（200行以下・ポインタに徹する）
├── SOUL.md / VOICE.md / RED-LINES.md   ← identity層
├── MEMORY.md / DREAMS.md               ← digest層
├── open-loops.md   ← 未解決ループ（compileが更新）
│
├── daily/          ← raw: 日次ログ（朝夕自動生成）
├── clips/          ← raw: X・記事クリップ（x/ articles/）
├── raw/            ← raw: 手動ダンプ受け皿（文字起こし等）
│
├── entities/       ← wiki: 人物 people/ ツール tools/ 組織 orgs/
├── clients/        ← wiki: 顧客1社1ページ
├── insights/       ← wiki: 教訓・パターン（1ファイル1教訓）
├── research/       ← wiki: 検証済みリサーチ（expires付き）
├── decisions/      ← wiki: 意思決定ログ（月次）
│
├── memory/ system/ skills/ ← Claude Code内部のミラー（SYNCED）
├── templates/      ← entity / concept / research / daily-note / decision
└── scripts/        ← hooks・compile・lint・sync
```

## セットアップ

### 前提条件

- Claude Code（Pro or Max） / Obsidian（無料） / GitHubアカウント
- （オプション）Slack・Google Calendar・Gmail のConnector、常駐エージェント

### Step 1: Vault作成 + テンプレート展開

```bash
git clone https://github.com/chaenmasahiro0425/exbrain.git /tmp/exbrain
mkdir -p ~/vault && cp -r /tmp/exbrain/vault-template/* /tmp/exbrain/vault-template/.gitignore ~/vault/

# iCloud同期（iPhone対応する場合）
mv ~/vault ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/exbrain
ln -s ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/exbrain ~/vault
```

### Step 2: identity層を書く（ここだけは人間の仕事）

- `SOUL.md` — 自分は誰か、AIにどう振る舞ってほしいか
- `VOICE.md` — チャネル別の文体
- `RED-LINES.md` — どんな指示があっても越えない線

### Step 3: Hooks設定

`~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [
      { "type": "command", "command": "bash ~/vault/scripts/on-session-start.sh" }
    ]}],
    "Stop": [{ "hooks": [
      { "type": "command", "command": "bash ~/vault/scripts/on-session-end.sh", "async": true }
    ]}],
    "PostToolUse": [{ "matcher": "Write|Edit", "hooks": [
      { "type": "command", "command": "bash ~/vault/scripts/on-file-change.sh", "async": true }
    ]}]
  }
}
```

### Step 4: バックフィル — 持っているものを全部脳に入れる

過去のチャットログ・議事録・メモを `raw/` に放り込み、Claude Codeに:

```
~/vault/CLAUDE.md のルールに従い、raw/ の全ファイルを読んで
entities/ clients/ insights/ を編纂して。全主張に出典リンクを付けて。
```

数十ファイルあるなら並列subagent（またはWorkflow）で一撃。

### Step 5: ループを起動

```bash
# launchd登録（プレースホルダを自分のユーザー名に置換してから）
cp /tmp/exbrain/launchd/com.YOURNAME.brain-*.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.YOURNAME.brain-compile.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.YOURNAME.brain-lint.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.YOURNAME.brain-pull.plist
```

Cloud Scheduled Tasks（[claude.ai/code/scheduled](https://claude.ai/code/scheduled)）で朝夕のdaily note生成と週次Dreamingを登録すれば、PCを閉じても脳が動き続ける。

### Step 6: GitHubバックアップ

```bash
cd ~/vault
git init && git add -A && git commit -m "Initial brain"
gh repo create my-vault --private --source=. --push
```

## ⚠️ 同期の警告 — vaultはここで死ぬ

**同期システムは1系統に絞る**こと。エージェントがファイルを書いている最中にiCloudが同期すると、`ファイル名 2.md` 形式の競合コピーが量産される（v1の実運用で **395個** 発生した実話）。

- gitを「セーブポイント層」にする: コミットした時だけ確定
- iCloudを使う場合、週次lintが競合コピーを検出する（v2で対策済み）
- 検出された byte-identical 重複は安全に削除できる

## 含まれるスクリプト

| スクリプト | 用途 |
|-----------|------|
| `brain-compile.sh` | ★夜間コンパイラ: raw → wiki編纂（23:30） |
| `brain-lint.sh` | ★週次lint: 腐敗検出（日曜09:00） |
| `on-session-start.sh` | SessionStart hook: pull → healthcheck → primer注入 |
| `session-primer.sh` | 「脳の状態」をセッション冒頭にコンテキスト注入 |
| `on-session-end.sh` | Stop hook: daily雛形保証 + 同期 |
| `on-file-change.sh` | PostToolUse hook: 変更を監査ログに記録 |
| `vault-sync.sh` | git双方向同期（rebase・daily競合はクラウド優先） |
| `vault-healthcheck.sh` | セッション毎の健全性点検 + ダッシュボード |
| `sync-x-bookmarks.sh` | Xブックマーク取得（常駐エージェント用） |
| `sync-agent-to-vault.sh` | 外部エージェントのデータでdaily note充実化 |
| `ios-clip-shortcut.md` | iPhoneの共有メニューからワンタップクリップ |

全スクリプトmacOS互換（GNU拡張なし）。LLM実行部は権限を絞ったheadlessモード。

## 設計思想 — 参考文献

- [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 「ナレッジベースをコードベースのように扱う」原点
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) / [Cloud Scheduled Tasks](https://docs.anthropic.com/en/docs/claude-code/scheduled-tasks)
- raw/wiki分離・出典レシート・スケプティック検証・賞味期限は、2026年に実務コミュニティで収斂した第二の脳パターンの実装

## ライセンス

MIT — [LICENSE](LICENSE)
