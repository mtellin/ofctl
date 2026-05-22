import Foundation

public enum CLIError: Error, CustomStringConvertible, Equatable {
    case usage(String)
    case automation(String)
    case invalidDate(String)

    public var description: String {
        switch self {
        case .usage(let message), .automation(let message), .invalidDate(let message):
            message
        }
    }
}

public struct CommandLineOptions: Equatable {
    public enum Command: Equatable {
        case help
        case perspectives(OutputFormat)
        case task(TaskLookup)
        case tasks(TaskQuery)
        case add(AddTask)
        case addGroup(AddTask)
        case update(UpdateTask)
        case projectStatus(UpdateProjectStatus)
    }

    public var command: Command
}

public struct TaskQuery: Equatable {
    public var perspective: String?
    public var project: String?
    public var folder: String?
    public var tags: [String]
    public var tagMode: TagMode
    public var flagged: Bool
    public var available: String?
    public var planned: String?
    public var deferred: String?
    public var due: String?
    public var repeatRule: String?
    public var completed: String?
    public var includeCompleted: Bool
    public var includeDropped: Bool
    public var includeNotes: Bool
    public var limit: Int?
    public var format: OutputFormat
}

public struct TaskLookup: Equatable {
    public var id: String
    public var includeNotes: Bool
    public var includeChildren: Bool
    public var format: OutputFormat
}

public struct AddTask: Equatable {
    public var name: String
    public var project: String?
    public var parent: String?
    public var tags: [String]
    public var deferDate: String?
    public var plannedDate: String?
    public var dueDate: String?
    public var repeatRule: String?
    public var repeatMethod: RepeatMethod?
    public var estimatedMinutes: Int?
    public var note: String?
    public var sequential: Bool?
    public var completedByChildren: Bool?
    public var actionGroup: Bool
    public var dryRun: Bool
}

public struct UpdateTask: Equatable {
    public var id: String
    public var name: String?
    public var project: String??
    public var addTags: [String]
    public var removeTags: [String]
    public var clearTags: Bool
    public var deferDate: String??
    public var plannedDate: String??
    public var dueDate: String??
    public var repeatRule: String??
    public var repeatMethod: RepeatMethod?
    public var estimatedMinutes: Int??
    public var note: String?
    public var sequential: Bool?
    public var completedByChildren: Bool?
    public var complete: Bool
    public var completedAt: String?
    public var incomplete: Bool
    public var drop: Bool
    public var dropAllOccurrences: Bool
    public var skip: Bool
    public var dryRun: Bool
}

public struct UpdateProjectStatus: Equatable {
    public var project: String
    public var status: ProjectStatus
    public var dryRun: Bool
}

public enum ProjectStatus: String, Equatable {
    case active
    case onHold = "on-hold"
    case completed
    case dropped
}

public enum OutputFormat: String, Equatable {
    case json
    case text
}

public enum TagMode: String, Equatable {
    case all
    case any
}

public enum RepeatMethod: String, Equatable {
    case fixed
    case due
    case `defer`
}

public enum CLI {
    public static let help = """
    ofctl - OmniFocus command-line bridge

    Usage:
      ofctl perspectives [--format json|text]
      ofctl task TASK_ID [--include-notes] [--include-children] [--format json|text]
      ofctl tasks [--perspective NAME] [--project NAME] [--folder NAME] [--tag NAME] [--tag-mode all|any] [--flagged] [--available FILTER] [--planned FILTER] [--deferred FILTER] [--due FILTER] [--repeat-rule any|none|RRULE] [--completed FILTER] [--limit COUNT|--all] [--include-notes] [--include-completed] [--include-dropped] [--format json|text]
      ofctl add NAME [--project NAME|--parent TASK_ID] [--tag NAME] [--defer DATE] [--planned DATE] [--due DATE] [--repeat-rule RRULE] [--repeat-method fixed|due|defer] [--duration MINUTES] [--note TEXT|--note-file PATH] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--dry-run]
      ofctl add-group NAME [--project NAME|--parent TASK_ID] [--tag NAME] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--defer DATE] [--planned DATE] [--due DATE] [--repeat-rule RRULE] [--repeat-method fixed|due|defer] [--duration MINUTES] [--note TEXT|--note-file PATH] [--dry-run]
      ofctl update TASK_ID [--name NAME] [--project NAME|none] [--tag NAME|--add-tag NAME] [--remove-tag NAME] [--clear-tags] [--defer DATE|none] [--planned DATE|none] [--due DATE|none] [--repeat-rule RRULE|none] [--repeat-method fixed|due|defer] [--duration MINUTES|none] [--note TEXT|--note-file PATH] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--complete] [--completed-at DATE] [--incomplete] [--drop] [--all-occurrences] [--skip] [--dry-run]
      ofctl project-status PROJECT_NAME --status active|on-hold|completed|dropped [--dry-run]

    Dates:
      Use ISO-like local dates: 2026-05-18 or 2026-05-18T09:00:00.
      Task date filters support: now, today, tomorrow, yesterday, none, before:DATE, after:DATE, on:YYYY-MM-DD.
      DATE can be now, today, tomorrow, yesterday, YYYY-MM-DD, or an ISO-like date/time.
      Task --project values create a top-level project when no project with that name exists.
      Task --tag values can be leaf names or paths like People/Alex Rivera and Status/Work 💼.
      Repeat rules are ICS RRULE strings such as FREQ=WEEKLY;INTERVAL=1.
    """

