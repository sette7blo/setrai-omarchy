---
name: setrai-log-body
description: Log a body-weight measurement in Setrai for a specific date (defaults to today). Trigger on "log my weight", "I weighed X", "log 72kg", "record body weight".
---

# Setrai — log body weight

Use this when the user wants to **record a body-weight measurement**.

Endpoint: `POST $SETRAI_URL/api/body-weight`
Config: `SETRAI_URL` from `~/.config/setrai-omarchy/config`, default `http://localhost:3000`.

## Request shape

```json
{ "weightKg": 72.4, "date": "2026-11-10" }
```

- `weightKg` — number, kilograms. If user gives pounds, convert (lb × 0.45359237).
- `date` — `YYYY-MM-DD` string. Default to **today in the local timezone** if
  omitted.

## Response

`201 { entry: { id, date, weightKg } }`.

## When to invoke

- "log my body weight"
- "I weighed 72.4 today"
- "72 kg" / "158 lb" said in a body-weight context
- "log yesterday's weight as 73"

## Confirmation (required)

Body-weight entries show up in the user's progress chart. Confirm before
writing:

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

- `400 Invalid body-weight date` → date was not `YYYY-MM-DD` or in the future.
- `400 Invalid body-weight` → weight was zero/negative/non-numeric.
