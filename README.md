<p align="center">
  <img src="assets/banner.png" alt="Exbrain Banner" width="800">
</p>

<h1 align="center">Exbrain — Your AI's External Brain</h1>

<p align="center">
  <b>An AI knowledge system that automatically remembers, organizes, and reflects.</b><br>
  Claude Code × Obsidian × SOUL/MEMORY/DREAMS<br><br>
  <a href="README_JP.md">🇯🇵 日本語版はこちら</a> · Inspired by <a href="https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f">Karpathy's LLM Wiki</a>
</p>

## What is Exbrain?

Exbrain turns Claude Code's hidden internal state — Memory files, CLAUDE.md configs, Skills — into a human-readable Obsidian vault. It adds a **Dreaming** layer that automatically reflects on your day, detects patterns, and builds a growth trajectory over time.

Your laptop can be closed. Your phone shows everything. You just open Obsidian and read.

## How It Works — For Beginners

If you're new to Claude Code or Obsidian, here's the big picture:

```
┌──────────────────────────────────────────────────────────────┐
│                    YOU (Human)                                │
│                                                              │
│   Work with Claude Code    Bookmark on X    Send URL in Slack│
│         ↓                      ↓                  ↓          │
└─────────┬──────────────────────┬──────────────────┬──────────┘
          │                      │                  │
          ▼                      ▼                  ▼
┌─────────────────┐  ┌───────────────────┐  ┌──────────────────┐
│  Claude Code    │  │  Cron Job (Auto)  │  │  Always-On Agent │
│  (Local CLI)    │  │  Every 4 hours    │  │  (e.g. OpenClaw) │
│                 │  │                   │  │                  │
│ • /clip skill   │  │ • X bookmark sync │  │ • Slack listener │
│ • Hooks (auto)  │  │ • xurl API        │  │ • URL detection  │
│ • Session logs  │  │                   │  │ • firecrawl      │
└────────┬────────┘  └────────┬──────────┘  └────────┬─────────┘
         │                    │                      │
         └────────────────────┼──────────────────────┘
                              │
                              ▼
                 ┌──────────────────────┐
                 │   ~/vault/ (Git)     │
                 │                      │
                 │  SOUL.md   MEMORY.md │
                 │  DREAMS.md           │
                 │  daily/  clips/      │
                 │  clients/ insights/  │
                 └──────────┬───────────┘
                            │
                   ┌────────┼────────┐
                   │        │        │
                   ▼        ▼        ▼
                GitHub   iCloud   Obsidian
                (backup) (sync)   (Mac+iPhone)
```

### Components Explained

