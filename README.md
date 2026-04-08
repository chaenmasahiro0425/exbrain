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

All scripts are macOS-compatible (no GNU extensions), reviewed for security (no shell injection, PID-based locking instead of flock).

## References

- [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — The original pattern
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — async hook documentation
- [Cloud Scheduled Tasks](https://docs.anthropic.com/en/docs/claude-code/scheduled-tasks) — PC-free automation
- [QMD](https://github.com/tobi/qmd) — Markdown semantic search (for 100+ pages)

## License

MIT
