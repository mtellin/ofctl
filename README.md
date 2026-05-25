# ofctl

`ofctl` is a native Swift command-line bridge for OmniFocus.

> [!NOTE]
> This is a 100% vibe-coded app built for my personal workflow. It is shared in
> case it is useful to others, but it is not a polished commercial product. If
> you run into a problem, open an issue and I can try to address it.

It exists so Claude Code and other local automation can work with OmniFocus
without installing an unauthorized MCP server. Instead of granting broad,
open-ended access to OmniFocus, `ofctl` exposes a small set of auditable
commands that can be approved, logged, tested, and reasoned about.

## Why This Exists

OmniFocus is the source of truth for active execution. Claude is useful for
meeting prep, agenda generation, task cleanup, and migration from Markdown task
notes, but Claude needs a stable interface to OmniFocus to do that work safely.

`ofctl` provides that interface:

- Query tasks for meeting agendas, especially by person tag.
- Inspect planned, due, deferred, completed, and available work.
- Query tasks from built-in or custom OmniFocus perspectives.
- Scope day-planning queries by project, folder, tags, and flagged state.
- Add tasks from Claude workflows without using OmniFocus UI automation directly.
- Create action groups and add child tasks to an existing action group.
- Update task metadata such as project, tags, dates, duration, notes, and
  completion/drop state.
- Set action group ordering and completion behavior.
- Create a top-level OmniFocus project when a task is added or moved to a
  project name that does not exist.
- Skip the current occurrence of a repeating task.
- Change project status between active, on hold, completed, and dropped.
- Move a project into a folder (or back to the library top level).
- Convert Markdown notes to OmniFocus rich text on write.
- Convert OmniFocus rich notes back to Markdown on read.
- Keep Claude-facing automation narrow enough to be acceptable on machines where
  an MCP server cannot be installed.

## Design Goals

- Native macOS tooling: Swift CLI plus OmniFocus automation.
- Omni Automation JavaScript executed through direct Apple Events, keeping the
  task logic in OmniJS while avoiding a shell script runner in the hot path.
- Minimal command surface: explicit commands instead of arbitrary app control.
- Claude-friendly output: JSON by default, text output for quick terminal checks.
- Safe defaults: list queries omit rich notes unless requested.
- GTD-friendly semantics: person tags, waiting-on tags, project context, planned
  dates, due dates, defer availability, and estimated duration are first-class.

## Requirements

- macOS
- OmniFocus 4.7+ with the database migrated for Planned Dates
- Swift toolchain
- macOS Automation permission for `ofctl` to control OmniFocus

## Build

```sh
swift build
swift build -c release --product ofctl
```

The release executable is:

```sh
.build/release/ofctl
```

## Quick Start

Query agenda items for a person:

```sh
ofctl tasks --tag "Alex Rivera" --format text
```

Find work available now:

```sh
ofctl tasks --available now --limit 25 --format text
```

Find tasks planned up to the current moment:

```sh
ofctl tasks --planned now --format text
```

Find tasks in a project or folder:

```sh
ofctl tasks --project "Product Launch" --format text
ofctl tasks --folder Work --available now --format text
```

Find completed work:

```sh
ofctl tasks --completed today --format text
```

List OmniFocus perspectives:

```sh
ofctl perspectives --format text
```

Query tasks from a perspective:

```sh
ofctl tasks --perspective Forecast --format text
ofctl tasks --perspective "Waiting On" --limit 50
```

Fetch one task by ID:

```sh
ofctl task TASK_ID --include-notes
```

Create an action group and add a child task:

```sh
ofctl add-group "Launch checklist" \
  --project "Product Launch" \
  --sequential

ofctl add "Send launch note" --parent ACTION_GROUP_TASK_ID
```

Read an action group with its children:

```sh
ofctl task ACTION_GROUP_TASK_ID --include-children
```

Add a waiting-on task:

```sh
ofctl add "Ask Alex for project status" \
  --project "Work Follow-ups" \
  --tag "People/Alex Rivera" \
  --tag "Waiting On" \
  --tag "Status/Work 💼" \
  --note "Waiting on Alex Rivera."
```

Add or find repeating tasks:

```sh
ofctl add "Water plants" \
  --due "2026-05-22" \
  --repeat-rule "FREQ=WEEKLY;INTERVAL=1" \
  --repeat-method due

ofctl tasks --repeat-rule any --format text
```

Flag the day's top-priority task:

```sh
ofctl add "Ship the deck" --project "Product Launch" --flag
ofctl update TASK_ID --flag
ofctl update TASK_ID --no-flag
```

Dry-run any write first:

```sh
ofctl add "Ask Taylor about launch date" --tag "Taylor Morgan" --dry-run
```

Create folders:

```sh
ofctl folder-create "Home Maintenance"
ofctl folder-create "Garden" --parent "Home Maintenance"
ofctl folder-create "Work Projects" --dry-run
```

Manage tags:

```sh
ofctl tags --format text
ofctl tag-create "Errands" --parent "Contexts"
ofctl tag-rename "Contexts/Errands" --to "Out & About"
ofctl tag-move "Out & About" --to-parent "Status" --dry-run
ofctl tag-delete "Deprecated Tag" --dry-run
```

List and review projects:

