---
name: setrai-log-body
description: Log a body-weight measurement in Setrai for a specific date (defaults to today). Trigger on "log my weight", "I weighed X", "log 72kg", "record body weight".
---

# Setrai — log body weight

Use this when the user wants to **record a body-weight measurement**.

Endpoint: `setrai-write POST /api/body-weight`
Connection: reach Setrai only through the plugin's two commands, never with
curl and never by reading its credentials file. `setrai-read /api/<path>` sends
a GET; `setrai-write <METHOD> /api/<path> '<json body>'` sends a POST, PUT,
PATCH or DELETE with the body as one argument (not piped in). Both print the
JSON response and use the server and key saved in the plugin's Settings. The
coach prompt gives their full paths: call them by those paths. Outside the
coach they are in the plugin's `bin` folder, two folders above this skill's
real location.

## Request shape

```json
{ "weightKg": 72.4, "date": "2026-11-10" }
```

- `weightKg` — number, kilograms. If user gives pounds, convert (lb × 0.45359237).
- `date` — `YYYY-MM-DD` string. Default to **today in the local timezone** if
  omitted.

## Response

`201 { entry: { id, date, weightKg } }`. An entry that already exists for that
date is replaced.

## When to invoke

- "log my body weight"
- "I weighed 72.4 today"
- "72 kg" / "158 lb" said in a body-weight context
- "log yesterday's weight as 73"

## Confirmation (required)

Body-weight entries show up in the user's progress chart. Confirm before
writing. If the coach prompt says Setrai changes are pre-approved, a change the user
asked for in plain words needs no extra confirmation: make it, then say what
changed.
Otherwise:

```
User: log 72.4 today
You:  Log 72.4 kg for 2026-11-10? [confirm]
User: yes
You:  [POST /api/body-weight { weightKg: 72.4, date: "2026-11-10" }]
      Logged. Latest trend: ...
```

## Unit conversions

- lb → kg: multiply by `0.45359237`, round to one decimal.
- stone → kg: multiply by `6.35029318`.

Always show the final `kg` value in the confirmation so the user catches
conversion mistakes before they're written.

## Error handling

- `400 Invalid body-weight date` → date was not a real `YYYY-MM-DD` date. The
  server accepts future dates, so check the date yourself before sending.
- `400 Weight must be numeric` / `Weight must be greater than zero` → fix the
  value and ask again.
