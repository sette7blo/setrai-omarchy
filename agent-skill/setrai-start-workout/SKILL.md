---
name: setrai-start-workout
description: Start a Setrai training session from one of the user's saved programs. Trigger on "start workout", "start today's workout", "start push day", "start my program", "begin training".
---

# Setrai — start a workout from a saved program

Setrai is a self-hosted training tracker running on this machine. Use this skill
when the user wants to **start a training session** from a program they already
have saved.

Connection: read `baseUrl` and `apiKey` from
`~/.local/state/omarchy/setrai/credentials.json` (written by the plugin's
Settings view). `SETRAI_URL` and `SETRAI_API_KEY` in the environment override
them; the address defaults to `http://localhost:3000`. Send
`Authorization: Bearer <apiKey>` on every request.

## When to invoke

- "start a push workout" / "start leg day" / "start my upper body program"
- "start today's workout"
- "begin a session from program X"

## Steps

1. **List saved programs** to find the one the user asked for.
   `GET <baseUrl>/api/programs` → `{ programs: [{ id, name, exercises, ... }] }`
   Match on `name` (case-insensitive substring is fine). If multiple match,
   ask the user to disambiguate.
2. **Start a session** against that program.
   `POST <baseUrl>/api/sessions` with body `{ "programId": <id> }`
   Server response: `201 { session: { id, programName, plannedExercises, ... } }`.
3. **Confirm to the user**: name of the program, number of planned exercises,
   and the resume URL (`/sessions/<id>`). Offer to open the browser via
   `setrai open /sessions/<id>`.

## Error handling

- `404 Program not found` → the ID you resolved is stale; re-list.
- Connection refused → Setrai is not running; tell the user, do not retry.

## Mutations (ALWAYS confirm before writing)

Starting a session mutates state. Before POSTing, state what you'll do and
wait for an explicit "yes" / "go" from the user.

## Example

```
User: start my push workout
You:  Found program "Push A" (6 exercises). Start it now? [confirm]
User: yes
You:  [POST /api/sessions { programId: 12 }]
      Session started: /sessions/341. Open in browser?
```
