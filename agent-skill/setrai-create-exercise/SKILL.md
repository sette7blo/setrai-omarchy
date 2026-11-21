---
name: setrai-create-exercise
description: Add a new exercise to the Setrai library and give it a picture that matches the rest of the library, or make a matching picture for an exercise that has none. Trigger on "create an exercise", "add an exercise", "there is no exercise for", "make an image for this exercise", "the exercise has no picture".
---

# Setrai — create an exercise and its picture

Use this when the library has no exercise for what the user wants, or when an
exercise needs a picture. Every picture follows the style guide below, so the
library looks like one set.

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

## 1. Check it does not exist yet

`setrai-read '/api/exercises?search=<name>' --jq '[.exercises[] | {id, name, equipment}]'`.
Search two or three wordings (for example "calf", "heel raise"). If a match
exists, use it; do not create a near-duplicate.

## 2. Create the exercise

Show the user the draft first and create it only once they agree, unless they
pre-approved Setrai changes.

`setrai-write POST /api/exercises '<json>'` → `201 { exercise: { id, slug, ... } }`.

Fields (the server rejects values outside these lists):

- `name` (required), up to 120 characters.
- `movementType` (required): `compound` or `isolation`.
- `category`: `strength` or `bodyweight`.
- `muscleGroup`, the primary muscle: `chest`, `back`, `shoulders`, `biceps`,
  `triceps`, `core`, `quadriceps`, `hamstrings`, `glutes`, `calves`.
- `muscles`, secondary muscles: any of `chest`, `upper-chest`, `back`, `lats`,
  `upper-back`, `lower-back`, `traps`, `shoulders`, `anterior-deltoid`,
  `lateral-deltoid`, `posterior-deltoid`, `biceps`, `forearms`, `triceps`,
  `core`, `abs`, `obliques`, `quadriceps`, `hamstrings`, `glutes`, `abductors`,
  `adductors`, `calves`. List only muscles that do real work in the movement:
  recovery counts each one at half the load of the primary muscle, so an extra
  one makes Setrai think it needs rest. Leave the list empty for a
  single-muscle exercise (calf raise, crunch). Holding the weight is not a
  reason to add `forearms`: recovery counts forearms as biceps.
- `equipment`: any of `bodyweight`, `barbell`, `dumbbells`, `kettlebell`,
  `bench`, `cable-machine`, `machine`, `pull-up-bar`, `steel-mace`. Use only
  equipment the user has (`setrai-read /api/profile`).
- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `description`: one or two sentences.
- `instructions`: array of short steps, in order.
- `defaultSets` (1-50), `defaultReps` (text, such as `"10-15"`), `defaultRest`
  (seconds, 0-600).

Then go on to the picture.

## 3. Make the picture

This needs an image generation tool in your agent. If you have none, say so
and stop: do not draw a substitute (SVG, ASCII, a screenshot or a stock photo),
and do not attach any other image.

### Style guide

Every picture in the library looks like this. Keep all of it; change only the
athlete's pose and equipment.

- 4:3 landscape. One athlete, full body in frame, centred, head near the top
  and feet near the bottom. Nobody else.
- The athlete is drawn in grayscale ink with crosshatched shading and a thin
  bright orange outline around the whole body. Athletic build. The library has
  both men and women; either is fine.
- Black athletic wear (tank top or sports top, shorts or leggings), white
  socks, plain white trainers. No logos, brand marks or text anywhere.
- Equipment drawn the same way as the athlete: hexagonal black dumbbells,
  plain black kettlebells, plain benches.
- Background: diagonal dry-brush strokes in vivid orange, black and light gray
  running from bottom left to top right, with orange, black and white paint
  splatters.
- Floor: glossy black, reflecting the athlete and streaks of orange and white.
  The athlete's feet, knees or hands touch it exactly where the exercise needs.
- No text, numbers, watermark or border.

### Reference images

`references/` next to this file (resolve this skill's real location first)
holds four library pictures:

- `dumbbell-shrug.webp`: standing, front view, dumbbells at the sides.
- `dumbbell-lunges.webp`: standing in a stride, three-quarter side view.
- `plank.webp`: face down on the floor, side view.
- `crunches.webp`: lying on the back, side view.

Pass the **one** reference whose body position is closest to the new exercise.
References are copied closely, pose included, so a reference in a different
position pulls the picture away from the exercise.

### Prompt

Write the pose first, then the style:

1. The pose at the moment that shows the exercise best (the top of a raise,
   the bottom of a squat), described by body part: where each foot, knee,
   hand and the torso are, what touches the floor and what does not. Say what
   the reader must see ("a clear gap of air under both heels").
2. The camera angle that shows that moment: side view when the movement is
   front to back (calf raise, hinge, lunge, plank), front view when it is
   sideways (lateral raise, side bend).
3. Then the style guide above, in full.

Ask for 4:3. Name the file after the exercise slug.

### Check, then retry

Look at the result before using it. Crop or zoom in on the part that defines
the exercise (feet for a calf raise, hips for a hinge) and check it against the
pose you asked for, and check the style guide: no text or logos, one athlete,
orange outline, the floor reflection.

If the pose is wrong, say what is wrong and generate again with that part made
more explicit. If the reference keeps forcing its own pose, try once without a
reference and with the style guide written out in full. Stop after four
attempts in total and show the user the best one, saying what is off with it.

## 4. Attach it

Show the user the picture and attach it only once they agree, unless they
pre-approved Setrai changes:

`setrai-upload <exercise-id> <image-file>` → `200 { exercise: { ..., image_url } }`.

It replaces the exercise's current picture. It refuses SVG and files over
10 MB. `404` means the exercise id is wrong.

## Report

One short paragraph: the exercise's name and id, its main settings, and
whether the picture was attached. If it was not, say why.
