# The modification benchmark

The claim this measures: **ask an AI to change your desktop, and the change
works** — how often, for a bar written in Almide against the same bar written
in QML (Quickshell, what Omarchy's shell layer is made of).

## Setup

- `baseline/almide/` and `baseline/qml/shell.qml` — the same bar in both
  languages: Hyprland workspaces (click to switch), a clock, the volume, the
  battery; same theme, same layout. Frozen here so the benchmark does not move
  with the shell. The Almide one is built against the snaidhm checkout next to
  this repository.
- `tasks/NN-name/prompt.md` — a change, worded as a user asks for it ("Move
  the bar to the bottom of the screen", "Clicking the volume should mute or
  unmute the sound"). 30 of them: layout, colour, text and format, new
  modules from system state, and new interactions.
- `tasks/NN-name/check.sh` — whether the change is there, judged only from
  outside the bar, so one check judges both languages: the compositor's
  geometry of the bar's surface, the screen's pixels, the text read off them
  (OCR), and the state the bar drives (the volume, the focused workspace)
  after a real click or wheel turn through a virtual pointer. Helpers:
  `lib.sh`.
- `tasks/NN-name/ref/{almide,qml}/` — a correct change in each language.
  `run.py --verify-refs` holds every check to failing on the baseline and
  passing on the reference, in both languages; a check that does not
  discriminate does not measure its task.

## A run

For each task, language and trial: the model gets the bar's complete source
and the request, and returns the files it changes (no tools, no project
files, no settings: `claude -p --safe-mode --setting-sources project --tools
""`). The Almide prompt carries the language reference, `docs/CHEATSHEET.md`
— what Almide ships for models to read; QML, which models already know, gets
none. The result is built and started in a fresh Hyprland session in Docker
(`verify.sh`, on vkms at scale 2), the task's check runs, and the bar must
still be alive afterwards. If any of that fails, the model gets one retry
with what went wrong (the build errors, the bar's output, or the check's
verdict).

- **works on the first try** — the headline: builds, starts, does what was
  asked, keeps running.
- works after one retry.
- first try builds and runs — the change did not break the bar, whether or not
  it did what was asked.

```
bench/run.py --verify-refs                     # the checks, first
bench/run.py --model claude-sonnet-5 --trials 3
```

Results go to `results/DATE/MODEL/`: `summary.md`, `results.jsonl`, and per
attempt the model's reply and the verification log.

The Docker host needs vkms (see `test/hyprland/run.sh`); `BENCH_CONTEXT`
names the Docker context (default `colima-bench`, a VM of its own so the
benchmark and `try.sh` do not share the one virtual display).