| Component | What it is | Role in Exbrain |
|-----------|-----------|-----------------|
| **Claude Code** | Anthropic's AI coding CLI ([docs](https://docs.anthropic.com/en/docs/claude-code)) | Your main AI assistant. Runs skills like `/clip`, writes to vault, manages hooks |
| **Obsidian** | Free markdown note app ([obsidian.md](https://obsidian.md)) | Where you **read** everything. Vault = folder of .md files. Works on Mac, iPhone, Android |
| **Always-On Agent** | A background AI (e.g. [OpenClaw](https://openclaw.com)) | Monitors Slack/Discord 24/7. Runs cron jobs even when Claude Code is closed |
| **Cloud Scheduled Tasks** | Claude Code's built-in scheduler ([docs](https://docs.anthropic.com/en/docs/claude-code/scheduled-tasks)) | Runs morning/evening Dreaming without your PC. Updates MEMORY.md and DREAMS.md |
| **xurl** | X API CLI tool | Fetches tweets and bookmarks from X (Twitter) |
| **Firecrawl** | Web scraping CLI | Converts any URL into clean markdown |
| **iCloud** | Apple's cloud sync | Syncs vault between Mac and iPhone automatically |
| **GitHub** | Code hosting | Backup + version history for your vault |

### Data Flow: What Happens When You Clip

```
You find an interesting article
         │
         ▼
  ┌─ Pick your method ──────────────────────────────────┐
  │                                                      │
  │  A) /clip URL          B) Slack DM         C) Just  │
  │     in Claude Code        send URL         bookmark │
  │         │                    │              on X     │
  │         ▼                    ▼                │      │
  │    Claude Code          Agent detects    (wait 4h)   │
  │    runs instantly       URL in real-time      │      │
  └──────┬───────────────────┬───────────────────┬──────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                             ▼
                   ┌─────────────────┐
                   │  AI Processing  │
                   │                 │
                   │ 1. Fetch content│
                   │ 2. Summarize    │
                   │ 3. Tag (auto)   │
                   │ 4. Save .md     │
                   └────────┬────────┘
                            │
                            ▼
               vault/clips/x/2026-04-08_slug.md
                            │
                  ┌─────────┼─────────┐
                  │         │         │
                  ▼         ▼         ▼
            _index.md   daily note   git push
            updated     updated      to GitHub
                                        │
                                        ▼
                                   iCloud sync
                                        │
                                        ▼
                                 📱 Read on iPhone
```

### System Relationship Map

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ┌──────────────┐         ┌──────────────┐              │
│  │ Claude Code  │────────▶│  ~/vault/    │◀──────┐      │
│  │ (CLI agent)  │ writes  │ (Obsidian)   │       │      │
│  │              │         │              │  writes│      │
│  │ Skills:      │         │ SOUL.md      │       │      │
│  │  /clip       │         │ MEMORY.md    │  ┌────┴────┐ │
│  │  /auto-min   │         │ DREAMS.md    │  │ Cloud   │ │
│  │  30+ more    │         │ daily/       │  │Schedule │ │
│  └──────────────┘         │ clips/       │  │ Tasks   │ │
│                           │ clients/     │  │         │ │
│  ┌──────────────┐         │ meetings/    │  │ Morning │ │
│  │ Always-On    │────────▶│ insights/    │  │ Evening │ │
│  │ Agent        │ writes  │              │  └─────────┘ │
│  │ (OpenClaw)   │         └──────┬───────┘              │
│  │              │                │                      │
│  │ Cron jobs:   │          git push/pull                │
│  │  X bookmarks │                │                      │
│  │  Slack DM    │         ┌──────▼───────┐              │
│  │  Reports     │         │   GitHub     │              │
│  └──────────────┘         │  (private)   │              │
│                           └──────────────┘              │
│                                                         │
│          ─── All connected via ~/vault/ ───             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## The SOUL / MEMORY / DREAMS Trinity

The core of Exbrain is three files at the root of your vault:

```
~/vault/
├── SOUL.md      ← WHO you are (identity, values, boundaries)
├── MEMORY.md    ← WHAT you've experienced (decisions, patterns, lessons)
└── DREAMS.md    ← WHERE you're going (insights, growth, open questions)
```

### SOUL.md — Identity

Defines who you are and how the AI should behave. Merged from Claude Code's CLAUDE.md and any external agent personality configs.

```markdown
## Identity
- Your name, role, company

## Values
- "Ship fast, iterate later"
- "API-first, no manual work"

## Boundaries (non-negotiable)
- "Never send emails — drafts only"
- "Never post to Slack without confirmation"

## Tech Ecosystem
- APIs, MCP servers, CLI tools
```

### MEMORY.md — Experience

A digest of everything the AI has learned. Auto-synced from Claude Code's Memory (`.claude/projects/*/memory/`) + enriched by Cloud Scheduled Tasks.

```markdown
## Recent
- [2026-04-07] Built Obsidian vault with SOUL/MEMORY/DREAMS
- [2026-04-06] Shipped new feature for Project Alpha

## Decisions
- Hybrid design: static mirror + Karpathy pattern + Dreaming

## Patterns
- Fridays are meeting-heavy (3 weeks in a row)
- Email replies concentrate in the afternoon

## CC Memory Summary (35 files)
- feedback/21: "Never send emails", "Always git commit after GAS edits"
- reference/7: API locations, tool configs
- project/4: Active project statuses
- user/1: User profile and preferences
```

### DREAMS.md — Reflection

Updated automatically by Dreaming (morning + evening + weekly). Tracks patterns that emerge over time.

```markdown
## Current Insights
- Meeting density peaks on Mondays (10+ meetings, 3 consecutive weeks)

## Emerging Patterns
| Pattern | Count | Trend |
|---------|-------|-------|
| Tool → Skill → Automation cycle | 10+ | Consistent |
| Email/Slack send caution | 5+ | Critical boundary |

## Growth Trajectory
- Q1: Built 26 skills, automated 32 cron jobs

## Open Questions
- Should CC Memory duplicates be consolidated?
```

## Clips — Knowledge Clipping

Clips automatically captures tweets and articles into your vault. Like Karpathy's compounding knowledge pattern, everything you read accumulates and becomes searchable in Obsidian.

### Three Ways to Clip

| Method | Trigger | Best for |
|--------|---------|----------|
| **`/clip` skill** | `/clip <URL>` in Claude Code | Working at your desk, high-quality summaries |
| **Slack DM** | Post URL in Slack DM to your agent | On the go (phone), instant capture |
| **X Bookmark Sync** | Automatic every 4 hours | Passive — just bookmark on X, it syncs |

### 1. `/clip` — Manual Clip in Claude Code

```
/clip https://x.com/karpathy/status/1234567890
/clip https://example.com/great-article
/clip https://url1.com https://url2.com          # multiple URLs
```

Detects X tweet vs article automatically. Fetches content, generates summary + tags in Japanese, saves to `clips/`, updates daily note, and pushes to git.

### 2. Slack DM — Clip from Your Phone

Just send a URL to your agent's Slack DM:

```
https://example.com/interesting-article
```

The agent detects the URL, scrapes the content, generates a summary, saves to `clips/`, and replies in a thread:

```
📎 Clipped!
📄 How LLMs Will Change Everything
🏷️ #ai #llm #future
📁 vault/clips/articles/2026-04-08_llm-change-everything.md
```

**Setup**: Requires an always-on agent (like [OpenClaw](https://openclaw.com)) with Slack Socket Mode. Add the URL detection behavior to your agent's auto-actions. See [Slack Clip Setup](#slack-clip-setup) below.

### 3. X Bookmark Auto-Sync

Bookmark tweets on X as you normally would. A cron job syncs them to your vault automatically.

**Default schedule**: Every 4 hours (8:00, 12:00, 16:00, 20:00)

**Requirements**: [xurl](https://github.com/twitterdev/xurl) CLI with OAuth2 authentication.

```bash
# Test manually
xurl bookmarks -n 5 --auth oauth2
```

### Clip File Format

```markdown
---
date: 2026-04-08
type: clip
source: x | article
url: https://...
author: "@username"
tags: [ai, claude-code, agent]
via: slack | cli | cron          # how it was clipped
---

## Summary
(3-5 line summary in your language)

## Key Points
- Point 1
- Point 2

## Notes
> Important quotes

## Related
[[insights/...]] | [[clips/...]]
```

### Daily Note Integration

Each clip is automatically linked in the day's daily note:

```markdown
## Clips
- [[clips/x/2026-04-08_sam-altman-social-contract]] — Sam Altman's social contract
- [[clips/articles/2026-04-08_karpathy-llm-wiki]] — Karpathy LLM Wiki pattern
```

### Dataview Queries

Browse clips by tag in Obsidian:

```dataview
TABLE rows.date, rows.source, rows.author
FROM "clips"
WHERE type = "clip"
FLATTEN tags as tag
GROUP BY tag
SORT rows.date DESC
```

### Slack Clip Setup

To enable Slack DM → clip, add this auto-action to your agent:

1. **Create skill files** in your agent's workspace:

```
workspace/skills/slack-clip/
├── SKILL.md          ← Skill overview
├── BEHAVIOR.md       ← Detection rules + processing flow
└── processed-clips.json  ← Deduplication tracking
```

2. **Add auto-action** to your agent's config (e.g., `AGENTS.md`):

```markdown
### URL投稿 → Vaultクリップ
DM にURLを含むメッセージが来たら自動でvault/clips/に保存。

検知方法:
- メッセージテキストに https:// を含む（転送メッセージは除外）
- Slack内部URL、画像直リンクは除外

処理:
1. URL種別判定（X tweet vs 記事）
2. X tweet → xurl read / 記事 → firecrawl scrape
3. 要約・タグ生成 → vault/clips/ に保存
4. git push + スレッド返信で確認
```

3. **Ensure tools are available** to the agent:
   - `xurl` (X API CLI) with OAuth2 auth
   - `firecrawl` (web scraping CLI)
   - Git access to your vault repo

### X Bookmark Cron Setup

Add a cron job to your agent scheduler:

```json
{
  "name": "clip-x-bookmarks",
  "schedule": "0 8-23/4 * * *",
  "message": "Fetch X bookmarks with `xurl bookmarks -n 20 --auth oauth2`, check for duplicates in vault/clips/x/, summarize new ones, save to vault/clips/x/, update _index.md, git push."
}
```

## Architecture

```
┌─ Layer 1: Cloud Scheduled Tasks (no PC needed) ────────────┐
│                                                              │
│  07:00  vault-daily-morning                                  │
│  ├── Read SOUL.md (understand user context)                  │
│  ├── Read MEMORY.md (recent decisions & patterns)            │
│  ├── Google Calendar → today's schedule                      │
│  ├── Slack → overnight highlights                            │
│  ├── Gmail → important unread emails                         │
│  ├── Morning Dreaming (yesterday's review → today's focus)   │
│  ├── Update MEMORY.md Recent section                         │
│  └── git push                                                │
│                                                              │
│  18:30  vault-daily-evening                                  │
│  ├── Read SOUL.md + MEMORY.md + DREAMS.md                    │
│  ├── Evening Dreaming (today + 7-day pattern detection)      │
│  ├── Update MEMORY.md + DREAMS.md                            │
│  ├── Sunday: weekly Dreaming + Lint + Slack notification      │
│  └── git push                                                │
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │ push
                       ▼
┌─ GitHub (private repo) ──────────────────────────────────────┐
│  All vault files                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │ pull (hourly via launchd)
                       ▼
┌─ Layer 2: Local Automation ──────────────────────────────────┐
│                                                               │
│  Claude Code Hooks (async: true)                              │
│  ├── PostToolUse → log file changes                           │
│  └── Stop → append session end to daily note + MEMORY.md      │
│                                                               │
│  External Agent Cron (when PC is on)                          │
│  ├── Additional data: Salesforce, Stripe, HERP, YouTube       │
│  └── Skipped when PC is off (Layer 1 is self-sufficient)      │
│                                                               │
└──────────────────────┬───────────────────────────────────────┘
                       │ iCloud sync
                       ▼
              Obsidian (Mac + iPhone)
```

## Vault Structure

```
~/vault/
├── SOUL.md                ← Identity, values, boundaries
├── MEMORY.md              ← Experience digest (CC Memory mirror)
├── DREAMS.md              ← Dreaming accumulation (auto-updated)
├── CLAUDE.md              ← Schema (LLM rules for this vault)
│
├── daily/                 ← Daily notes (auto-generated morning & evening)
│   └── 2026-04-07.md         Schedule / Gmail / Slack / AI Analysis /
│                              Morning Reflection / Evening Reflection /
│                              Claude Code Session / Thoughts
│
├── system/                ← Claude Code system mirror (SYNCED)
│   ├── claude-md-tree.md     All CLAUDE.md files as a tree
│   ├── global-rules.md       Rules & boundaries summary
│   ├── api-inventory.md      API list (no keys)
│   ├── tech-stack.md         Technology stack
│   └── cron-jobs.md          Running cron jobs
│
├── skills/                ← All skills with details (SYNCED)
├── memory/                ← CC Memory individual file mirror (SYNCED)
│   ├── feedback/             Behavioral guidelines
│   ├── reference/            External system pointers
│   ├── project/              Project statuses
│   └── user/                 User profile
│
├── clips/                 ← Clipped tweets & articles (auto + manual)
│   ├── x/                    X bookmarks (auto-synced daily at 22:00)
│   ├── articles/             Web articles (via /clip or Slack)
│   ├── _index.md             Clip index (auto-updated)
│   └── tags.md               Tag-based classification (Dataview)
│
├── clients/               ← Client knowledge (Karpathy pattern)
├── meetings/              ← Meeting summaries (auto from /auto-minutes)
├── decisions/             ← Decision log
├── insights/              ← Learnings + weekly Dreaming
├── templates/             ← daily-note, meeting, decision
└── scripts/               ← Hook scripts + sync scripts
```

## Hybrid Design: Three Personalities

```
vault/
├── system/, skills/, memory/
│   → Static mirror (dashboard)
│   → Auto-synced from Claude Code, read-only
│   → <!-- SYNCED: DO NOT EDIT --> header
│
├── daily/
│   → Auto log + handwritten diary
│   → Calendar + Slack + Gmail + AI Analysis + Dreaming
│   → Runs even with PC closed (Cloud Scheduled Tasks)
│
└── meetings/, clients/, insights/
    → Karpathy pattern (compounding knowledge)
    → Each meeting processed → client page auto-enriched
    → No need to re-read 12 meeting transcripts
```

## Setup

### Prerequisites
- Claude Code (Pro or Max)
- Obsidian (free)
- GitHub account
- (Optional) Slack / Google Calendar / Gmail Connectors

### Step 1: Create Vault

```bash
mkdir -p ~/vault/{daily,system,skills,memory/{feedback,reference,project,user},clients,meetings,decisions,insights,templates,scripts}

# iCloud sync (for iPhone)
mv ~/vault ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/exbrain
ln -s ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/exbrain ~/vault
```

### Step 2: Copy Templates

```bash
git clone https://github.com/YOUR_USERNAME/exbrain.git /tmp/exbrain
cp -r /tmp/exbrain/vault-template/* ~/vault/
```

### Step 3: Configure Hooks

Add to `~/.claude/settings.json`:

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

### Step 4: Initial Sync

In Claude Code:
```
Please read all my skills from ~/.claude/skills/, all memory files from
~/.claude/projects/*/memory/, and sync them to ~/vault/. Create SOUL.md
with my identity and MEMORY.md with a digest of all memories.
```

### Step 5: GitHub Backup

```bash
cd ~/vault
git init && git add -A && git commit -m "Initial vault"
gh repo create my-vault --private --source=. --push
```

### Step 6: Cloud Scheduled Tasks (PC-free automation)

At [claude.ai/code/scheduled](https://claude.ai/code/scheduled):
- **vault-daily-morning** (07:00): Read SOUL.md → Calendar + Slack + Gmail → daily note + Morning Dreaming
- **vault-daily-evening** (18:30): Read SOUL.md + MEMORY.md + DREAMS.md → Evening Dreaming + pattern detection

## Daily Note Example

```markdown
---
date: 2026-04-07
weekday: Monday
type: daily
score: 74
---

## Schedule
| Time | Event | Note |
|------|-------|------|
| 09:00 | Management meeting | |
| 10:00 | Sales standup | |
| 14:00 | Company standup | |

## Gmail
| From | Subject | Action |
|------|---------|--------|
| [Contact] | Project meeting request | Reply needed |

## Slack Highlights
- **#general**: Organization restructuring discussion
- **#sales**: New lead from inbound campaign
- **#daily-report**: Project Beta milestone reached

## Morning Reflection
- Yesterday's decision: Revised product roadmap
- Today's focus: Follow up on pending proposals

## Evening Reflection
- Highlight: Project Beta milestone reached
- Pattern: Mondays consistently have 10+ meetings (3 weeks)
- Unresolved: Partner meeting follow-up

## Thoughts
<!-- Write your own reflection here -->
```

## Scripts Included

| Script | Purpose |
|--------|---------|
| `on-session-end.sh` | Stop hook: appends session summary to daily note + MEMORY.md |
| `on-file-change.sh` | PostToolUse hook: logs CLAUDE.md/memory/skill changes |
| `weekly-sync.sh` | Weekly lint: broken links, orphan pages, stale content |
| `git-pull-sync.sh` | Hourly git pull with stash handling |
| `sync-agent-to-vault.sh` | Enriches daily notes from external agent JSON data |
| `sync-x-bookmarks.sh` | Auto-fetches X bookmarks + clips (cron 22:00) |

All scripts are macOS-compatible (no GNU extensions), reviewed for security (no shell injection, PID-based locking instead of flock).

## References

- [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — The original pattern
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — async hook documentation
- [Cloud Scheduled Tasks](https://docs.anthropic.com/en/docs/claude-code/scheduled-tasks) — PC-free automation
- [QMD](https://github.com/tobi/qmd) — Markdown semantic search (for 100+ pages)

## License

MIT
