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

Tag filters can use either a leaf tag name or a slash-delimited tag path:

```sh
ofctl tasks --tag "People/Alex Rivera"
ofctl tasks --tag "Status/Work 💼"
```

Repeated tags use AND semantics by default:

```sh
ofctl tasks --tag "@computer" --tag "Waiting On"
```

Use `--tag-mode any` for OR semantics:

```sh
ofctl tasks --tag "@computer" --tag "@phone" --tag-mode any
```

Query by project or folder:

```sh
ofctl tasks --project "Product Launch"
ofctl tasks --folder Work
```

Query flagged tasks:

```sh
ofctl tasks --flagged
```

Text output:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Text output includes task name, project or inbox location, tags, defer date,
planned date, due date, and completion date when present.

Fetch one task by ID:

```sh
ofctl task TASK_ID
ofctl task TASK_ID --include-notes --format text
ofctl task TASK_ID --include-children
```

## Work Computer Privacy Scope

On a work computer, set `OFCTL_WORK_HOSTNAMES` to a comma-separated list that
includes that Mac's hostname:

```sh
export OFCTL_WORK_HOSTNAMES="work-macbook-hostname"
```

When active, `ofctl` limits read and write commands to Inbox items and items in
projects under an OmniFocus folder named `Work`. Task queries silently omit
other items, and direct task lookup, task writes, and project status changes
outside that scope fail.

If OmniFocus is installed in a non-standard location or LaunchServices cannot
resolve it reliably, configure the app target explicitly:

```sh
export OFCTL_OMNIFOCUS_BUNDLE_ID="com.omnigroup.OmniFocus4"
export OFCTL_OMNIFOCUS_APP_NAME="OmniFocus"
export OFCTL_OMNIFOCUS_APP_PATH="/Applications/OmniFocus.app"
```

## Perspectives

List built-in and custom OmniFocus perspectives:

```sh
ofctl perspectives
ofctl perspectives --format text
```

Query tasks from a built-in perspective:

```sh
ofctl tasks --perspective Forecast
ofctl tasks --perspective Flagged --format text
```

Query tasks from a custom perspective:

```sh
ofctl tasks --perspective "Waiting On" --limit 50
```

Custom perspectives can also be queried by the `identifier` returned from
`ofctl perspectives`.

Perspective queries use OmniFocus's own perspective engine, then apply any
additional `ofctl` filters you pass:

```sh
ofctl tasks --perspective Forecast --tag "@computer" --limit 25
ofctl tasks --perspective "Waiting On" --due before:now --format text
```

`ofctl` briefly switches the front OmniFocus window to read the perspective
content tree, then restores the previous perspective. This is read-only, but the
window may visibly change while the command runs.

## Availability And Date Filters

Use `--available` when you want tasks that are available by effective defer
date. Tasks with no defer date count as available. Tasks whose containing
project is on hold, done, or dropped are never available. For point-in-time
queries (`--available now`), tasks OmniFocus reports as blocked (a sequential
predecessor incomplete, or an on-hold ancestor) are also excluded — matching
what the OmniFocus UI shows as available right now. Date-window variants
(`--available today`, `before:`/`after:`) apply only the defer-date and
project-status checks, since blocking can change within the window.

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

Use `--completed` for completion dates. Passing `--completed` automatically
includes completed tasks.

```sh
ofctl tasks --completed today
ofctl tasks --completed before:now
ofctl tasks --completed on:2026-05-20
```

Use `--repeat-rule` to audit recurrence:

```sh
ofctl tasks --repeat-rule any
ofctl tasks --repeat-rule none
ofctl tasks --repeat-rule "FREQ=WEEKLY;INTERVAL=1"
```

`any` matches tasks with a repeat rule, `none` matches tasks without one, and an
RRULE string matches that exact repeat rule.

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
ofctl tasks --folder Work --completed today
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
- `folders`
- `inInbox`
- `tags`
- `tagPaths`
- `deferDate`
- `plannedDate`
- `dueDate`
- `completionDate`
- `effectiveCompletionDate`
- `effectiveDropDate`
- `effectiveDeferDate`
- `effectivePlannedDate`
- `effectiveDueDate`
- `repeatRule`
- `repeatMethod`
- `repetitionRule`
- `estimatedMinutes`
- `parent`
- `hasChildren`
- `childCount`
- `sequential`
- `completedByChildren`
- `children` when `task --include-children` is used
- `flagged`
- `completed`
- `dropped`
- `individuallyCompleted`
- `individuallyDropped`
- `effectivelyCompleted`
- `effectivelyDropped`
- `path`

