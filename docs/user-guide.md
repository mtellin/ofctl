# User Guide

This guide covers the `ofctl` command-line interface.

## Running ofctl

From the repository:

```sh
swift run ofctl help
```

From the release build:

```sh
.build/release/ofctl help
```

For examples below, `ofctl` means either the release executable or `swift run
ofctl` from the repository.

## Query Tasks

Basic query:

```sh
ofctl tasks
```

Query by person or context tag:

```sh
ofctl tasks --tag "Alex Rivera"
ofctl tasks --tag "@computer"
```

Text output:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Text output includes task name, project or inbox location, tags, defer date,
planned date, and due date.

## Availability And Date Filters

Use `--available` when you want tasks that are available by effective defer
date. Tasks with no defer date count as available.

```sh
ofctl tasks --available now
```

Use `--planned` for OmniFocus planned dates:

```sh
ofctl tasks --planned today
ofctl tasks --planned now
ofctl tasks --planned before:now
ofctl tasks --planned on:2026-05-19
```

Use `--deferred` for the task's own defer date:

```sh
ofctl tasks --deferred none
ofctl tasks --deferred before:now
ofctl tasks --deferred after:today
```

Use `--due` for effective due dates:

```sh
ofctl tasks --due today
ofctl tasks --due before:2026-05-25
ofctl tasks --due none
```

Supported filter values:

- `now`
- `today`
- `tomorrow`
- `yesterday`
- `none`
- `before:DATE`
- `after:DATE`
- `on:YYYY-MM-DD`

For `before:` and `after:`, `DATE` can be `now`, `today`, `tomorrow`,
`yesterday`, `YYYY-MM-DD`, or an ISO-like date/time.

Examples:

```sh
ofctl tasks --planned before:now
ofctl tasks --available now --tag "@computer"
ofctl tasks --tag "Alex Rivera" --due none
```

## Limits

Task queries return up to 100 tasks by default:

```sh
ofctl tasks --available now
```

Set a different limit:

```sh
ofctl tasks --available now --limit 25
```

Export every match:

```sh
ofctl tasks --available now --all
```

Use `--all` carefully. Broad queries can be slow against large OmniFocus
databases.

## Notes

Task queries omit notes by default for speed.

Include notes:

```sh
ofctl tasks --tag "Alex Rivera" --include-notes
```

JSON output then includes:

- `note`: Markdown converted from OmniFocus rich text
- `notePlain`: plain OmniFocus note text

Without `--include-notes`, those fields are omitted.

## JSON Output

Default output is JSON. Task objects include:

- `id`
- `name`
- `project`
- `inInbox`
- `tags`
- `deferDate`
- `plannedDate`
- `dueDate`
- `effectiveDeferDate`
- `effectivePlannedDate`
- `effectiveDueDate`
- `estimatedMinutes`
- `flagged`
- `completed`
- `dropped`
- `path`

Response metadata includes:

- `total`: total matches
- `count`: returned task count
- `limit`: active limit, or `null` for `--all`
- `truncated`: whether there are more matches than returned

Inspect structure with `jq`:

```sh
ofctl tasks --available now --limit 10 | jq '.tasks[] | {name, project, inInbox, path}'
```

## Add Tasks

Create a task:

```sh
ofctl add "Ask Taylor about launch date"
```

Add to a project:

```sh
ofctl add "Ask Taylor about launch date" --project "Work Follow-ups"
```

Add tags:

```sh
ofctl add "Ask Alex for project status" \
  --tag "Alex Rivera" \
  --tag "Waiting On" \
  --tag "Work"
```

Set dates and duration:

```sh
ofctl add "Draft launch follow-up" \
  --planned "2026-05-19T09:00:00" \
  --defer "2026-05-19" \
  --due "2026-05-22" \
  --duration 30
```

Dry-run a write:

```sh
ofctl add "Ask Taylor about launch date" --tag "Taylor Morgan" --dry-run
```

## Notes On Add

Inline Markdown note:

```sh
ofctl add "Ask Taylor about launch date" \
  --note "Discuss **launch risk** and [brief](https://example.com)."
```

Multiline Markdown note:

```sh
ofctl add "Ask Taylor about launch date" --note-file /tmp/of-note.md
```

Markdown is converted to OmniFocus rich text where supported.

## Update Tasks

Use the task `id` returned by `tasks` or `add`.

Update dates and duration:

```sh
ofctl update TASK_ID \
  --planned "2026-05-19T09:00:00" \
  --duration 30
```

Clear fields:

```sh
ofctl update TASK_ID --planned none --duration none
```

Move to another project:

```sh
ofctl update TASK_ID --project "Work Follow-ups"
```

Add tags:

```sh
ofctl update TASK_ID --tag "Alex Rivera" --tag "Waiting On"
```

Clear existing tags before adding new ones:

```sh
ofctl update TASK_ID --clear-tags --tag "Alex Rivera"
```

Update notes:

```sh
ofctl update TASK_ID --note-file /tmp/of-note.md
```

Dry-run:

```sh
ofctl update TASK_ID --planned none --dry-run
```

## Common Queries

Person agenda:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Available computer work:

```sh
ofctl tasks --available now --tag "@computer" --limit 25 --format text
```

Planned work up to this moment:

```sh
ofctl tasks --planned now --format text
```

Tasks planned later today:

```sh
ofctl tasks --planned after:now --format text
```

Tasks with no planned date:

```sh
ofctl tasks --planned none --limit 25 --format text
```

Tasks with defer dates that have arrived:

```sh
ofctl tasks --deferred before:now --format text
```

Waiting-on items for a person:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Then inspect the returned tags for `Waiting On`.

Note: repeated `--tag` filters are currently parsed but only the last tag is
used by the query engine. Until multi-tag matching is implemented, query one tag
at a time and inspect tags in the JSON/text output.
