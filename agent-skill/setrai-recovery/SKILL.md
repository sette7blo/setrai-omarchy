---
name: setrai-recovery
description: Show per-muscle recovery / readiness state from Setrai. Trigger on "recovery", "how am I recovering", "am I ready for push day", "what's fresh", "muscle readiness".
---

# Setrai — show muscle recovery and readiness

Fetch Setrai's per-muscle recovery model and present it so the user can decide
what to train today.

Endpoint: `GET $SETRAI_URL/api/recovery`
Config: `SETRAI_URL` from `~/.config/setrai-omarchy/config`, default `http://localhost:3000`.

## Response shape

```json
{ "recovery": { "groups": [ { "name": "chest", "readiness": 0.82, ... } ], ... } }
```

`readiness` is a `0..1` fraction. `1.0` means fully recovered. Thresholds this
skill uses:

- `>= 0.75` — ready to train hard
- `0.5–0.74` — light work only
- `< 0.5` — rest or active recovery

## When to invoke

- "recovery" / "how am I recovering"
- "am I ready for push day"
- "is my back fresh"
- "what should I avoid training today"

## Rendering

List muscle groups grouped by traffic-light, newest fatigue first:

```
🟢 ready       chest (0.88), triceps (0.82), hamstrings (0.79)
🟡 light       shoulders (0.61), quads (0.54)
🔴 recover     back (0.42), biceps (0.37)
```

If the user asked specifically ("am I ready for push day"), answer in one
sentence first, then list the implicated muscles:

```
Push day is borderline — shoulders and triceps still at 0.61 / 0.82. Light push
work is ok; skip heavy OHP.
```

## No mutations

This skill only reads. No confirmation needed.