`completed` and `dropped` reflect OmniFocus's effective task state, including
completion or drop state inherited from a parent action group, project, or
folder. The `individuallyCompleted` and `individuallyDropped` fields reflect
only the task's own state.

Response metadata includes:

- `perspective`: active perspective name, or `null`
- `project`: active project filter, or `null`
- `folder`: active folder filter, or `null`
- `tags`: active tag filters
- `tagMode`: `all` or `any`
- `repeatRule`: active repeat rule filter, or `null`
- `total`: total matches
- `count`: returned task count
- `limit`: active limit, or `null` for `--all`
- `truncated`: whether there are more matches than returned

Inspect structure with `jq`:

```sh
ofctl tasks --available now --limit 10 | jq '.tasks[] | {name, project, inInbox, path}'
```

Single-task lookup returns `{ "task": ... }` with the same task object shape.

## Add Tasks

Create a task:

```sh
ofctl add "Ask Taylor about launch date"
```

Add to a project:

```sh
ofctl add "Ask Taylor about launch date" --project "Work Follow-ups"
```

If the named project does not exist, `ofctl` creates it as a top-level
OmniFocus project before adding the task. `--dry-run` reports whether the
project already exists or would be created.

Add to a project inside a folder, including a nested folder:

```sh
ofctl add "Ask Taylor about launch date" --project "Work Follow-ups" --folder "Work/Planning"
```

When `--folder` is present, `ofctl` targets or creates the named project inside
that folder path. `--folder` requires `--project`.

Add tags:

```sh
ofctl add "Ask Alex for project status" \
  --tag "Alex Rivera" \
  --tag "Waiting On" \
  --tag "Work"
```

Prefer tag paths when the parent matters:

```sh
ofctl add "Ask Alex for project status" \
  --tag "People/Alex Rivera" \
  --tag "Status/Work 💼"
```

When adding tags, `ofctl` resolves paths parent-by-parent and creates any
missing path segments. Plain person-looking tags such as `Alex Rivera` are
created under `People` when that tag exists. Plain `Work` resolves to
`Status/Work 💼` when that tag exists. `--dry-run` reports which tags exist and
which tags would be created.

Set dates and duration:

```sh
ofctl add "Draft launch follow-up" \
  --planned "2026-05-19T09:00:00" \
  --defer "2026-05-19" \
  --due "2026-05-22" \
  --duration 30
```

Set a repeating task with an ICS RRULE string:

```sh
ofctl add "Water plants" \
  --due "2026-05-22" \
  --repeat-rule "FREQ=WEEKLY;INTERVAL=1" \
  --repeat-method due
```

`--repeat-method` controls how OmniFocus schedules the next occurrence:

- `fixed`: regular fixed schedule that does not drift when completed late.
- `due`: due again after completion.
- `defer`: defer again after completion.

If `--repeat-method` is omitted, `ofctl` uses OmniFocus's fixed repeat method.
`--repeat-method` must be used with `--repeat-rule`.

Flag a task as the day's top priority:

```sh
ofctl add "Ship the deck" --project "Product Launch" --flag
```

Use `--no-flag` to explicitly create a task without a flag when you want to be explicit:

```sh
ofctl add "Low priority item" --no-flag
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

## Action Groups

OmniFocus action groups are tasks with child tasks. `ofctl` represents them with
the same task JSON shape and adds child-specific fields such as `hasChildren`,
`childCount`, `sequential`, `completedByChildren`, and `children`.

Create an action group:

```sh
ofctl add-group "Launch checklist" --project "Product Launch"
```

Create a sequential action group:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --sequential
```

Create a parallel action group:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --parallel
```

Set whether the action group completes automatically when its children complete:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --complete-with-children

ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --no-complete-with-children
```

Add a task to an action group:

```sh
ofctl add "Send launch note" --parent ACTION_GROUP_TASK_ID
```

