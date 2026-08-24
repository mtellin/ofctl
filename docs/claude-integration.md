# Claude Integration

`ofctl` is intended to let Claude Code work with OmniFocus without installing an
MCP server.

On work-managed computers, configure `OFCTL_WORK_HOSTNAMES` with that Mac's
hostname so `ofctl` automatically restricts Claude-facing reads and writes to
Inbox items and projects under the OmniFocus `Work` folder.

If OmniFocus launch targeting is unreliable, configure
`OFCTL_OMNIFOCUS_BUNDLE_ID`, `OFCTL_OMNIFOCUS_APP_NAME`, or
`OFCTL_OMNIFOCUS_APP_PATH` instead of falling back to raw automation URLs.

## Integration Model

Claude should call `ofctl` as a local executable:

```sh
.build/release/ofctl tasks --tag "Alex Rivera"
```

The command surface is intentionally narrow:

- `tasks` for read workflows
- `task` for single-task inspection by ID
- `perspectives` for discovering built-in and custom OmniFocus views
- `add` for task creation
- `add-group` for action group creation
- `update` for controlled edits, including moving one or more tasks into a project; `--project` auto-creates a missing project (use `--folder` to place it in a folder, or rely on the single-folder default inside a privacy scope), so a separate `project-create` step is usually unnecessary when moving tasks
- `task-rename TASK_ID --to NEW_NAME` for task-only renames
- `task-move` for controlled task ordering and moves into projects, action groups, or inbox
- `project-status` for controlled project state changes
- `project-rename PROJECT_NAME --to NEW_NAME` for native project renames
- `project-note PROJECT_NAME_OR_ID` to set (`--note TEXT` / `--note-file PATH`), prepend (`--prepend TEXT`), or clear (`--note none`) a project's freeform note; accepts a project name or id, and preserves any trailing `=== ofctl-state ===` block (unlike task `--note`, which replaces the whole note). Use `--prepend` to add a reference link (e.g. an `obsidian://` deep link) to the top of a project that maps 1:1 to an external note
- `project-completion PROJECT_NAME --complete-with-last-action|--no-complete-with-last-action` for the project "Complete with last action" flag on parallel/sequential projects
- `project-create` to create a new project in a folder, optionally as a single-action list (`--singleton`) or on-hold (`--on-hold`)
- `folder-create` to create a new OmniFocus folder, optionally nested inside an existing parent folder
- `tags` to list all tags with paths (not folder-scoped; always returns all tags)
- `tag-create`, `tag-rename`, `tag-delete`, `tag-move` for tag management; always use `--dry-run` before `tag-delete` to confirm the blast radius
- `task-delete TASK_ID [TASK_ID ...]` to delete tasks; always `--dry-run` first and confirm IDs with the user before deleting
- `project-delete PROJECT_NAME` to delete a project; always `--dry-run` first
- `projects` to list projects with review dates; `--due-for-review` is useful for surfacing overdue reviews. Add `--include-notes` to read each project's note (e.g. to find a project's linked reference note)
- `project-review PROJECT_NAME --mark-reviewed` to advance the review date; use `--interval SPEC` (e.g. `1w`) to set a recurring interval. Vary intervals by how fast a project actually moves rather than leaving every project on one cadence — uniform intervals make the whole review queue come due on the same day. An interval cannot be cleared; use a long one such as `1y`. To pin the next review to a specific date rather than the interval-derived one, add `--next-review YYYY-MM-DD`.
- `task-state TASK_ID` / `project-state PROJECT_NAME` to read (`--get`) or merge (`--set KEY=VALUE`, `--increment KEY`, `--clear-key KEY`, `--clear`) a delimited `=== ofctl-state ===` metadata block in the note without clobbering its freeform content

This is easier to review and approve than general-purpose application
automation or a full OmniFocus MCP server.

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

For perspective-backed review:

```sh
ofctl perspectives --format text
ofctl tasks --perspective Forecast --limit 50
ofctl tasks --perspective "Waiting On" --limit 50
```

For focused day planning:

```sh
ofctl tasks --folder Work --available now --limit 50
ofctl tasks --project "Product Launch" --available now --limit 50
ofctl tasks --completed today --format text
ofctl tasks --tag "@phone" --tag "@computer" --tag-mode any --limit 25
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
  --tag "People/Alex Rivera" \
  --tag "Waiting On" \
  --tag "Status/Work 💼" \
  --note-file /tmp/of-note.md \
  --dry-run
```

Recurring task dry-run example:

```sh
ofctl add "Water plants" \
  --due "2026-05-22" \
  --repeat-rule "FREQ=WEEKLY;INTERVAL=1" \
  --repeat-method due \
  --dry-run
```

For Markdown notes that contain a short checklist, prefer an action group when
the checklist represents ordered or related work under one outcome:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --sequential \
  --note-file /tmp/of-note.md \
  --dry-run

ofctl add "Send launch note" \
  --parent "$ACTION_GROUP_TASK_ID" \
  --dry-run
```

## Safety Guidelines For Claude

Prefer read-only commands unless the user asks for a write.

Use `--dry-run` before creating or updating tasks when:

- The task name is subjective.
- The target project is ambiguous.
- A missing project would be created.
- A task is being inserted into an action group.
- Dates could be interpreted more than one way.
- The operation touches multiple tasks.

Use `--limit` on broad queries:

```sh
ofctl tasks --available now --limit 25
```

Use `--include-notes` only when notes are needed. Note conversion is more
expensive than list queries.

Prefer tag paths such as `People/$PERSON_NAME` and `Status/Work 💼` when
creating or updating tasks. Plain person-looking missing tags are created under
`People`, and plain `Work` resolves to `Status/Work 💼` when that tag exists,
but paths make the intended parent auditable in the command.

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
ofctl tasks --perspective "Waiting On" --limit 50
```

