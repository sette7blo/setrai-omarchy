---
name: setrai-quick-workout
description: Generate a Setrai "quick workout" that respects muscle recovery, then optionally start it as a live session. Trigger on "quick workout", "generate a workout", "give me something to do today", "I have 30 minutes".
---

# Setrai — generate + start a quick workout

Two-step: **generate** a workout plan from the user's constraints, then
**start** it as a live session if they want to do it right now.

Connection: read `baseUrl` and `apiKey` from
`~/.local/state/omarchy/setrai/credentials.json` (written by the plugin's
Settings view). `SETRAI_URL` and `SETRAI_API_KEY` in the environment override
them; the address defaults to `http://localhost:3000`. Send
`Authorization: Bearer <apiKey>` on every request.

## Step 1 — Generate

`POST <baseUrl>/api/quick-workout` with a body describing constraints. The
server validates and fills in reasonable defaults; pass through whatever the
user said. Common fields:

```json
{
  "durationMin": 30,
  "focus": "push" | "pull" | "legs" | "upper" | "full",
  "equipment": ["barbell", "dumbbell", "bodyweight"]
}
```

Response: `200 { workout: { name, exercises: [...] } }`.

Present the generated plan to the user **before** starting it:

```
Generated a 30-minute push workout:
  1. Bench press        4 × 6
  2. Overhead press     3 × 8
  3. Incline DB press   3 × 10
  ...
Start it now?
```

## Step 2 — Start (only on confirm)

`POST <baseUrl>/api/quick-workout/start` with the same `workout` object the
previous call returned. Response: `201 { session: { id, ... } }`.

Then surface the live-session URL (`/sessions/<id>`) and offer to open the
browser via `setrai open /sessions/<id>`.

## Confirmation (required for Step 2)

Starting a session mutates state. Never POST to `/start` without an explicit
"yes".

## Error handling

- Generator rejects constraints as unsatisfiable → relay the error and let the
  user relax a constraint (e.g. longer duration, broader focus).
- Connection refused → Setrai is not running; stop.
