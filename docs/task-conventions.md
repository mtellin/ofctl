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
- `Work`

## Waiting On

Recommended waiting-on shape:

```text
Task + Waiting On tag + person tag + real project/location
```

Example:

```sh
ofctl add "Ask Alex for project status" \
  --project "Work Follow-ups" \
  --tag "Alex Rivera" \
  --tag "Waiting On" \
  --tag "Work"
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

Use the real OmniFocus project when one exists.

For people reminders that are not tied to a specific project, use:

```text
Work Follow-ups
```

For Markdown task-note migration, if a note clearly belongs to a project, set its
frontmatter `project` field before or during cleanup.

## Notes And Markdown

Callers should send Markdown. `ofctl` converts supported Markdown to OmniFocus
rich text on write and converts rich notes back to Markdown on read.

Supported mappings:

- `[title](url)` links
- `**bold**`
- `*italic*`
- `` `inline code` ``
- `#`, `##`, and `###` headings
- OmniFocus bullet text normalized to Markdown-style list markers on read

Prefer `--note-file` for multiline notes:

```sh
ofctl add "Ask Taylor about launch date" --note-file /tmp/of-note.md
```

Include source context when migrating:

```text
Source: Markdown task note - tasks/Ask Alex for project status.md
```