If there is no matching perspective, fall back to:

```sh
ofctl tasks --tag "Waiting On" --limit 50
```

Waiting-on items for one person:

```sh
ofctl tasks --tag "$PERSON_NAME" --tag "Waiting On" --limit 50
```

Inspect a known task ID:

```sh
ofctl task "$TASK_ID" --include-notes
```

Set the day's single top-priority task (flag it):

```sh
ofctl add "$TASK_NAME" --project "$PROJECT_NAME" --flag --dry-run
ofctl update "$TASK_ID" --flag --dry-run
ofctl update "$TASK_ID" --no-flag --dry-run
```

Only one task should be flagged at a time. Flag conveys "do this first today."
Use `tasks --flagged` to find the current flagged task before setting a new one.

Controlled task updates:

```sh
ofctl update "$TASK_ID" --add-tag "Waiting On" --dry-run
ofctl update "$TASK_ID" --remove-tag "Waiting On" --dry-run
ofctl update "$TASK_ID" --project none --dry-run
ofctl update "$TASK_ID" --project "$PROJECT_NAME" --folder "$FOLDER_PATH" --dry-run
ofctl update "$TASK_ID" --repeat-rule "FREQ=WEEKLY;INTERVAL=1" --repeat-method fixed --dry-run
ofctl update "$TASK_ID" --repeat-rule none --dry-run
ofctl update "$TASK_ID" --complete --dry-run
ofctl update "$TASK_ID" --skip --dry-run
```

Batch updates (multiple IDs apply the same mutation to all):

```sh
ofctl update "$ID1" "$ID2" "$ID3" --add-tag "Waiting On" --dry-run
ofctl update "$ID1" "$ID2" --complete --dry-run
```

Controlled task ordering:

```sh
ofctl task-move "$TASK_ID" --before "$TARGET_TASK_ID" --dry-run
ofctl task-move "$TASK_ID" --after "$TARGET_TASK_ID" --dry-run
ofctl task-move "$TASK_ID" --project "$PROJECT_NAME" --position beginning --dry-run
ofctl task-move "$TASK_ID" --parent "$ACTION_GROUP_TASK_ID" --dry-run
```

Use `task-move` instead of telling the user to drag tasks manually. Use
`--before` when an item must appear above a known reference task, such as a
README or setup task.

Controlled action group workflows:

```sh
ofctl add-group "Launch checklist" --project "$PROJECT_NAME" --sequential --dry-run
ofctl add "Send launch note" --parent "$ACTION_GROUP_TASK_ID" --dry-run
ofctl task "$ACTION_GROUP_TASK_ID" --include-children
ofctl update "$ACTION_GROUP_TASK_ID" --parallel --dry-run
ofctl update "$ACTION_GROUP_TASK_ID" --complete-with-children --dry-run
```

Use `--sequential` when child actions must happen in order. Use `--parallel`
when children can be worked independently. Use `--complete-with-children` only
when the group should automatically complete after all child tasks are complete.

Controlled project status updates:

```sh
ofctl project-status "$PROJECT_NAME" --status on-hold --dry-run
```

Read or merge the note state block (persists structured state in the note so it
syncs across machines; never use `update --note` for this — that replaces the
whole note):

```sh
ofctl task-state "$TASK_ID" --get
ofctl task-state "$TASK_ID" --get --format text
ofctl task-state "$TASK_ID" --set priority=P1 --set "why=committed in sync: blocks ADR" --dry-run
ofctl task-state "$TASK_ID" --increment slip-count
ofctl task-state "$TASK_ID" --clear-key why
ofctl project-state "$PROJECT_NAME" --set priority=P2 --set last-reviewed=2026-06-24
```

Read and edit a project's freeform note without disturbing its state block (the
`project-note` freeform edit and the `project-state` block edit are independent
and compose safely):

```sh
ofctl projects --folder "$FOLDER" --include-notes --format text
ofctl project-note "$PROJECT_NAME_OR_ID" --prepend "[Notes](obsidian://open?vault=Home&file=$ENCODED)"
ofctl project-note "$PROJECT_NAME_OR_ID" --note none
```

Controlled project moves (destination must be within the `Work` folder under
work privacy scope):

```sh
ofctl project-move "$PROJECT_NAME" --to-folder Work --dry-run
```

## Known Limitations

Project arguments (`--project` and the `PROJECT_NAME` positional on `project-*`
commands) resolve by exact name across all folders — including projects nested in
subfolders — and fall back to a primary-key id. Resolution is never a substring
match. When a dropped or completed project shares a name with an active one, the
name resolves to the active twin; pass the twin's id to target it. Prefer id when
scripting a mutation against a specific project you already looked up.

Repeated `--tag` filters use AND semantics by default. Use `--tag-mode any`
when a query should match any listed tag.

Recurrence is represented as an ICS RRULE string in `repeatRule`. Query repeating
tasks with `ofctl tasks --repeat-rule any`, query non-repeating tasks with
`--repeat-rule none`, and clear recurrence with `ofctl update TASK_ID
--repeat-rule none`. Use `--repeat-method fixed` for a regular fixed schedule
that should not drift when completed late. `--repeat-method due` means due again
after completion, and `--repeat-method defer` means defer again after completion.

## Permission Model

`ofctl` uses direct Apple Events to ask OmniFocus to evaluate Omni Automation
JavaScript. The task logic runs in OmniJS, and macOS may prompt for Automation
permission the first time it runs.

The executable does not run a daemon, open a network port, install a server, or
receive remote requests. It only acts when invoked locally.
