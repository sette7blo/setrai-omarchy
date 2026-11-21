---
name: setrai-quick-workout
description: Generate a Setrai "quick workout" that respects muscle recovery, then optionally start it as a live session. Trigger on "quick workout", "generate a workout", "give me something to do today", "I have 30 minutes".
---

# Setrai — generate + start a quick workout

Two-step: **generate** a workout plan from the user's constraints, then
**start** it as a live session if they want to do it right now.

Connection: reach Setrai only through the plugin's three commands, never with
curl and never by reading its credentials file. `setrai-read /api/<path>` sends
a GET (add `--jq '<filter>'` to keep only the fields you need from a large
answer, instead of processing the output with python or another program);
`setrai-upload <exercise-id> <image-file>` attaches a JPEG, PNG, WebP or GIF to
an exercise; `setrai-write <METHOD> /api/<path> '<json body>'` sends a POST, PUT,
PATCH or DELETE with the body as one argument (not piped in). All three print the
JSON response and use the server and key saved in the plugin's Settings. The
coach prompt gives their full paths: call them by those paths. Outside the
coach they are in the plugin's `bin` folder, two folders above this skill's
real location.

## Step 1 — Generate

`setrai-write POST /api/quick-workout` with a JSON body describing constraints.
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

`setrai-write POST /api/quick-workout/start` with `{ "workout": <the workout
object from step 1> }`. Response: `201 { workout, program, session: { id, ... } }`.

Then surface the live-session URL (`/sessions/<id>`) and offer to open the
browser via `setrai open /sessions/<id>`.

## Confirmation (required for Step 2)

Starting a session mutates state. Never POST to `/start` without an explicit
"yes", unless the user asked for this workout to be started.
If the coach prompt says Setrai changes are pre-approved, a change the user
asked for in plain words needs no extra confirmation: make it, then say what
changed.

## Error handling

- `400` with a message such as `Duration must be between 15 and 90 minutes` or
  `Invalid quick-workout goal` → relay it and let the user adjust.
- Connection refused → Setrai is not running; stop.