You can also create nested action groups by combining `add-group` with
`--parent`:

```sh
ofctl add-group "Release-day checks" --parent ACTION_GROUP_TASK_ID --sequential
```

Read an action group and its child tasks:

```sh
ofctl task ACTION_GROUP_TASK_ID --include-children
```

Read notes and children together:

```sh
ofctl task ACTION_GROUP_TASK_ID --include-notes --include-children
```

Update action group behavior:

```sh
ofctl update ACTION_GROUP_TASK_ID --sequential
ofctl update ACTION_GROUP_TASK_ID --parallel
ofctl update ACTION_GROUP_TASK_ID --complete-with-children
ofctl update ACTION_GROUP_TASK_ID --no-complete-with-children
```

Action group settings are task properties in OmniFocus. `sequential: true`
means child tasks block each other in order; `sequential: false` means the
children are parallel. `completedByChildren` controls whether the group is
completed automatically after its children are complete.

Dry-run action group writes:

```sh
ofctl add-group "Launch checklist" --project "Product Launch" --dry-run
ofctl add "Send launch note" --parent ACTION_GROUP_TASK_ID --dry-run
ofctl update ACTION_GROUP_TASK_ID --parallel --dry-run
```

`--project` and `--parent` are mutually exclusive. Use `--project` when creating
an action group at the project root, and `--parent` when creating a child task or
nested action group under another task.

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

Update or clear recurrence:

```sh
ofctl update TASK_ID --repeat-rule "FREQ=MONTHLY;INTERVAL=1" --repeat-method fixed
ofctl update TASK_ID --repeat-rule none
```

Move one or more tasks to another project (pass multiple ids to move them all):

```sh
ofctl update TASK_ID [TASK_ID ...] --project "Work Follow-ups"
```

If the named project does not exist, `ofctl` creates it before moving the
task(s). Without a privacy scope it is created as a top-level project. To place
the new project in a folder, add `--folder` (same semantics as `add --folder`):

```sh
ofctl update TASK_ID TASK_ID --project "Q3 Planning" --folder "Work/Planning"
```

When a privacy scope is active and allows exactly one folder (for example a work
scope that allows only `Work`), `update` creates new projects in that folder
automatically — so `--folder` is optional in that case:

```sh
ofctl update TASK_ID TASK_ID --project "Q3 Planning"   # creates inside Work
```

Require the project to already exist:

```sh
ofctl update TASK_ID --project "Work Follow-ups" --no-create-project
```

Use this guardrail when processing inbox tasks or when the project name may be a
partial match.

`--project` matches by exact name across every folder (including projects nested
in subfolders), then falls back to a project's primary-key id. Pass an id to
target one project unambiguously — for example a dropped project that shares a
name with an active one, since a name always resolves to the active twin:

```sh
ofctl update TASK_ID --project "hrqEheYhIFz" --no-create-project   # by id
```

Move back to the inbox:

```sh
ofctl update TASK_ID --project none
```

Add tags:

```sh
ofctl update TASK_ID --tag "Alex Rivera" --tag "Waiting On"
```

`--add-tag` is also accepted when that reads more clearly:

```sh
ofctl update TASK_ID --add-tag "Waiting On"
```

Use tag paths when changing nested tags:

```sh
ofctl update TASK_ID --add-tag "People/Alex Rivera"
ofctl update TASK_ID --remove-tag "Status/Work 💼"
```

Remove tags:

```sh
ofctl update TASK_ID --remove-tag "Waiting On"
```

Clear existing tags before adding new ones:

```sh
ofctl update TASK_ID --clear-tags --tag "Alex Rivera"
```

Update notes:

```sh
ofctl update TASK_ID --note-file /tmp/of-note.md
```

Set action group ordering or completion behavior:

```sh
ofctl update TASK_ID --sequential
ofctl update TASK_ID --parallel
ofctl update TASK_ID --complete-with-children
ofctl update TASK_ID --no-complete-with-children
```

Flag a task as the day's top priority:

```sh
ofctl update TASK_ID --flag
```

Clear a flag:

```sh
ofctl update TASK_ID --no-flag
```

Complete a task:

```sh
ofctl update TASK_ID --complete
ofctl update TASK_ID --completed-at "2026-05-20T13:00:00"
```