    public static func parse(_ arguments: [String]) throws -> CommandLineOptions {
        var args = Array(arguments.dropFirst())
        guard let command = args.first else {
            return CommandLineOptions(command: .help)
        }
        args.removeFirst()

        switch command {
        case "help", "--help", "-h":
            return CommandLineOptions(command: .help)
        case "perspectives":
            return try CommandLineOptions(command: .perspectives(parseFormatOnly(args, command: "perspectives")))
        case "task":
            return try CommandLineOptions(command: .task(parseTaskLookup(args)))
        case "tasks":
            return try CommandLineOptions(command: .tasks(parseTaskQuery(args)))
        case "add":
            return try CommandLineOptions(command: .add(parseAddTask(args, actionGroup: false)))
        case "add-group":
            return try CommandLineOptions(command: .addGroup(parseAddTask(args, actionGroup: true)))
        case "update":
            return try CommandLineOptions(command: .update(parseUpdateTask(args)))
        case "project-status":
            return try CommandLineOptions(command: .projectStatus(parseUpdateProjectStatus(args)))
        default:
            throw CLIError.usage("Unknown command: \(command)\n\n\(help)")
        }
    }

    private static func parseTaskQuery(_ args: [String]) throws -> TaskQuery {
        var parser = OptionParser(args)
        var query = TaskQuery(
            perspective: nil,
            project: nil,
            folder: nil,
            tags: [],
            tagMode: .all,
            flagged: false,
            available: nil,
            planned: nil,
            deferred: nil,
            due: nil,
            repeatRule: nil,
            completed: nil,
            includeCompleted: false,
            includeDropped: false,
            includeNotes: false,
            limit: 100,
            format: .json
        )

        while let arg = parser.next() {
            switch arg {
            case "--perspective":
                query.perspective = try parser.value(after: arg)
            case "--project":
                query.project = try parser.value(after: arg)
            case "--folder":
                query.folder = try parser.value(after: arg)
            case "--tag":
                query.tags.append(try parser.value(after: arg))
            case "--tag-mode":
                let value = try parser.value(after: arg)
                guard let tagMode = TagMode(rawValue: value) else {
                    throw CLIError.usage("Unsupported tag mode: \(value)")
                }
                query.tagMode = tagMode
            case "--flagged":
                query.flagged = true
            case "--available":
                query.available = try parser.value(after: arg)
            case "--planned":
                query.planned = try parser.value(after: arg)
            case "--deferred":
                query.deferred = try parser.value(after: arg)
            case "--due":
                query.due = try parser.value(after: arg)
            case "--repeat-rule":
                query.repeatRule = try parser.value(after: arg)
            case "--completed":
                query.completed = try parser.value(after: arg)
                query.includeCompleted = true
            case "--include-completed":
                query.includeCompleted = true
            case "--include-dropped":
                query.includeDropped = true
            case "--include-notes":
                query.includeNotes = true
            case "--limit":
                let value = try parser.value(after: arg)
                guard let limit = Int(value), limit > 0 else {
                    throw CLIError.usage("--limit must be a positive integer")
                }
                query.limit = limit
            case "--all":
                query.limit = nil
            case "--format":
                let value = try parser.value(after: arg)
                guard let format = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                query.format = format
            default:
                throw CLIError.usage("Unexpected argument for tasks: \(arg)")
            }
        }

        return query
    }