```sh
ofctl projects --format text
ofctl projects --due-for-review --format text
ofctl projects --folder Work --status active --format text
ofctl project-review "Work Notifications" --interval 1w
ofctl project-review "Work Notifications" --mark-reviewed
ofctl project-review "Work Notifications" --mark-reviewed --interval 2w --dry-run
```

Delete tasks and projects (always dry-run first):

```sh
ofctl task-delete TASK_ID --dry-run
ofctl task-delete TASK_ID
ofctl task-delete ID1 ID2 ID3 --dry-run
ofctl project-delete "Home Maintenance" --dry-run
ofctl project-delete "Home Maintenance"
```

## Documentation

- [User Guide](docs/user-guide.md): complete command reference and examples.
- [Claude Integration](docs/claude-integration.md): how Claude Code should use
  `ofctl` in place of an MCP server.
- [Task Conventions](docs/task-conventions.md): recommended tags, dates,
  waiting-on behavior, and Markdown note handling.

## Current Commands

- `ofctl perspectives`: list built-in and custom OmniFocus perspectives.
- `ofctl task`: fetch one task by OmniFocus ID.
- `ofctl tasks`: query tasks by project, folder, tag, availability, planned
  date, defer date, due date, repeat rule, completion date, perspective,
  flagged state, completion/dropped state, and output format.
- `ofctl add`: create a task with project, tags, defer/planned/due dates,
  repeat rule, duration, Markdown notes, action group settings, flag state, or
  a parent action group.
- `ofctl add-group`: create an action group, optionally sequential/parallel and
  optionally completed by its children.
- `ofctl update`: update one or more tasks by ID — name, project, tags, dates,
  repeat rule, duration, notes, completion state, dropped state, flag state,
  action group settings, and skipped repeating occurrences.
- `ofctl project-status`: set a project to active, on hold, completed, or
  dropped.
- `ofctl project-move`: move a project into a folder (or to the library top
  level with `--to-folder none`).
- `ofctl project-create`: create a new project, optionally in a folder and
  optionally as a single-action list (`--singleton`) or on-hold (`--on-hold`).
- `ofctl folder-create`: create a new OmniFocus folder, optionally nested
  inside an existing parent folder.
- `ofctl tags`: list all tags with their paths and child counts.
- `ofctl tag-create`: create a new tag, optionally under a parent tag.
- `ofctl tag-rename`: rename an existing tag.
- `ofctl tag-delete`: delete a tag (reports task and child counts in response).
- `ofctl tag-move`: reparent a tag under a different tag or move it to the top
  level with `--to-parent none`.
- `ofctl task-delete`: delete one or more tasks by ID (accepts multiple IDs).
- `ofctl project-delete`: delete a project by name.
- `ofctl projects`: list projects with optional folder, status, and
  `--due-for-review` filters. Includes review interval and next/last review
  date in JSON output.
- `ofctl project-review`: set a project's review interval and/or mark it as
  reviewed. Interval spec: `<N><d|w|m|y>` (e.g. `1w`, `2m`); `none` clears.

Tags can be passed as leaf names or slash-delimited paths such as
`People/Alex Rivera` and `Status/Work 💼`. Missing path segments are created
under their parent; plain person-looking tags default under `People`, and plain
`Work` resolves to `Status/Work 💼` when that tag exists.

Recurrence uses OmniFocus repeat rules through ICS RRULE strings. Use
`--repeat-rule "FREQ=WEEKLY;INTERVAL=1"` to set a repeat, `--repeat-method
fixed|due|defer` to choose the repeat anchor, `--repeat-rule none` on `update`
to clear a repeat, and `tasks --repeat-rule any|none|RRULE` to audit repeating
or non-repeating tasks. `fixed` is a regular fixed schedule that does not drift
when completed late; `due` means due again after completion; `defer` means defer
again after completion.

Run:

```sh
ofctl help
```

## Safety Notes

`ofctl` is not a replacement for reviewing what Claude is doing. It is a safer
interface because it constrains what Claude can ask for:

- Read commands are explicit and bounded by default.
- Write commands support `--dry-run`.
- Broad task queries default to `--limit 100`.
- Rich note conversion is opt-in for queries with `--include-notes`.
- Notes preserve source context when migrating from Markdown task notes.

### Work Computer Privacy Scope

Set `OFCTL_WORK_HOSTNAMES` to a comma-separated list of hostnames on machines
where Claude should only see work data:

```sh
export OFCTL_WORK_HOSTNAMES="work-macbook-hostname"
```

When the current hostname matches that list, `ofctl` only returns or mutates
Inbox items and items whose containing project is under an OmniFocus folder
named `Work`. Direct task lookups and write commands for other folders fail
with a privacy-scope error.

If LaunchServices cannot reliably find OmniFocus, set
`OFCTL_OMNIFOCUS_BUNDLE_ID`, `OFCTL_OMNIFOCUS_APP_NAME`, or
`OFCTL_OMNIFOCUS_APP_PATH` to override the default target
`com.omnigroup.OmniFocus4` / `OmniFocus` / `/Applications/OmniFocus.app`.

## Development

Run tests:

```sh
swift test
```

Run from source:

```sh
swift run ofctl tasks --available now --limit 10 --format text
```

Build release:

```sh
swift build -c release --product ofctl
```