Mark a completed task incomplete:

```sh
ofctl update TASK_ID --incomplete
```

Drop a task:

```sh
ofctl update TASK_ID --drop
```

For a repeating task, drop all future occurrences:

```sh
ofctl update TASK_ID --drop --all-occurrences
```

Skip the current occurrence of a repeating task while preserving the repeat:

```sh
ofctl update TASK_ID --skip
```

Dry-run:

```sh
ofctl update TASK_ID --planned none --dry-run
```

Apply the same change to multiple tasks at once:

```sh
ofctl update ID1 ID2 ID3 --add-tag "Waiting On" --dry-run
ofctl update ID1 ID2 ID3 --complete --dry-run
```

The response contains a `tasks` array with one entry per ID. All mutations apply
to every task — use `--dry-run` first when touching more than one task.

## Rename A Task

Use `task-rename` when the only intended change is the task name:

```sh
ofctl task-rename TASK_ID --to "Follow up with Taylor" --dry-run
ofctl task-rename TASK_ID --to "Follow up with Taylor"
```

This uses OmniFocus's native task `name` property. `update TASK_ID --name NAME`
remains available when renaming is part of a broader task update.

## Move Tasks

Use `task-move` when order matters, or when moving a task into a project,
action group, or inbox without changing other metadata.

Move a task before or after another task:

```sh
ofctl task-move TASK_ID --before TARGET_TASK_ID --dry-run
ofctl task-move TASK_ID --after TARGET_TASK_ID
```

Move several tasks together, preserving the ID order supplied on the command
line:

```sh
ofctl task-move ID1 ID2 ID3 --before TARGET_TASK_ID --dry-run
```

Move to a container:

```sh
ofctl task-move TASK_ID --project "Product Launch"
ofctl task-move TASK_ID --project "Product Launch" --position beginning
ofctl task-move TASK_ID --parent ACTION_GROUP_TASK_ID
ofctl task-move TASK_ID --inbox --position beginning
```

`--position` accepts `beginning` or `ending` and defaults to `ending`. It only
applies with `--project`, `--parent`, or `--inbox`; `--before` and `--after`
already define an exact insertion point.

## Creating Projects

### Regular project

`ofctl add --project NAME` creates a regular parallel project if one with that
name does not already exist. Omitting `--folder` creates the project at the
library top level; adding `--folder FOLDER_PATH` targets or creates the project
inside that folder, including nested paths like `Work/Planning`. Use this for
multi-step projects where you add the first task at the same time.

### Dedicated project-create command

Use `project-create` when you want to create a project shell first — before
adding tasks — or when you need options unavailable on `add`:

```sh
# Create a single-action list in the Work folder
ofctl project-create "Work Notifications" --folder Work --singleton

# Create a regular project in a subfolder
ofctl project-create "Q3 Planning" --folder Work

# Create a project on-hold (Someday/Maybe)
ofctl project-create "Learn Rust" --folder Personal --on-hold

# Dry-run to preview without writing
ofctl project-create "My Project" --folder Work --singleton --dry-run
```

`--singleton` sets the project as a single-action list (`containsSingletonActions = true`).
Single-action lists are the right project type for ongoing collections of
independent tasks — GitHub notifications, work admin items, etc.

`--folder` places the project inside the named folder. Omitting it creates the
project at the library top level (not recommended — always use a folder).

## Project Status

Set a project status:

```sh
ofctl project-status "Product Launch" --status active
ofctl project-status "Product Launch" --status on-hold
ofctl project-status "Product Launch" --status completed
ofctl project-status "Product Launch" --status dropped
```

Use `--dry-run` to preview the project status mutation:

```sh
ofctl project-status "Product Launch" --status on-hold --dry-run
```

Every `project-*` command takes the project as a name or a primary-key id. A name
resolves to the active project when a dropped/completed twin shares that name, so
target the twin by id:

```sh
ofctl project-status "hrqEheYhIFz" --status dropped   # id targets a specific twin
ofctl project-delete "hrqEheYhIFz"
```

## Project Completion

Set or unset "Complete with last action" on a parallel or sequential project:

```sh
ofctl project-completion "Product Launch" --complete-with-last-action
ofctl project-completion "Product Launch" --no-complete-with-last-action
```