    private static func parseTaskLookup(_ args: [String]) throws -> TaskLookup {
        var parser = OptionParser(args)
        guard let id = parser.next(), !id.hasPrefix("--") else {
            throw CLIError.usage("task requires a task id\n\n\(help)")
        }

        var lookup = TaskLookup(id: id, includeNotes: false, includeChildren: false, format: .json)

        while let arg = parser.next() {
            switch arg {
            case "--include-notes":
                lookup.includeNotes = true
            case "--include-children":
                lookup.includeChildren = true
            case "--format":
                let value = try parser.value(after: arg)
                guard let format = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                lookup.format = format
            default:
                throw CLIError.usage("Unexpected argument for task: \(arg)")
            }
        }

        return lookup
    }

    private static func parseFormatOnly(_ args: [String], command: String) throws -> OutputFormat {
        var parser = OptionParser(args)
        var format = OutputFormat.json

        while let arg = parser.next() {
            switch arg {
            case "--format":
                let value = try parser.value(after: arg)
                guard let parsed = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                format = parsed
            default:
                throw CLIError.usage("Unexpected argument for \(command): \(arg)")
            }
        }

        return format
    }

    private static func parseAddTask(_ args: [String], actionGroup: Bool) throws -> AddTask {
        var parser = OptionParser(args)
        guard let name = parser.next(), !name.hasPrefix("--") else {
            throw CLIError.usage("add requires a task name\n\n\(help)")
        }

        var task = AddTask(
            name: name,
            project: nil,
            parent: nil,
            tags: [],
            deferDate: nil,
            plannedDate: nil,
            dueDate: nil,
            repeatRule: nil,
            repeatMethod: nil,
            estimatedMinutes: nil,
            note: nil,
            sequential: actionGroup ? false : nil,
            completedByChildren: actionGroup ? false : nil,
            actionGroup: actionGroup,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--project":
                task.project = try parser.value(after: arg)
            case "--parent":
                task.parent = try parser.value(after: arg)
            case "--tag":
                task.tags.append(try parser.value(after: arg))
            case "--defer":
                task.deferDate = try parser.value(after: arg)
            case "--planned":
                task.plannedDate = try parser.value(after: arg)
            case "--due":
                task.dueDate = try parser.value(after: arg)
            case "--repeat-rule":
                task.repeatRule = try parser.value(after: arg)
            case "--repeat-method":
                task.repeatMethod = try parseRepeatMethod(try parser.value(after: arg))
            case "--duration":
                let value = try parser.value(after: arg)
                guard let minutes = Int(value), minutes >= 0 else {
                    throw CLIError.usage("--duration must be a non-negative integer")
                }
                task.estimatedMinutes = minutes
            case "--note":
                task.note = try parser.value(after: arg)
            case "--note-file":
                task.note = try readNoteFile(try parser.value(after: arg))
            case "--sequential":
                task.sequential = true
                task.actionGroup = true
            case "--parallel":
                task.sequential = false
                task.actionGroup = true
            case "--complete-with-children":
                task.completedByChildren = true
                task.actionGroup = true
            case "--no-complete-with-children":
                task.completedByChildren = false
                task.actionGroup = true
            case "--dry-run":
                task.dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for add: \(arg)")
            }
        }

        if task.project != nil && task.parent != nil {
            throw CLIError.usage("--project and --parent cannot be used together")
        }
        if task.repeatMethod != nil && task.repeatRule == nil {
            throw CLIError.usage("--repeat-method requires --repeat-rule")
        }

