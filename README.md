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
- Inspect planned, due, deferred, and available work.
- Add tasks from Claude workflows without using OmniFocus UI automation directly.
- Update task metadata such as project, tags, dates, duration, and notes.
- Convert Markdown notes to OmniFocus rich text on write.
- Convert OmniFocus rich notes back to Markdown on read.
- Keep Claude-facing automation narrow enough to be acceptable on machines where
  an MCP server cannot be installed.

## Design Goals

- Native macOS tooling: Swift CLI plus OmniFocus automation.
- Minimal command surface: explicit commands instead of arbitrary app control.
- Claude-friendly output: JSON by default, text output for quick terminal checks.
- Safe defaults: list queries omit rich notes unless requested.
- GTD-friendly semantics: person tags, waiting-on tags, project context, planned
  dates, due dates, defer availability, and estimated duration are first-class.

## Requirements

- macOS
- OmniFocus 4.7+ with the database migrated for Planned Dates
- Swift toolchain
- macOS Automation permission for `ofctl`/`osascript` to control OmniFocus

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

Add a waiting-on task:

```sh
ofctl add "Ask Alex for project status" \
  --project "Work Follow-ups" \
  --tag "Alex Rivera" \
  --tag "Waiting On" \
  --tag "Work" \
  --note "Waiting on Alex Rivera."
```

Dry-run any write first:

```sh
ofctl add "Ask Taylor about launch date" --tag "Taylor Morgan" --dry-run
```

## Documentation

- [User Guide](docs/user-guide.md): complete command reference and examples.
- [Claude Integration](docs/claude-integration.md): how Claude Code should use
  `ofctl` in place of an MCP server.
- [Task Conventions](docs/task-conventions.md): recommended tags, dates,
  waiting-on behavior, and Markdown note handling.

## Current Commands

- `ofctl tasks`: query tasks by tag, availability, planned date, defer date, due
  date, completion/dropped state, and output format.
- `ofctl add`: create a task with project, tags, defer/planned/due dates,
  duration, and Markdown notes.
- `ofctl update`: update task name, project, tags, dates, duration, and notes.

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
