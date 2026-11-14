---
name: setrai-show-stats
description: Pull the user's Setrai training statistics overview — recent volume, streak, records, body weight trend. Trigger on "show stats", "how was last week", "my training overview", "training summary".
---

# Setrai — show training statistics

Fetch and present Setrai's overview dashboard as plain text.

Endpoint: `GET <baseUrl>/api/statistics`
Connection: read `baseUrl` and `apiKey` from
`~/.local/state/omarchy/setrai/credentials.json` (written by the plugin's
Settings view). `SETRAI_URL` and `SETRAI_API_KEY` in the environment override
them; the address defaults to `http://localhost:3000`. Send
`Authorization: Bearer <apiKey>` on every request.

## Response shape

```json
{
  "statistics": {
    "trainingFrequency": { "totalSessions": 84, "thisWeek": 2 },
    "totalVolume": 512340,
    "weeklyVolume": [ { "weekStart": "2026-11-09", "volume": 15200 } ],
    "volumeByExercise": [ ... ],
    "volumeByMuscle": [ ... ],
    "personalRecords": [
      { "exerciseName": "Bench press", "recordWeight": 100, "recordReps": 5,
        "estimated1RM": 116.7, "achievedAt": "...", "improvement": 2.5 }
    ],
    "trainingStreak": {
      "currentStreakDays": 2, "longestStreakDays": 5,
      "currentStreakWeeks": 6, "longestStreakWeeks": 11
    },
    "bodyWeight": [ { "date": "2026-11-10", "weightKg": 72.1 } ],
    "bodyWeightChangeKg": -1.4
  }
}
```

- Volumes are in kg (weight x reps over completed sets).
- `weeklyVolume` is oldest first, keyed by the Monday (UTC) of each week.
  Weeks without training are left out, so a missing week means 0.
- `bodyWeight` is oldest first. `bodyWeightChangeKg` is latest minus first
  entry, or `null` when there are no entries.

Report the server's figures as they are; don't recompute them.

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
  w-0   15.2t

Streak: 6 weeks
Body weight: 72.1 kg (-1.4 kg total)
Recent PRs:
  Bench press    100 kg × 5
  Front squat    85 kg × 3
```

If the user asked a narrow question ("how was last week?"), answer that
specifically — don't dump the whole payload.

## No mutations

This skill only reads. No confirmation needed.
