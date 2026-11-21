---
name: setrai-start-workout
description: Start a Setrai training session from one of the user's saved programs. Trigger on "start workout", "start today's workout", "start push day", "start my program", "begin training".
---

# Setrai — start a workout from a saved program

Setrai is a self-hosted training tracker running on this machine. Use this skill
when the user wants to **start a training session** from a program they already
have saved.

Connection: reach Setrai only through the plugin's two commands, never with
curl and never by reading its credentials file. `setrai-read /api/<path>` sends
a GET (add `--jq '<filter>'` to keep only the fields you need from a large
answer, instead of processing the output with python or another program); `setrai-write <METHOD> /api/<path> '<json body>'` sends a POST, PUT,
PATCH or DELETE with the body as one argument (not piped in). Both print the
JSON response and use the server and key saved in the plugin's Settings. The
coach prompt gives their full paths: call them by those paths. Outside the
coach they are in the plugin's `bin` folder, two folders above this skill's
real location.

## When to invoke

- "start a push workout" / "start leg day" / "start my upper body program"
- "start today's workout"
- "begin a session from program X"

## Steps

1. **List saved programs** to find the one the user asked for.
   `setrai-read /api/programs` → `{ programs: [{ id, name, exercises, ... }] }`
   Match on `name` (case-insensitive substring is fine). If multiple match,
   ask the user to disambiguate.
2. **Start a session** against that program.
   `setrai-write POST /api/sessions` with body `{ "programId": <id> }`
   Server response: `201 { session: { id, programName, plannedExercises, ... } }`.
3. **Confirm to the user**: name of the program, number of planned exercises,
   and the resume URL (`/sessions/<id>`). Offer to open it via
   `setrai open /sessions/<id>`, which opens Setrai in its own window.

Before step 2, check `setrai-read /api/sessions` for a session whose
`finishedAt` is `null`. Setrai does not stop a second session from starting,
so if one is open, tell the user and offer to resume it instead.

Shortcut: once the user has confirmed a program, `setrai start <id>` does the
open-session check, starts the session and opens the window in one step.

## Error handling

- `404 Program not found` → the ID you resolved is stale; re-list.
- Connection refused → Setrai is not running; tell the user, do not retry.

## Mutations (ALWAYS confirm before writing)

Starting a session mutates state. Before POSTing, state what you'll do and
wait for an explicit "yes" / "go" from the user.
If the coach prompt says Setrai changes are pre-approved, a change the user
asked for in plain words needs no extra confirmation: make it, then say what
changed.

## Example

```
User: start my push workout
You:  Found program "Push A" (6 exercises). Start it now? [confirm]
User: yes
You:  [POST /api/sessions { programId: 12 }]
      Session started: /sessions/341. Open in browser?
```
