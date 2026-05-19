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
        case tasks(TaskQuery)
        case add(AddTask)
        case update(UpdateTask)
    }

    public var command: Command
}

public struct TaskQuery: Equatable {
    public var tag: String?
    public var available: String?
    public var planned: String?
    public var deferred: String?
    public var due: String?
    public var includeCompleted: Bool
    public var includeDropped: Bool
    public var includeNotes: Bool
    public var limit: Int?
    public var format: OutputFormat
}

public struct AddTask: Equatable {
    public var name: String
    public var project: String?
    public var tags: [String]
    public var deferDate: String?
    public var plannedDate: String?
    public var dueDate: String?
    public var estimatedMinutes: Int?
    public var note: String?
    public var dryRun: Bool
}

public struct UpdateTask: Equatable {
    public var id: String
    public var name: String?
    public var project: String?
    public var tags: [String]
    public var clearTags: Bool
    public var deferDate: String??
    public var plannedDate: String??
    public var dueDate: String??
    public var estimatedMinutes: Int??
    public var note: String?
    public var dryRun: Bool
}

public enum OutputFormat: String, Equatable {
    case json
    case text
}

public enum CLI {
    public static let help = """
    ofctl - OmniFocus command-line bridge

    Usage:
      ofctl tasks [--tag NAME] [--available FILTER] [--planned FILTER] [--deferred FILTER] [--due FILTER] [--limit COUNT|--all] [--include-notes] [--include-completed] [--include-dropped] [--format json|text]
      ofctl add NAME [--project NAME] [--tag NAME] [--defer DATE] [--planned DATE] [--due DATE] [--duration MINUTES] [--note TEXT|--note-file PATH] [--dry-run]
      ofctl update TASK_ID [--name NAME] [--project NAME] [--tag NAME] [--clear-tags] [--defer DATE|none] [--planned DATE|none] [--due DATE|none] [--duration MINUTES|none] [--note TEXT|--note-file PATH] [--dry-run]

    Dates:
      Use ISO-like local dates: 2026-05-18 or 2026-05-18T09:00:00.
      Task date filters support: now, today, tomorrow, yesterday, none, before:DATE, after:DATE, on:YYYY-MM-DD.
      DATE can be now, today, tomorrow, yesterday, YYYY-MM-DD, or an ISO-like date/time.
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
        case "tasks":
            return try CommandLineOptions(command: .tasks(parseTaskQuery(args)))
        case "add":
            return try CommandLineOptions(command: .add(parseAddTask(args)))
        case "update":
            return try CommandLineOptions(command: .update(parseUpdateTask(args)))
        default:
            throw CLIError.usage("Unknown command: \(command)\n\n\(help)")
        }
    }

    private static func parseTaskQuery(_ args: [String]) throws -> TaskQuery {
        var parser = OptionParser(args)
        var query = TaskQuery(
            tag: nil,
            available: nil,
            planned: nil,
            deferred: nil,
            due: nil,
            includeCompleted: false,
            includeDropped: false,
            includeNotes: false,
            limit: 100,
            format: .json
        )

        while let arg = parser.next() {
            switch arg {
            case "--tag":
                query.tag = try parser.value(after: arg)
            case "--available":
                query.available = try parser.value(after: arg)
            case "--planned":
                query.planned = try parser.value(after: arg)
            case "--deferred":
                query.deferred = try parser.value(after: arg)
            case "--due":
                query.due = try parser.value(after: arg)
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

    private static func parseAddTask(_ args: [String]) throws -> AddTask {
        var parser = OptionParser(args)
        guard let name = parser.next(), !name.hasPrefix("--") else {
            throw CLIError.usage("add requires a task name\n\n\(help)")
        }

        var task = AddTask(
            name: name,
            project: nil,
            tags: [],
            deferDate: nil,
            plannedDate: nil,
            dueDate: nil,
            estimatedMinutes: nil,
            note: nil,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--project":
                task.project = try parser.value(after: arg)
            case "--tag":
                task.tags.append(try parser.value(after: arg))
            case "--defer":
                task.deferDate = try parser.value(after: arg)
            case "--planned":
                task.plannedDate = try parser.value(after: arg)
            case "--due":
                task.dueDate = try parser.value(after: arg)
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
            case "--dry-run":
                task.dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for add: \(arg)")
            }
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
            tags: [],
            clearTags: false,
            deferDate: nil,
            plannedDate: nil,
            dueDate: nil,
            estimatedMinutes: nil,
            note: nil,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--name":
                task.name = try parser.value(after: arg)
            case "--project":
                task.project = try parser.value(after: arg)
            case "--tag":
                task.tags.append(try parser.value(after: arg))
            case "--clear-tags":
                task.clearTags = true
            case "--defer":
                task.deferDate = .some(try nullableValue(after: arg, parser: &parser))
            case "--planned":
                task.plannedDate = .some(try nullableValue(after: arg, parser: &parser))
            case "--due":
                task.dueDate = .some(try nullableValue(after: arg, parser: &parser))
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
            case "--dry-run":
                task.dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for update: \(arg)")
            }
        }

        return task
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
