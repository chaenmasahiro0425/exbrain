# Obsidian Vault Schema

> このファイルはLLMがvaultを読み書きする際のルール定義。

## ファイル区分

| 区分 | 場所 | 編集権限 | ヘッダー |
|------|------|---------|---------|
| SYNCED | system/, skills/, memory/ | 自動同期のみ。手動編集禁止 | `<!-- SYNCED: DO NOT EDIT -->` |
| editable | daily/, meetings/, clients/, decisions/, insights/ | Claude + 人間が自由に編集 | なし |

## 書き込みルール

1. **frontmatter必須** — 全ページに YAML frontmatter を付ける
2. **日本語** — 本文は日本語。タグ・フォルダ名は英語kebab-case
3. **日付フォーマット** — YYYY-MM-DD（ISO 8601）
4. **SYNCEDファイルの冒頭** — `<!-- SYNCED: DO NOT EDIT -->` を1行目に

## リンク規約

- 内部リンク: `[[フォルダ/ファイル名]]` 形式
- 外部ソース: frontmatterの `source:` フィールドにパス記載
- 双方向リンク推奨

## 命名規則

| コンテンツ | パターン | 例 |
|-----------|---------|-----|
| デイリーノート | `YYYY-MM-DD.md` | `2026-04-07.md` |
| 議事録 | `YYYY-MM-DD_<顧客>_<種別>.md` | `2026-04-07_naoru_定例.md` |
| 判断ログ | `YYYY-MM_<テーマ>.md` | `2026-04_料金改定.md` |
| 顧客 | `<kebab-case>.md` | `naoru.md` |
