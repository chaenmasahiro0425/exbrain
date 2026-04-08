---
date: 2026-04-08
type: index
---

# Clips by Tag

> タグ別クリップ分類。Dataview対応。

```dataview
TABLE rows.date, rows.source, rows.author
FROM "clips"
WHERE type = "clip"
FLATTEN tags as tag
GROUP BY tag
SORT rows.date DESC
```
