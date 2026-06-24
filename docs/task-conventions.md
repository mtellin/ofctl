# Task Conventions

This document captures the conventions `ofctl` is designed to support.

## Source Of Truth

OmniFocus is the execution source of truth. Markdown notes can still hold
project support notes, meeting notes, and migration history, but active tasks
should live in OmniFocus.

When migrating a Markdown task note:

- Create the OmniFocus task.
- Preserve useful note content.
- Add a source reference in the OmniFocus note.
- Mark the Markdown task note complete.
- Add `completed-date`.
- Add `omnifocus-id`.
- Set the Markdown task note `project` field if the note belongs to a project.

## Tags

Use context tags for tools, locations, and action modes:

- `@computer`
- `@phone`
- `@home-inside`
- `@home-outside`
- `@errand`

Use person-name tags for people:

- `Alex Rivera`
- `Priya Shah`
- `Jordan Lee`

Avoid person tags like `@alex` unless the whole tag system changes. The existing
`@...` convention is for contexts, not people.

Use status/domain tags where helpful:

- `Waiting On`
- `Work 💼`

Prefer tag paths when calling `ofctl` so tags are created or resolved under the
intended parent:

```sh
ofctl add "Ask Alex for project status" \
  --tag "People/Alex Rivera" \
  --tag "Status/Work 💼"
```

When a plain person-looking tag such as `Alex Rivera` is missing, `ofctl`
creates it under `People` if that tag exists. When `Status/Work 💼` exists,
plain `Work` resolves to that tag instead of creating a root-level `Work` tag.

## Waiting On

Recommended waiting-on shape:

```text
Task + Waiting On tag + person tag + real project/location
```

Example:

```sh
ofctl add "Ask Alex for project status" \
  --project "Work Follow-ups" \
  --tag "People/Alex Rivera" \
  --tag "Waiting On" \
  --tag "Status/Work 💼"
```

OmniFocus does not have a task-level "On Hold" status. The common OmniFocus/GTD
pattern is to mark the `Waiting On` tag itself as On Hold, then review waiting
items through a perspective that shows Remaining items rather than only
Available items.

This prevents waiting items from cluttering normal available-action views while
keeping them visible in a Waiting On review or person agenda.

## Dates

Use dates intentionally:

- `defer`: task is unavailable before this date/time.
- `planned`: intended time to work on the task.
- `due`: real external deadline or consequence.

Do not use due dates as casual reminders.

Use planned dates for daily planning:

```sh
ofctl update TASK_ID --planned "2026-05-19T09:00:00"
```

Use defer dates when the task should not show up yet:

```sh
ofctl update TASK_ID --defer "2026-05-22"
```

Use due dates only for real deadlines:

```sh
ofctl update TASK_ID --due "2026-05-30"
```

Use recurrence for work that should create a next occurrence after completion.
Store recurrence as an auditable ICS RRULE string:

```sh
ofctl add "Water plants" --due "2026-05-22" --repeat-rule "FREQ=WEEKLY;INTERVAL=1" --repeat-method due
```

Use `--repeat-method fixed` for a regular fixed schedule that should not drift
when completed late. Use `--repeat-method due` for "due again after completion"
and `--repeat-method defer` for "defer again after completion."

## Duration

Use estimated minutes for planning:

```sh
ofctl add "Review project tracker" --duration 30
```

Clear duration:

```sh
ofctl update TASK_ID --duration none
```

## Projects

Projects belong inside a folder (Home, Personal, Work, or Routines). When
`ofctl add --project NAME` creates a new project it lands at the library top
level unless you pass `--folder FOLDER_PATH`. Prefer passing `--folder` up front
when the destination folder is known, including nested paths like
`Work/Planning`.

Use the real OmniFocus project when one exists.

For people reminders that are not tied to a specific project, use:

```text
Work Follow-ups
```

For Markdown task-note migration, if a note clearly belongs to a project, set its
frontmatter `project` field before or during cleanup.

## Action Groups

Use an action group when a single outcome naturally breaks into a small set of
child actions that should stay together.

Good action group candidates:

- A checklist that belongs to one project outcome.
- A sequence where later actions are blocked by earlier actions.
- A small batch of related actions that should be reviewed as one unit.

Prefer a normal task instead when the item is a single next action, even if the
note contains context or acceptance criteria.

Sequential groups:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --sequential
```

Parallel groups:

```sh
ofctl add-group "Prep demo environment" \
  --project "Product Launch" \
  --parallel
```

Add children by parent task ID:

```sh
ofctl add "Send launch note" --parent ACTION_GROUP_TASK_ID
ofctl add "Post release checklist" --parent ACTION_GROUP_TASK_ID
```

Use `--complete-with-children` only when completing every child should complete
the group automatically. Leave it off when the parent needs a final review or
wrap-up step.

## Notes And Markdown

Callers should send Markdown. `ofctl` converts supported Markdown to OmniFocus
rich text on write and converts rich notes back to Markdown on read.

Supported mappings:

- `**bold**`
- `*italic*`
- `` `inline code` ``
- `#`, `##`, and `###` headings
- OmniFocus bullet text normalized to Markdown-style list markers on read

Markdown links are preserved losslessly as readable text in the form
`title (url)`. OmniFocus may auto-link supported plain URLs, but `ofctl` does
not force custom URL schemes such as `obsidian://` into rich-text links because
OmniFocus rejects some schemes during automation.

Prefer `--note-file` for multiline notes:

```sh
ofctl add "Ask Taylor about launch date" --note-file /tmp/of-note.md
```

Include source context when migrating:

```text
Source: Markdown task note - tasks/Ask Alex for project status.md
```

## Note State Block

Automated tooling may persist a small key/value metadata block at the end of a
task or project note, delimited by a `=== ofctl-state ===` sentinel line. This
keeps structured state (for example prioritization signals such as slip history,
a priority tier, and why-it-matters context) in OmniFocus itself so it syncs
across machines rather than living in a local file.

Manage the block with `task-state` / `project-state` (see the user guide) — do
not hand-edit it through `--note`, which replaces the whole note. The freeform
note content above the sentinel is preserved across state writes.

The keys below are an example convention used by one consumer; the block itself
is general-purpose and accepts any `key: value` pairs.

```text
From: Circuit Daily Sync on 6/20/2026

=== ofctl-state ===
priority: P1
priority-source: auto
slip-count: 3
last-planned: 2026-06-23
why: committed in sync; blocks the ADR
```

Conventions for the block:

- `priority`: `P1` | `P2` | `P3` — persistent relative importance, distinct from
  the native flag ("do this first today") and from any per-run scheduling tier.
- `priority-source`: `auto` | `manual` — `manual` means a human set the tier and
  it should not be auto-recomputed.
- `slip-count`: integer; how many times the task was planned but not completed.
- `last-planned` / `last-slip-date`: ISO dates used to compute carryover and to
  keep slip increments idempotent (only increment once per slip day).
- `why`: short free text on why the item matters. Values may contain colons.

Projects use the same block with `last-reviewed` in place of the planning dates.