        return task
    }

    private static func parseUpdateTask(_ args: [String]) throws -> UpdateTask {
        var parser = OptionParser(args)
        guard let id = parser.next(), !id.hasPrefix("--") else {
            throw CLIError.usage("update requires a task id\n\n\(help)")
        }

        var task = UpdateTask(
            id: id,
            name: nil,
            project: nil,
            addTags: [],
            removeTags: [],
            clearTags: false,
            deferDate: nil,
            plannedDate: nil,
            dueDate: nil,
            repeatRule: nil,
            repeatMethod: nil,
            estimatedMinutes: nil,
            note: nil,
            sequential: nil,
            completedByChildren: nil,
            complete: false,
            completedAt: nil,
            incomplete: false,
            drop: false,
            dropAllOccurrences: false,
            skip: false,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--name":
                task.name = try parser.value(after: arg)
            case "--project":
                task.project = .some(try nullableValue(after: arg, parser: &parser))
            case "--tag", "--add-tag":
                task.addTags.append(try parser.value(after: arg))
            case "--remove-tag":
                task.removeTags.append(try parser.value(after: arg))
            case "--clear-tags":
                task.clearTags = true
            case "--defer":
                task.deferDate = .some(try nullableValue(after: arg, parser: &parser))
            case "--planned":
                task.plannedDate = .some(try nullableValue(after: arg, parser: &parser))
            case "--due":
                task.dueDate = .some(try nullableValue(after: arg, parser: &parser))
            case "--repeat-rule":
                task.repeatRule = .some(try nullableValue(after: arg, parser: &parser))
            case "--repeat-method":
                task.repeatMethod = try parseRepeatMethod(try parser.value(after: arg))
            case "--duration":
                let value = try parser.value(after: arg)
                if value == "none" {
                    task.estimatedMinutes = .some(nil)
                } else if let minutes = Int(value), minutes >= 0 {
                    task.estimatedMinutes = .some(minutes)
                } else {
                    throw CLIError.usage("--duration must be a non-negative integer or none")
                }
            case "--note":
                task.note = try parser.value(after: arg)
            case "--note-file":
                task.note = try readNoteFile(try parser.value(after: arg))
            case "--sequential":
                task.sequential = true
            case "--parallel":
                task.sequential = false
            case "--complete-with-children":
                task.completedByChildren = true
            case "--no-complete-with-children":
                task.completedByChildren = false
            case "--complete":
                task.complete = true
            case "--completed-at":
                task.complete = true
                task.completedAt = try parser.value(after: arg)
            case "--incomplete":
                task.incomplete = true
            case "--drop":
                task.drop = true
            case "--all-occurrences":
                task.dropAllOccurrences = true
            case "--skip":
                task.skip = true
            case "--dry-run":
                task.dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for update: \(arg)")
            }
        }

        if task.complete && task.incomplete {
            throw CLIError.usage("--complete and --incomplete cannot be used together")
        }
        if task.drop && task.skip {
            throw CLIError.usage("--drop and --skip cannot be used together")
        }
        if task.dropAllOccurrences && !task.drop {
            throw CLIError.usage("--all-occurrences requires --drop")
        }
        if task.repeatMethod != nil && task.repeatRule == nil {
            throw CLIError.usage("--repeat-method requires --repeat-rule")
        }

        return task
    }

    private static func parseRepeatMethod(_ value: String) throws -> RepeatMethod {
        guard let method = RepeatMethod(rawValue: value) else {
            throw CLIError.usage("Unsupported repeat method: \(value)")
        }
        return method
    }

    private static func parseUpdateProjectStatus(_ args: [String]) throws -> UpdateProjectStatus {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-status requires a project name\n\n\(help)")
        }

        var status: ProjectStatus?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--status":
                let value = try parser.value(after: arg)
                guard let parsed = ProjectStatus(rawValue: value) else {
                    throw CLIError.usage("Unsupported project status: \(value)")
                }
                status = parsed
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-status: \(arg)")
            }
        }

        guard let status else {
            throw CLIError.usage("project-status requires --status active|on-hold|completed|dropped")
        }

        return UpdateProjectStatus(project: project, status: status, dryRun: dryRun)
    }

    private static func nullableValue(after option: String, parser: inout OptionParser) throws -> String? {
        let value = try parser.value(after: option)
        return value == "none" ? nil : value
    }

    private static func readNoteFile(_ path: String) throws -> String {
        do {
            return try String(contentsOfFile: NSString(string: path).expandingTildeInPath, encoding: .utf8)
        } catch {
            throw CLIError.usage("Could not read note file \(path): \(error.localizedDescription)")
        }
    }
}

private struct OptionParser {
    private var args: [String]
    private var index = 0

    init(_ args: [String]) {
        self.args = args
    }

    mutating func next() -> String? {
        guard index < args.count else { return nil }
        defer { index += 1 }
        return args[index]
    }

    mutating func value(after option: String) throws -> String {
        guard let value = next(), !value.hasPrefix("--") else {
            throw CLIError.usage("\(option) requires a value")
        }
        return value
    }
}
