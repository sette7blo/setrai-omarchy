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

`POST <baseUrl>/api/quick-workout` with a JSON body describing constraints.
Every field is optional; `{}` is valid.

```json
{
  "durationMinutes": 30,
  "goal": "hypertrophy",
  "targetMuscles": ["chest", "triceps"],
  "equipment": ["barbell", "bench", "dumbbells"]
}
```

- `durationMinutes`: integer from 15 to 90. Defaults to 30. The plan has one
  exercise per 9 minutes.
- `goal`: `strength`, `hypertrophy`, `general-fitness` or `endurance`. Defaults
  to the training goal in the user's profile. It sets the sets, reps and rest.
- `targetMuscles`: array of `chest`, `back`, `shoulders`, `biceps`, `triceps`,
  `core`, `quadriceps`, `hamstrings`, `glutes`, `calves`. Leave it out to let
  the server pick the most recovered muscles.
- `equipment`: array of `bodyweight`, `barbell`, `dumbbells`, `kettlebell`,
  `bench`, `cable-machine`, `machine`, `pull-up-bar`, `steel-mace`. Defaults to
  the equipment in the user's profile; only send it when the user names what
  they have today.

The server ignores fields it does not know, so a misspelled name silently
gives a default workout. Map what the user says onto these fields: "push" is
`["chest", "shoulders", "triceps"]`, "pull" is `["back", "biceps"]`, "legs" is
`["quadriceps", "hamstrings", "glutes", "calves"]`.

Response: `200 { workout: { name, durationMinutes, estimatedDurationMinutes,
goal, targetMuscles, exercises: [{ exerciseName, muscleGroup, sets, reps,
restSec, ... }] } }`. Check that `durationMinutes`, `goal` and `targetMuscles`
in the response match what you sent.

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

`POST <baseUrl>/api/quick-workout/start` with `{ "workout": <the workout
object from step 1> }`. Response: `201 { workout, program, session: { id, ... } }`.

Then surface the live-session URL (`/sessions/<id>`) and offer to open the
browser via `setrai open /sessions/<id>`.

## Confirmation (required for Step 2)

Starting a session mutates state. Never POST to `/start` without an explicit
"yes".

## Error handling

- `400` with a message such as `Duration must be between 15 and 90 minutes` or
  `Invalid quick-workout goal` → relay it and let the user adjust.
- Connection refused → Setrai is not running; stop.
