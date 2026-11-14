---
name: setrai-recovery
description: Show per-muscle recovery / readiness state from Setrai. Trigger on "recovery", "how am I recovering", "am I ready for push day", "what's fresh", "muscle readiness".
---

# Setrai — show muscle recovery and readiness

Fetch Setrai's per-muscle recovery model and present it so the user can decide
what to train today.

Endpoint: `GET <baseUrl>/api/recovery`
Connection: read `baseUrl` and `apiKey` from
`~/.local/state/omarchy/setrai/credentials.json` (written by the plugin's
Settings view). `SETRAI_URL` and `SETRAI_API_KEY` in the environment override
them; the address defaults to `http://localhost:3000`. Send
`Authorization: Bearer <apiKey>` on every request.

## Response shape

```json
{
  "recovery": {
    "generatedAt": "2026-11-13T09:00:00.000Z",
    "lookbackDays": 7,
    "readiness": 86,
    "muscles": [
      { "muscle": "chest", "recovery": 0.82, "status": "...", "lastTrainedAt": "..." }
    ]
  }
}
```

- `readiness` is the overall figure as a whole percentage (0-100).
- Each muscle's `recovery` is a `0..1` fraction; `1` means fully recovered.
  Muscles not trained in the lookback window are not listed and count as
  fully recovered.

Thresholds this skill uses for a muscle:

- `>= 0.75` ready to train hard
- `0.5-0.74` light work only
- `< 0.5` rest or active recovery

## When to invoke

- "recovery" / "how am I recovering"
- "am I ready for push day"
- "is my back fresh"
- "what should I avoid training today"

## Rendering

Lead with the overall readiness, then group muscles by threshold, most
fatigued first:

```
Readiness 86%
  ready     chest (88%), triceps (82%), hamstrings (79%)
  light     shoulders (61%), quads (54%)
  recover   back (42%), biceps (37%)
```

If the user asked specifically ("am I ready for push day"), answer in one
sentence first, then list the implicated muscles:

```
Push day is borderline: shoulders at 61%, triceps at 82%. Light push
work is ok; skip heavy OHP.
```

## No mutations

This skill only reads. No confirmation needed.
