#!/usr/bin/env bash
# on-session-start.sh — Claude Code SessionStart hook（新規 2026-06-14）
# 役割:
#   1) クラウドの最新を取り込む（--pull-only / FDAコンテキストなので TCC を踏まない）
#   2) 健全性チェック（切断・競合・未push を検知。RED時はOS通知＋安全自動修復）
#   3) 「脳の状態」primer を stdout に出力 → Claude が文脈注入（分身化の核）
# 呼び出し元: ~/.claude/settings.json → hooks.SessionStart
set +e
VAULT="$HOME/vault"

bash "$VAULT/scripts/vault-sync.sh" --pull-only >/dev/null 2>&1
bash "$VAULT/scripts/vault-healthcheck.sh" >/dev/null 2>&1
bash "$VAULT/scripts/session-primer.sh" 2>/dev/null
exit 0
