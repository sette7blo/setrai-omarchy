---
name: setrai-show-stats
description: Pull the user's Setrai training statistics overview — recent volume, streak, records, body weight trend. Trigger on "show stats", "how was last week", "my training overview", "training summary".
---

# Setrai — show training statistics

Fetch and present Setrai's overview dashboard as plain text.

Endpoint: `GET $SETRAI_URL/api/statistics`
Config: `SETRAI_URL` from `~/.config/setrai-omarchy/config`, default `http://localhost:3000`.

## Response shape

```json
{
  "statistics": {
    "volume": { ... weekly/monthly series ... },
    "records": [ ... 1RM, volume PRs ... ],
    "streak": { ... training streak info ... },
    "bodyWeight": { ... trend ... }
  }
}
```

The exact fields are stable across releases; read whatever the response
contains and render the subset the user asked for. Do not assume fields beyond
`volume`, `records`, `streak`, `bodyWeight` without checking.

## When to invoke

- "show my stats"
- "how was last week"
- "weekly / monthly volume"
- "training summary"
- "what are my records"

## Rendering

Keep output compact and scannable. Prefer a terse table over prose:

```
Volume (last 4 weeks)
  w-3   12.4t
  w-2   14.1t
  w-1   13.8t
  w-0   15.2t   ↑

Streak: 6 weeks (last: 2026-11-08)
Latest body weight: 72.1 kg (−0.4 from 4w ago)
Recent PRs:
  Bench press    100 kg × 5
  Front squat    85 kg × 3
```

If the user asked a narrow question ("how was last week?"), answer that
specifically — don't dump the whole payload.

## No mutations

This skill only reads. No confirmation needed.
