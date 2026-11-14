---
name: setrai-create-program
description: Design a training program with the user and save it to Setrai as a reusable program. Trigger on "create a program", "build me a routine", "make a push day", "design a 4-day split", "new workout plan".
---

# Setrai — create a training program

Use this when the user wants a **new saved program**: a named list of
exercises with sets, reps and rest that they can start again and again. For a
one-off session for today, use `setrai-quick-workout` instead.

Connection: read `baseUrl` and `apiKey` from
`~/.local/state/omarchy/setrai/credentials.json` (written by the plugin's
Settings view). `SETRAI_URL` and `SETRAI_API_KEY` in the environment override
them; the address defaults to `http://localhost:3000`. Send
`Authorization: Bearer <apiKey>` on every request.

A Setrai program is **one workout**. A weekly split is several programs
("Upper A", "Lower A", ...): create one per training day.

## Steps

1. **Understand the request.** If the user did not say, ask for what you need
   and no more: the goal, how many days a week, how long a session, and any
   exercise or body part to avoid. `GET <baseUrl>/api/profile` gives
   `trainingGoal` (`strength`, `hypertrophy`, `general-fitness`, `endurance`)
   and `equipment`; use them as defaults instead of asking.
2. **Load the exercise library.** `GET <baseUrl>/api/exercises` →
   `{ exercises: [{ id, slug, name, muscle_group, muscles, equipment,
   movement_type, difficulty, default_sets, default_reps, default_rest }] }`.
   `?search=<text>` narrows it by name. Only use exercises from this list, and
   only ones whose `equipment` the user has. Never invent an exercise; if the
   library lacks something, say so and pick the closest one it does have.
3. **Check what they already have.** `GET <baseUrl>/api/programs` → avoid a
   duplicate name, and point out an existing program that already covers it.
4. **Draft the program** and show it in full before saving:

   ```
   Upper A (6 exercises, about 55 min)
     1. Bench Press            4 x 6-8     rest 150 s
     2. Bent Over Row          4 x 6-8     rest 150 s
     ...
   Save this to Setrai?
   ```
5. **Save on an explicit yes.** `POST <baseUrl>/api/programs`:

   ```json
   {
     "name": "Upper A",
     "description": "Horizontal push and pull, then arms.",
     "difficulty": "intermediate",
     "tags": ["strength", "upper"],
     "exercises": [
       { "exerciseSlug": "bench-press", "sets": 4, "reps": "6-8", "restSeconds": 150 },
       { "exerciseId": 174, "sets": 3, "reps": "8-12", "restSeconds": 90, "notes": "Slow lowering" }
     ]
   }
   ```

   Response: `201 { program: { id, name, exercises, ... } }`.
6. **Confirm**: the saved name and id, and offer to start it with
   `setrai start <id>`.

## Request fields

- `name`: required, at most 300 characters.
- `description`: optional text. `difficulty`: optional short text; the
  library uses `beginner`, `intermediate`, `advanced`. `tags`: optional array
  of strings.
- `exercises`: array, at most 100, in workout order. Each entry needs
  `exerciseSlug` or `exerciseId` from the library, and may set:
  - `sets`: integer 1 to 100. Default 3.
  - `reps`: a **string**, such as `"8-12"`, `"5"` or `"30 s"`. Default `"8-12"`.
  - `restSeconds`: integer 0 to 3600. Default 90.
  - `targetWeight`: number in kg, or leave it out. When it is left out, a
    session started from the program suggests the weight last used.
  - `notes`: optional text.

Leave out `isTemporary`, `slug`, `blocks` and the `seed*` fields; they are for
Setrai's own use.

## Changing a program

`PATCH <baseUrl>/api/programs/<id>` takes the same fields. Sending `exercises`
replaces the whole list, so send every exercise, not only the changed ones.
Confirm before patching. Do not delete programs unless the user asks for that
program to be deleted.

## Error handling

- `400 Program contains an invalid exercise reference` → a slug or id is not
  in the library; re-read the list.
- `400 Sets must be between 1 and 100`, `Rest must be between 0 and 3600
  seconds`, `Reps are required (maximum 40 characters)` → fix the entry; `reps`
  sent as a number is the usual cause.
- Connection refused → Setrai is not running; tell the user, do not retry.

## Mutations (ALWAYS confirm before writing)

Show the complete program and wait for an explicit "yes" before any POST or
PATCH. For a multi-day split, show every day first and save them together
after one confirmation.