Use `--dry-run` to preview the mutation:

```sh
ofctl project-completion "Product Launch" --complete-with-last-action --dry-run
```

This controls OmniFocus's project `completedByChildren` property. It applies to
parallel and sequential projects, not single-action lists.

## Move A Project

Move a project into a folder:

```sh
ofctl project-move "Home Maintenance" --to-folder Home
ofctl project-move "Side Project" --to-folder Personal
```

Move a project back to the library top level (no folder):

```sh
ofctl project-move "Home Maintenance" --to-folder none
```

Nested folders are supported using a slash-delimited path. The destination is
resolved by exact full-path match first, then falls back to leaf name if
unambiguous:

```sh
ofctl project-move "Sub-initiative" --to-folder "Work/Q2 Planning"
```

Use `--dry-run` to preview without mutating:

```sh
ofctl project-move "Home Maintenance" --to-folder Home --dry-run
```

## Rename A Project

Rename an existing project:

```sh
ofctl project-rename "Home Maintenance" --to "House Maintenance" --dry-run
ofctl project-rename "Home Maintenance" --to "House Maintenance"
```

This uses OmniFocus's native project `name` property. It does not recreate the
project or move its tasks.

## Project Notes (project-note)

Set, prepend to, or clear a project's **freeform note**. The project can be given
by **name or by primary-key id** (e.g. the id from an `omnifocus:///project/<id>`
link).

```sh
ofctl project-note PROJECT_NAME_OR_ID (--note TEXT | --note-file PATH | --prepend TEXT | --note none) [--dry-run]
```

Exactly one operation per call:

- `--note TEXT` — replace the freeform note with `TEXT`.
- `--note-file PATH` — replace the freeform note with the contents of a file.
- `--prepend TEXT` — insert `TEXT` above the existing freeform note (blank-line
  separated). Ideal for adding a reference link to the top of the note.
- `--note none` — clear the freeform note.

```sh
# Add an Obsidian deep link to the top of the note
ofctl project-note "House Maintenance" --prepend "[Notes](obsidian://open?vault=Home&file=House%20Maintenance)"

# Replace the whole freeform note
ofctl project-note "House Maintenance" --note "Contractor: Acme; quote pending"

# Target by id, preview with --dry-run
ofctl project-note pjJ8kQ2xYz1 --note-file ./note.md --dry-run

# Clear it
ofctl project-note "House Maintenance" --note none
```

