# ofctl — Contributor Guide

ofctl is a Swift CLI that bridges to OmniFocus 4 via OmniJS (OmniAutomation) sent
over a raw Apple Event. It has no external dependencies, targets macOS 14+, and
uses Swift 6. All argument parsing is hand-rolled.

## Documentation Rule

**Every feature add, change, or removal must update documentation in the same
change.** This repo has three independent documentation surfaces that must stay in
sync:

| File | What to update |
|---|---|
| `README.md` | "Current Commands" list (`README.md:176`); add/update a Quick Start example for any new command |
| `docs/user-guide.md` | Add or update the relevant command section with usage examples |
| `docs/claude-integration.md` | Update when the change affects how a client/Claude should call ofctl — e.g. new read commands belong in "Recommended Claude Commands" |

Additionally:
- Keep the `help` string in `Sources/OFCTLCore/CLI.swift` (around line 131) in sync
  with docs — it is the authoritative usage reference.
- Add or update a parser test in `Tests/ofctlTests/ofctlTests.swift` for every new
  or modified command flag.

## Architecture

```
Sources/
  ofctl/
    ofctl.swift           @main — parses args, builds OmniFocusClient, switches on
                          command, formats output (text vs JSON)
  OFCTLCore/
    CLI.swift             Hand-rolled arg parsing: OptionParser, CLI.parse,
                          the Command enum, per-command input structs, help text
    OmniFocusClient.swift Command implementations + OmniJavaScript enum with
                          string-templated OmniJS scripts and serialization helpers
    OmniAutomation.swift  OmniJavaScriptRunner: sends OmniJS source as an Apple Event
                          (OFOC/OFEJ), auto-launches OmniFocus, reads back JSON reply
Tests/
  ofctlTests/
    ofctlTests.swift      swift-testing (@Test), covers arg parsing and privacy scope
```

The round-trip for any command: `CLI.parse` → command-specific input struct →
`OmniFocusClient` method → `OmniJavaScriptRunner.run(script:)` → JSON reply →
formatted output.

OmniFocus target defaults to `com.omnigroup.OmniFocus4` / `/Applications/OmniFocus.app`.
Override with env vars `OFCTL_OMNIFOCUS_BUNDLE_ID`, `OFCTL_OMNIFOCUS_APP_NAME`, or
`OFCTL_OMNIFOCUS_APP_PATH`.

## Build, Test, Run

```sh
# Build (debug)
swift build

# Build release binary → .build/release/ofctl
swift build -c release --product ofctl

# Run tests
swift test

# Run from source
swift run ofctl tasks --available now --limit 10 --format text
```

## Conventions

- **No external dependencies.** `Package.swift` is dependency-free; keep it that way.
- **Swift 6 language mode, macOS 14+ minimum.**
- **Default output is JSON.** `--format text` is the human-readable alternative.
  New commands should support both where it makes sense.
- **Privacy scope.** Any new read or write command must respect `OFCTL_WORK_HOSTNAMES`
  the same way existing commands do. See the privacy-scope tests at
  `Tests/ofctlTests/ofctlTests.swift:509` for the expected behavior.
- **Dry-run for mutations.** Any new mutating command (`add`-*, `update`, etc.) must
  support `--dry-run`, consistent with existing mutating commands.
- **Task conventions.** Consult `docs/task-conventions.md` for the project's tag
  taxonomy, date semantics, and duration conventions before adding fields that touch
  those areas.

## Documentation Files

- [`README.md`](README.md) — Quick start, current command surface, build instructions
- [`docs/user-guide.md`](docs/user-guide.md) — Full usage guide with examples
- [`docs/claude-integration.md`](docs/claude-integration.md) — How Claude should call
  ofctl: preferred workflows, safety guidelines, recommended commands
- [`docs/task-conventions.md`](docs/task-conventions.md) — Tag taxonomy, date and
  duration conventions, project structure
