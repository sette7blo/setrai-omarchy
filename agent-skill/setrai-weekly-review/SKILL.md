---
name: setrai-weekly-review
description: Review the user's training week from Setrai data and suggest what to adjust. Trigger on "weekly review", "how did my week go", "review my training", "what should I change", "coach me", "am I progressing".
---

# Setrai — weekly training review

Use this when the user wants a **coach's read of their recent training**: what
they did, how it compares with earlier weeks, and what to do next. It only
reads; it never changes anything in Setrai.

Connection: reach Setrai only through the plugin's two commands, never with
curl and never by reading its credentials file. `setrai-read /api/<path>` sends
a GET (add `--jq '<filter>'` to keep only the fields you need from a large
answer, instead of processing the output with python or another program); `setrai-write <METHOD> /api/<path> '<json body>'` sends a POST, PUT,
PATCH or DELETE with the body as one argument (not piped in). Both print the
JSON response and use the server and key saved in the plugin's Settings. The
coach prompt gives their full paths: call them by those paths. Outside the
coach they are in the plugin's `bin` folder, two folders above this skill's
real location.

## Data to read

1. `setrai-read /api/statistics` → `{ statistics: { trainingFrequency,
   weeklyVolume, volumeByMuscle, volumeByExercise, personalRecords,
   trainingStreak, bodyWeight, bodyWeightChangeKg } }`. See
   `setrai-show-stats` for the fields.
2. `setrai-read /api/recovery` → per-muscle recovery and the overall
   `readiness`. See `setrai-recovery` for the fields.
3. `setrai-read /api/sessions` → `{ sessions: [{ id, programName, startedAt,
   finishedAt, ... }] }`, newest first. The list does **not** include the
   logged sets. Skip sessions whose `finishedAt` is `null`; they are still in
   progress.
4. For each session finished in the week under review:
   `setrai-read /api/sessions/<id>` → `{ session: { programName, startedAt,
   finishedAt, plannedExercises, sets: [{ exerciseName, setNumber, reps,
   weight, done }] } }`. `weight` is in kg and is `null` for bodyweight sets.
5. `setrai-read /api/profile` → `trainingGoal`, `weightUnit` and
   `targetWeightKg`, so the advice fits the goal.

"The week" is the current Monday-to-Sunday week by default. If it has no
finished session yet, review the previous week and say so.

## What to report

Keep it short: a few lines per heading, numbers first.

- **What was trained**: sessions with day and program, and for each the main
  lifts with the best set (`weight x reps`).
- **Volume**: this week's entry in `weeklyVolume` against the previous two or
  three. A week missing from the list had no training.
- **Balance**: which muscles the week's sets covered and which they skipped.
  Group the sets you read by exercise; `volumeByMuscle` is all-time, so use it
  only for the long-run picture.
- **Progress**: entries in `personalRecords` whose `achievedAt` falls in the
  week, with `improvement`. For repeated lifts, compare the best set with the
  previous session that has the same exercise.
- **Planned against done**: exercises in `plannedExercises` with no completed
  set.
- **Body weight**: latest entry and `bodyWeightChangeKg`, against
  `targetWeightKg` when one is set.
- **Next week**: two or three concrete changes, each tied to something above
  (for example a skipped muscle group, a lift that stalled for three sessions,
  or volume that jumped more than about a fifth in one week).

## Rules

- Use the server's figures for anything it provides (weekly volume, records,
  readiness, body-weight change). Do not recompute them.
- Write weights in the profile's `weightUnit`. The API always returns kg;
  1 kg = 2.2046226218 lb.
- Say when there is too little data to judge. Fewer than about three weeks of
  sessions is not a trend.
- Do not give medical advice. Pain or injury is a reason to see a
  professional, not to adjust the program.
- Offer follow-ups rather than doing them: `setrai-create-program` to change
  the plan, `setrai-quick-workout` for a session today.

## Error handling

- `401` → the API key was rejected; ask the user to paste a new one in the
  plugin's settings.
- Connection refused → Setrai is not running; tell the user, do not retry.
