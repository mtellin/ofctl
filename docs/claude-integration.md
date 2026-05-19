# Claude Integration

`ofctl` is intended to let Claude Code work with OmniFocus without installing an
MCP server.

## Integration Model

Claude should call `ofctl` as a local executable:

```sh
.build/release/ofctl tasks --tag "Alex Rivera"
```

The command surface is intentionally narrow:

- `tasks` for read workflows
- `add` for task creation
- `update` for controlled edits

This is easier to review and approve than general-purpose AppleScript or a full
OmniFocus MCP server.

## Preferred Claude Workflow

For meeting prep and agendas:

1. Identify the person or meeting tag.
2. Query OmniFocus by person tag.
3. Use returned task names, dates, project, tags, and notes if requested.
4. Insert concise agenda bullets into the meeting note.
5. Do not mark tasks complete unless explicitly asked.

Example:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

For richer context:

```sh
ofctl tasks --tag "Alex Rivera" --include-notes
```

For migration from Markdown task notes:

1. Read the Markdown task note.
2. Create the OmniFocus task with `--dry-run`.
3. Review the payload.
4. Create the task.
5. Update the Markdown task note with `completed-date` and `omnifocus-id`.

Dry-run example:

```sh
ofctl add "Ask Alex for project status" \
  --project "Work Follow-ups" \
  --tag "Alex Rivera" \
  --tag "Waiting On" \
  --tag "Work" \
  --note-file /tmp/of-note.md \
  --dry-run
```

## Safety Guidelines For Claude

Prefer read-only commands unless the user asks for a write.

Use `--dry-run` before creating or updating tasks when:

- The task name is subjective.
- The target project is ambiguous.
- Dates could be interpreted more than one way.
- The operation touches multiple tasks.

Use `--limit` on broad queries:

```sh
ofctl tasks --available now --limit 25
```

Use `--include-notes` only when notes are needed. Note conversion is more
expensive than list queries.

Preserve source context when migrating:

```text
Source: Markdown task note - tasks/Example.md
```

## Recommended Claude Commands

Agenda for one person:

```sh
ofctl tasks --tag "$PERSON_NAME"
```

Available work:

```sh
ofctl tasks --available now --limit 25
```

Planned-now work:

```sh
ofctl tasks --planned now --limit 25
```

Waiting-on review:

```sh
ofctl tasks --tag "Waiting On" --limit 50
```

## Known Limitations

Multi-tag filtering is not fully implemented yet. If Claude passes multiple
`--tag` values, the current parser retains the last one. Query one tag at a time
and inspect returned tags until multi-tag support is added.

There is no `task TASK_ID` command yet. To inspect one task, query a likely tag
and filter client-side.

There are no bulk update commands. Claude should update tasks one at a time and
report each result.

## Permission Model

`ofctl` uses macOS automation to ask OmniFocus to evaluate Omni Automation
JavaScript. macOS may prompt for Automation permission the first time it runs.

The executable does not run a daemon, open a network port, install a server, or
receive remote requests. It only acts when invoked locally.