**State block is always preserved.** If the note contains a trailing
`=== ofctl-state ===` block (see [Note State Block](#note-state-block-task-state--project-state)),
`project-note` only edits the freeform region **above** it — the block is never
clobbered. This is unlike task `--note`, which replaces the entire note. Use
`project-state` to edit the block itself.

## projects

Lists projects with optional filtering. Each project in the JSON result includes
`id`, `name`, `folder` (array), `status`, `singleton`, `sequential`,
`completedByChildren`, `reviewInterval` (`{steps, unit}` or null),
`nextReviewDate`, and `lastReviewDate`. With `--include-notes`, each project also
includes a `note` field (its freeform note plus any state block, as Markdown).

```sh
ofctl projects [--folder NAME] [--status active|on-hold|completed|dropped] [--due-for-review] [--limit COUNT|--all] [--include-notes] [--format json|text]
```

List all projects:

```sh
ofctl projects --format text
```

Projects in a specific folder:

```sh
ofctl projects --folder Work --format text
```

Only active projects:

```sh
ofctl projects --status active --format text
```

Projects due for review (nextReviewDate ≤ now):

```sh
ofctl projects --due-for-review --format text
```

Include each project's note (text output prints the note's first line):

```sh
ofctl projects --folder Home --include-notes --format text
```

## project-review

Sets a project's review interval and/or marks it as reviewed.

```sh
ofctl project-review PROJECT_NAME [--mark-reviewed] [--interval SPEC|none] [--dry-run]
```

Interval spec format: `<N><unit>` where unit is `d` (days), `w` (weeks),
`m` (months), or `y` (years). Example: `1w`, `2m`, `90d`, `1y`.

Set a weekly review interval:

```sh
ofctl project-review "Work Notifications" --interval 1w
```

Mark a project as reviewed:

```sh
ofctl project-review "Home Maintenance" --mark-reviewed
```

Set interval and mark reviewed together:

```sh
ofctl project-review "Home Maintenance" --mark-reviewed --interval 2w --dry-run
ofctl project-review "Home Maintenance" --mark-reviewed --interval 2w
```

Clear the review interval:

```sh
ofctl project-review "Home Maintenance" --interval none
```

> **API note:** `--mark-reviewed` calls `project.markReviewed()` in OmniJS,
> which advances `nextReviewDate` by the review interval. If the project has no
> review interval set, setting one first is recommended.

## Note State Block (task-state / project-state)

`task-state` and `project-state` read or merge a small key/value metadata block
stored at the end of a task or project note. This lets external tooling persist
structured state — for example prioritization signals such as slip history, a
priority tier, and why-it-matters context — that syncs across machines through
OmniFocus itself, with no local state file needed. The block is general-purpose
and accepts any `key: value` pairs.

The block is delimited by a sentinel line and lives at the end of the note. The
freeform note content above the sentinel is never touched:

```
From: Circuit Daily Sync on 6/20/2026

=== ofctl-state ===
priority: P1
priority-source: auto
slip-count: 3
last-planned: 2026-06-23
why: committed in sync; blocks the ADR
```

> **Why `=== ofctl-state ===` and not a `###` heading?** `ofctl` strips
> markdown heading markers when writing a note but does not re-emit them when
> reading, so a heading sentinel would not survive the round trip. The `===`
> sentinel contains no markdown-special characters and round-trips verbatim.

> **Freeform notes round-trip losslessly.** Each `--set` / `--increment` /
> `--clear-key` rewrites the whole note (freeform region plus state block), so
> the freeform text must survive the read → write cycle unchanged. Markdown-special
> characters — underscores, asterisks, square brackets, backticks, and backslashes,
> common in URLs and Salesforce field names such as `Some_Field__c` — are escaped
> on read and unescaped on write symmetrically, so they neither accumulate
> backslashes nor drift no matter how many times the state block is updated.

```sh
ofctl task-state TASK_ID (--get | [--set KEY=VALUE ...] [--increment KEY ...] [--clear-key KEY ...] | --clear) [--format json|text] [--dry-run]
ofctl project-state PROJECT_NAME (--get | [--set KEY=VALUE ...] [--increment KEY ...] [--clear-key KEY ...] | --clear) [--format json|text] [--dry-run]
```

`task-state` takes a task ID; `project-state` takes a project name. Exactly one
mode is used per call: `--get` to read, or a mutation. `--get` cannot be
combined with a mutation, and `--clear` (which removes the whole block) cannot
be combined with `--set`/`--increment`/`--clear-key`.

Read the parsed block as JSON (default format):

```sh
ofctl task-state abc123 --get
```

Read as plain `key: value` lines:

```sh
ofctl task-state abc123 --get --format text
```

Merge values (creates the block if absent, preserves existing keys, keeps write
order). Values may contain colons — only the first `:` splits key from value:

```sh
ofctl task-state abc123 --set priority=P1 --set "why=committed in sync: blocks the ADR"
```

Atomically bump a numeric counter (missing or non-numeric is treated as 0):

```sh
ofctl task-state abc123 --increment slip-count
```

Remove a single key, or wipe the entire block (leaving the freeform note):

```sh
ofctl task-state abc123 --clear-key why
ofctl task-state abc123 --clear
```

Preview any mutation without writing — prints the resulting note and state:

```sh
ofctl task-state abc123 --set priority=P2 --dry-run
```

Project state works identically against a project name:

```sh
ofctl project-state "Product Launch" --set priority=P2 --set last-reviewed=2026-06-24
ofctl project-state "Product Launch" --get --format text
```

## task-delete

Deletes one or more tasks by OmniFocus ID. All IDs are validated first; if any
ID is not found or is outside the current privacy scope, the entire operation
fails and nothing is deleted.

```sh
ofctl task-delete TASK_ID [TASK_ID ...] [--dry-run]
```

Delete a single task:

```sh
ofctl task-delete TASK_ID --dry-run
ofctl task-delete TASK_ID
```

Delete several tasks at once:

```sh
ofctl task-delete ID1 ID2 ID3 --dry-run
ofctl task-delete ID1 ID2 ID3
```

The response includes an array of `{id, name, deleted}` objects.

## project-delete

Deletes a project by name.

```sh
ofctl project-delete PROJECT_NAME [--dry-run]
```

```sh
ofctl project-delete "Home Maintenance" --dry-run
ofctl project-delete "Home Maintenance"
```

The response includes `project.id`, `project.name`, and `project.folder` (the
folder path array). Always dry-run first to confirm the correct project is
targeted.

## tags

Lists all tags with their full path, parent, and child count.

```sh
ofctl tags [--format json|text]
```

```sh
ofctl tags --format text
```

Each JSON entry includes `id`, `name`, `path` (slash-delimited full path), `parent`,
`parentPath`, and `childCount`.

Tags are not folder-scoped — all tags are visible regardless of privacy scope.

## tag-create

Creates a new tag, optionally under an existing parent tag.

```sh
ofctl tag-create NAME [--parent TAG_PATH] [--dry-run]
```

Create a top-level tag:

```sh
ofctl tag-create "Contexts"
```

Create a child tag (parent resolved by name or slash-delimited path):

```sh
ofctl tag-create "Errands" --parent "Contexts"
ofctl tag-create "Home" --parent "Contexts/Errands"
```

Errors if a tag with that name already exists at the target path.

## tag-rename

Renames an existing tag.

```sh
ofctl tag-rename TAG_PATH --to NEW_NAME [--dry-run]
```

```sh
ofctl tag-rename "Contexts/Errands" --to "Out & About"
ofctl tag-rename "Old Label" --to "New Label" --dry-run
```

The tag path uses the tag name at each level separated by `/`. Only the leaf name
is changed; the tag remains in its current location in the hierarchy.

## tag-delete

Deletes a tag. The response includes `childCount` and `taskCount` (all descendant
tasks carrying this tag) so you can see the blast radius before committing.

```sh
ofctl tag-delete TAG_PATH [--dry-run]
```

```sh
ofctl tag-delete "Status/Deprecated" --dry-run
ofctl tag-delete "Status/Deprecated"
```

Deleting a parent tag also removes all child tags.

## tag-move

Reparents a tag under a different tag, or moves it to the top level.

```sh
ofctl tag-move TAG_PATH --to-parent TAG_PATH|none [--dry-run]
```

Move to a different parent:

```sh
ofctl tag-move "Errands" --to-parent "Contexts"
```

Move to the top level:

```sh
ofctl tag-move "Contexts/Errands" --to-parent none
```

Use `--dry-run` to preview without mutating:

```sh
ofctl tag-move "Errands" --to-parent "Contexts" --dry-run
```

## folder-create

Creates a new OmniFocus folder, optionally nested inside an existing parent.

```sh
ofctl folder-create NAME [--parent FOLDER_PATH] [--dry-run]
```

Create a top-level folder:

```sh
ofctl folder-create "Home Maintenance"
```

Create a nested folder (parent resolved by name or slash-delimited path):

```sh
ofctl folder-create "Garden" --parent "Home Maintenance"
ofctl folder-create "Sprints" --parent "Work/Q3 Planning"
```

Use `--dry-run` to preview without mutating:

```sh
ofctl folder-create "Work Projects" --dry-run
```

The returned JSON includes `folder.id`, `folder.name`, and `folder.path` (the
full path as an array of folder names from root to the new folder).

## Common Queries

Person agenda:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Forecast:

```sh
ofctl tasks --perspective Forecast --format text
```

Flagged:

```sh
ofctl tasks --flagged --format text
```

Available computer work:

```sh
ofctl tasks --available now --tag "@computer" --limit 25 --format text
```

Available work in a folder:

```sh
ofctl tasks --folder Work --available now --limit 25 --format text
```

Focused project work:

```sh
ofctl tasks --project "Product Launch" --available now --format text
```

Phone or computer work:

```sh
ofctl tasks --tag "@phone" --tag "@computer" --tag-mode any --format text
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

Completed today:

```sh
ofctl tasks --completed today --format text
```

Waiting-on items for a person:

```sh
ofctl tasks --tag "Alex Rivera" --tag "Waiting On" --format text
```
