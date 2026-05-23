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
- `path`

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

Move to another project:

```sh
ofctl update TASK_ID --project "Work Follow-ups"
```

If the named project does not exist, `ofctl` creates it as a top-level
OmniFocus project before moving the task.

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

## Creating Folders and Single-Action List Projects

`ofctl add --project NAME` creates a regular parallel project when the named
project does not exist. It cannot create OmniFocus folders or set the
single-action list project type.

To create a folder inside another folder, or to create a project as a
single-action list, use `osascript -l JavaScript` (JXA) to create the
structure, then send OmniAutomation JavaScript via Apple Events to convert
the project type.

**Step 1 — create the folder and projects with JXA:**

```sh
osascript -l JavaScript << 'EOF'
var of = Application("OmniFocus");
var doc = of.defaultDocument;
var parentFolder = doc.folders.whose({name: "Work"})[0];

var newFolder = of.Folder({name: "Work Routines"});
parentFolder.folders.push(newFolder);

["Daily Work Routines", "Weekly Work Routines"].forEach(function(name) {
    var proj = of.Project({name: name});
    newFolder.projects.push(proj);
});
"Done";
EOF
```

**Step 2 — convert projects to single-action lists via OmniAutomation:**

The correct OmniAutomation property is `containsSingletonActions`. Setting
`project.singleton = true` reads back as true but does not change the project
type in the UI and should not be used.

```javascript
// Send this via Apple Events (OFOC/OFEJ) — see OmniAutomation.swift for the
// event format used by ofctl.
(() => {
    const names = ["Daily Work Routines", "Weekly Work Routines"];
    for (const name of names) {
        const proj = flattenedProjects.find(p => p.name === name);
        if (!proj) throw new Error(`Project not found: ${name}`);
        proj.sequential = false;
        proj.containsSingletonActions = true;
    }
    return "Done";
})()
```

A minimal Swift runner that sends OmniAutomation to OmniFocus using the same
`OFOC/OFEJ` Apple Event channel as `ofctl`:

```swift
import Foundation
import AppKit

func fourCharCode(_ s: String) -> UInt32 {
    s.utf8.reduce(UInt32(0)) { ($0 << 8) + UInt32($1) }
}

func runOmniJS(_ js: String) throws -> String {
    let app = NSRunningApplication
        .runningApplications(withBundleIdentifier: "com.omnigroup.OmniFocus4").first!
    let target = NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
    let event = NSAppleEventDescriptor(
        eventClass: fourCharCode("OFOC"), eventID: fourCharCode("OFEJ"),
        targetDescriptor: target,
        returnID: AEReturnID(kAutoGenerateReturnID),
        transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(NSAppleEventDescriptor(string: js),
                   forKeyword: AEKeyword(keyDirectObject))
    let reply = try event.sendEvent(options: [.waitForReply], timeout: 30)
    return reply.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue ?? ""
}

let script = """
(() => {
    const proj = flattenedProjects.find(p => p.name === "Weekly Work Routines");
    proj.sequential = false;
    proj.containsSingletonActions = true;
    return "Done";
})()
"""
print(try runOmniJS(script))
```

Save as `/tmp/fix.swift` and run with `swift /tmp/fix.swift`.

**Moving an existing project into a folder:**

Use OmniAutomation's `moveSections` — do not use JXA's `folder.projects.push(project)`, which
creates a blank untitled project at that position instead of moving the existing one.

```javascript
// OmniAutomation — moves project into folder correctly
(() => {
    const workFolder = flattenedFolders.find(f => f.name === "Work");
    const proj = flattenedProjects.find(p => p.name === "My Project");
    moveSections([proj], workFolder.ending);
    return proj.parentFolder ? proj.parentFolder.name : "moved";
})()
```

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
