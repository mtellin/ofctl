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
        case taskRename(RenameTask)
        case taskMove(MoveTasks)
        case projectStatus(UpdateProjectStatus)
        case projectMove(MoveProject)
        case projectRename(RenameProject)
        case projectNote(UpdateProjectNote)
        case projectCompletion(UpdateProjectCompletion)
        case projectCreate(CreateProject)
        case folderCreate(CreateFolder)
        case tags(TagsQuery)
        case tagCreate(CreateTag)
        case tagRename(RenameTag)
        case tagDelete(DeleteTag)
        case tagMove(MoveTag)
        case taskDelete(DeleteTasks)
        case projectDelete(DeleteProject)
        case projects(ProjectsQuery)
        case projectReview(UpdateProjectReview)
        case taskState(StateMutation)
        case projectState(StateMutation)
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
    public var folder: String?
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
    public var flagged: Bool?
    public var actionGroup: Bool
    public var dryRun: Bool
    public var format: OutputFormat

    public init(
        name: String,
        project: String? = nil,
        folder: String? = nil,
        parent: String? = nil,
        tags: [String] = [],
        deferDate: String? = nil,
        plannedDate: String? = nil,
        dueDate: String? = nil,
        repeatRule: String? = nil,
        repeatMethod: RepeatMethod? = nil,
        estimatedMinutes: Int? = nil,
        note: String? = nil,
        sequential: Bool? = nil,
        completedByChildren: Bool? = nil,
        flagged: Bool? = nil,
        actionGroup: Bool = false,
        dryRun: Bool = false,
        format: OutputFormat = .json
    ) {
        self.name = name
        self.project = project
        self.folder = folder
        self.parent = parent
        self.tags = tags
        self.deferDate = deferDate
        self.plannedDate = plannedDate
        self.dueDate = dueDate
        self.repeatRule = repeatRule
        self.repeatMethod = repeatMethod
        self.estimatedMinutes = estimatedMinutes
        self.note = note
        self.sequential = sequential
        self.completedByChildren = completedByChildren
        self.flagged = flagged
        self.actionGroup = actionGroup
        self.dryRun = dryRun
        self.format = format
    }
}

public struct UpdateTask: Equatable {
    public var ids: [String]
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
    public var flagged: Bool?
    public var createProjectIfMissing: Bool = true
    public var folder: String? = nil
    public var dryRun: Bool
    public var format: OutputFormat = .json
}

public struct RenameTask: Equatable {
    public var id: String
    public var newName: String
    public var dryRun: Bool
}

public struct UpdateProjectStatus: Equatable {
    public var project: String
    public var status: ProjectStatus
    public var dryRun: Bool
}

public struct MoveProject: Equatable {
    public var project: String
    public var folder: String?  // nil = move to library top level (--to-folder none)
    public var dryRun: Bool
}

public struct RenameProject: Equatable {
    public var project: String
    public var newName: String
    public var dryRun: Bool
}

public enum ProjectNoteMode: String, Equatable {
    case set
    case prepend
    case clear
}

/// Set, prepend to, or clear a project's freeform note. The trailing
/// `=== ofctl-state ===` block (if any) is always preserved — only the freeform
/// region above it is affected. `project` may be a name or a primary-key id.
public struct UpdateProjectNote: Equatable {
    public var project: String
    public var mode: ProjectNoteMode
    public var text: String
    public var dryRun: Bool
}

public struct UpdateProjectCompletion: Equatable {
    public var project: String
    public var completeWithLastAction: Bool
    public var dryRun: Bool
}

public struct MoveTasks: Equatable {
    public var ids: [String]
    public var destination: TaskMoveDestination
    public var position: TaskMovePosition
    public var dryRun: Bool
}

public enum TaskMoveDestination: Equatable {
    case before(String)
    case after(String)
    case project(String)
    case parent(String)
    case inbox
}

public enum TaskMovePosition: String, Equatable {
    case beginning
    case ending
}

public struct CreateProject: Equatable {
    public var name: String
    public var folder: String?
    public var singleton: Bool
    public var onHold: Bool
    public var dryRun: Bool
}

public struct CreateFolder: Equatable {
    public var name: String
    public var parent: String?
    public var dryRun: Bool
}

public struct TagsQuery: Equatable {
    public var format: OutputFormat
}

public struct CreateTag: Equatable {
    public var name: String
    public var parent: String?
    public var dryRun: Bool
}

public struct RenameTag: Equatable {
    public var tag: String
    public var newName: String
    public var dryRun: Bool
}

public struct DeleteTag: Equatable {
    public var tag: String
    public var dryRun: Bool
}

public struct MoveTag: Equatable {
    public var tag: String
    public var newParent: String?
    public var dryRun: Bool
}

public struct DeleteTasks: Equatable {
    public var ids: [String]
    public var dryRun: Bool
}

public struct DeleteProject: Equatable {
    public var project: String
    public var dryRun: Bool
}

public struct ProjectsQuery: Equatable {
    public var folder: String?
    public var status: ProjectStatus?
    public var dueForReview: Bool
    public var limit: Int?
    public var format: OutputFormat
    public var includeNotes: Bool = false
}

public struct UpdateProjectReview: Equatable {
    public var project: String
    public var markReviewed: Bool
    public var interval: String??
    public var nextReview: String? = nil
    public var dryRun: Bool
}

public struct StateAssignment: Equatable {
    public var key: String
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// Read or merge the delimited `=== ofctl-state ===` key/value block inside a
/// task or project note. `identifier` is a task id for `task-state` and a project
/// name for `project-state`. Exactly one mode is used per invocation: `get` (read)
/// or a mutation (`sets`/`increments`/`clearKeys`/`clearAll`).
public struct StateMutation: Equatable {
    public var identifier: String
    public var get: Bool
    public var sets: [StateAssignment]
    public var increments: [String]
    public var clearKeys: [String]
    public var clearAll: Bool
    public var format: OutputFormat
    public var dryRun: Bool

    public init(
        identifier: String,
        get: Bool = false,
        sets: [StateAssignment] = [],
        increments: [String] = [],
        clearKeys: [String] = [],
        clearAll: Bool = false,
        format: OutputFormat = .json,
        dryRun: Bool = false
    ) {
        self.identifier = identifier
        self.get = get
        self.sets = sets
        self.increments = increments
        self.clearKeys = clearKeys
        self.clearAll = clearAll
        self.format = format
        self.dryRun = dryRun
    }
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
      ofctl add NAME [--project NAME [--folder FOLDER_PATH]|--parent TASK_ID] [--tag NAME] [--defer DATE] [--planned DATE] [--due DATE] [--repeat-rule RRULE] [--repeat-method fixed|due|defer] [--duration MINUTES] [--note TEXT|--note-file PATH] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--flag|--no-flag] [--dry-run] [--format json|text]
      ofctl add-group NAME [--project NAME [--folder FOLDER_PATH]|--parent TASK_ID] [--tag NAME] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--defer DATE] [--planned DATE] [--due DATE] [--repeat-rule RRULE] [--repeat-method fixed|due|defer] [--duration MINUTES] [--note TEXT|--note-file PATH] [--flag|--no-flag] [--dry-run] [--format json|text]
      ofctl update TASK_ID [TASK_ID ...] [--name NAME] [--project NAME|none [--folder FOLDER_PATH]] [--no-create-project] [--tag NAME|--add-tag NAME] [--remove-tag NAME] [--clear-tags] [--defer DATE|none] [--planned DATE|none] [--due DATE|none] [--repeat-rule RRULE|none] [--repeat-method fixed|due|defer] [--duration MINUTES|none] [--note TEXT|--note-file PATH] [--sequential|--parallel] [--complete-with-children|--no-complete-with-children] [--complete] [--completed-at DATE] [--incomplete] [--flag|--no-flag] [--drop] [--all-occurrences] [--skip] [--dry-run] [--format json|text]
      ofctl task-rename TASK_ID --to NEW_NAME [--dry-run]
      ofctl task-move TASK_ID [TASK_ID ...] (--before TASK_ID|--after TASK_ID|--project NAME|--parent TASK_ID|--inbox) [--position beginning|ending] [--dry-run]
      ofctl project-status PROJECT_NAME --status active|on-hold|completed|dropped [--dry-run]
      ofctl project-move PROJECT_NAME --to-folder FOLDER_NAME|none [--dry-run]
      ofctl project-rename PROJECT_NAME --to NEW_NAME [--dry-run]
      ofctl project-note PROJECT_NAME_OR_ID (--note TEXT|--note-file PATH|--prepend TEXT|--note none) [--dry-run]
      ofctl project-completion PROJECT_NAME (--complete-with-last-action|--no-complete-with-last-action) [--dry-run]
      ofctl project-create NAME [--folder FOLDER_NAME] [--singleton] [--on-hold] [--dry-run]
      ofctl folder-create NAME [--parent FOLDER_PATH] [--dry-run]
      ofctl tags [--format json|text]
      ofctl tag-create NAME [--parent TAG_PATH] [--dry-run]
      ofctl tag-rename TAG_PATH --to NEW_NAME [--dry-run]
      ofctl tag-delete TAG_PATH [--dry-run]
      ofctl tag-move TAG_PATH --to-parent TAG_PATH|none [--dry-run]
      ofctl task-delete TASK_ID [TASK_ID ...] [--dry-run]
      ofctl project-delete PROJECT_NAME [--dry-run]
      ofctl projects [--folder NAME] [--status active|on-hold|completed|dropped] [--due-for-review] [--limit COUNT|--all] [--include-notes] [--format json|text]
      ofctl project-review PROJECT_NAME [--mark-reviewed] [--interval SPEC] [--next-review DATE] [--dry-run]
      ofctl task-state TASK_ID (--get | [--set KEY=VALUE ...] [--increment KEY ...] [--clear-key KEY ...] | --clear) [--format json|text] [--dry-run]
      ofctl project-state PROJECT_NAME (--get | [--set KEY=VALUE ...] [--increment KEY ...] [--clear-key KEY ...] | --clear) [--format json|text] [--dry-run]

    Note state block:
      task-state and project-state read or merge a delimited "=== ofctl-state ===" block at the end of
      a note (key: value lines) without disturbing the freeform note content above it. Use --get to
      read the parsed block, --set/--increment/--clear-key to merge, and --clear to remove the block.

    Dates:
      Use ISO-like local dates: 2026-05-18 or 2026-05-18T09:00:00.
      Task date filters support: all, now, today, tomorrow, yesterday, none, before:DATE, after:DATE, on:YYYY-MM-DD.
      DATE can be now, today, tomorrow, yesterday, YYYY-MM-DD, or an ISO-like date/time.
      Task --project values create a top-level project when no project with that name exists; use update --no-create-project to require an existing project.
      Add --folder FOLDER_PATH to create or target a project inside a folder when adding or updating tasks. Within a privacy scope that allows exactly one folder, update creates new projects in that folder automatically.
      Project arguments (--project and the PROJECT_NAME positional on project-* commands) match by exact name across all folders, then fall back to a primary-key id. Pass an id to target one project unambiguously — e.g. a dropped project that shares a name with an active one (name always resolves to the active twin).
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
        case "task-rename":
            return try CommandLineOptions(command: .taskRename(parseRenameTask(args)))
        case "task-move":
            return try CommandLineOptions(command: .taskMove(parseMoveTasks(args)))
        case "project-status":
            return try CommandLineOptions(command: .projectStatus(parseUpdateProjectStatus(args)))
        case "project-move":
            return try CommandLineOptions(command: .projectMove(parseMoveProject(args)))
        case "project-rename":
            return try CommandLineOptions(command: .projectRename(parseRenameProject(args)))
        case "project-note":
            return try CommandLineOptions(command: .projectNote(parseProjectNote(args)))
        case "project-completion":
            return try CommandLineOptions(command: .projectCompletion(parseUpdateProjectCompletion(args)))
        case "project-create":
            return try CommandLineOptions(command: .projectCreate(parseCreateProject(args)))
        case "folder-create":
            return try CommandLineOptions(command: .folderCreate(parseCreateFolder(args)))
        case "tags":
            return CommandLineOptions(command: .tags(TagsQuery(format: try parseFormatOnly(args, command: "tags"))))
        case "tag-create":
            return try CommandLineOptions(command: .tagCreate(parseCreateTag(args)))
        case "tag-rename":
            return try CommandLineOptions(command: .tagRename(parseRenameTag(args)))
        case "tag-delete":
            return try CommandLineOptions(command: .tagDelete(parseDeleteTag(args)))
        case "tag-move":
            return try CommandLineOptions(command: .tagMove(parseMoveTag(args)))
        case "task-delete":
            return try CommandLineOptions(command: .taskDelete(parseDeleteTasks(args)))
        case "project-delete":
            return try CommandLineOptions(command: .projectDelete(parseDeleteProject(args)))
        case "projects":
            return try CommandLineOptions(command: .projects(parseProjectsQuery(args)))
        case "project-review":
            return try CommandLineOptions(command: .projectReview(parseUpdateProjectReview(args)))
        case "task-state":
            return try CommandLineOptions(command: .taskState(parseStateMutation(args, command: "task-state")))
        case "project-state":
            return try CommandLineOptions(command: .projectState(parseStateMutation(args, command: "project-state")))
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
            folder: nil,
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
            flagged: nil,
            actionGroup: actionGroup,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--project":
                task.project = try parser.value(after: arg)
            case "--folder":
                task.folder = try parser.value(after: arg)
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
            case "--flag":
                task.flagged = true
            case "--no-flag":
                task.flagged = false
            case "--dry-run":
                task.dryRun = true
            case "--format":
                let value = try parser.value(after: arg)
                guard let format = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                task.format = format
            default:
                throw CLIError.usage("Unexpected argument for add: \(arg)")
            }
        }

        if task.project != nil && task.parent != nil {
            throw CLIError.usage("--project and --parent cannot be used together")
        }
        if task.folder != nil && task.project == nil {
            throw CLIError.usage("--folder requires --project")
        }
        if task.repeatMethod != nil && task.repeatRule == nil {
            throw CLIError.usage("--repeat-method requires --repeat-rule")
        }

        return task
    }

    private static func parseUpdateTask(_ args: [String]) throws -> UpdateTask {
        var parser = OptionParser(args)
        var ids: [String] = []

        while let arg = parser.peek(), !arg.hasPrefix("--") {
            _ = parser.next()
            ids.append(arg)
        }

        guard !ids.isEmpty else {
            throw CLIError.usage("update requires at least one task id\n\n\(help)")
        }

        var task = UpdateTask(
            ids: ids,
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
            flagged: nil,
            dryRun: false
        )

        while let arg = parser.next() {
            switch arg {
            case "--name":
                task.name = try parser.value(after: arg)
            case "--project":
                task.project = .some(try nullableValue(after: arg, parser: &parser))
            case "--no-create-project":
                task.createProjectIfMissing = false
            case "--folder":
                task.folder = try parser.value(after: arg)
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
            case "--flag":
                task.flagged = true
            case "--no-flag":
                task.flagged = false
            case "--dry-run":
                task.dryRun = true
            case "--format":
                let value = try parser.value(after: arg)
                guard let format = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                task.format = format
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
        if task.folder != nil && task.project == nil {
            throw CLIError.usage("--folder requires --project")
        }

        return task
    }

    private static func parseRepeatMethod(_ value: String) throws -> RepeatMethod {
        guard let method = RepeatMethod(rawValue: value) else {
            throw CLIError.usage("Unsupported repeat method: \(value)")
        }
        return method
    }

    private static func parseMoveTasks(_ args: [String]) throws -> MoveTasks {
        var parser = OptionParser(args)
        var ids: [String] = []

        while let arg = parser.peek(), !arg.hasPrefix("--") {
            _ = parser.next()
            ids.append(arg)
        }

        guard !ids.isEmpty else {
            throw CLIError.usage("task-move requires at least one task id\n\n\(help)")
        }

        var destination: TaskMoveDestination?
        var position = TaskMovePosition.ending
        var positionWasSet = false
        var dryRun = false

        func setDestination(_ next: TaskMoveDestination) throws {
            guard destination == nil else {
                throw CLIError.usage("task-move accepts exactly one destination option")
            }
            destination = next
        }

        while let arg = parser.next() {
            switch arg {
            case "--before":
                try setDestination(.before(try parser.value(after: arg)))
            case "--after":
                try setDestination(.after(try parser.value(after: arg)))
            case "--project":
                try setDestination(.project(try parser.value(after: arg)))
            case "--parent":
                try setDestination(.parent(try parser.value(after: arg)))
            case "--inbox":
                try setDestination(.inbox)
            case "--position":
                let value = try parser.value(after: arg)
                guard let parsed = TaskMovePosition(rawValue: value) else {
                    throw CLIError.usage("Unsupported task-move position: \(value)")
                }
                position = parsed
                positionWasSet = true
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for task-move: \(arg)")
            }
        }

        guard let destination else {
            throw CLIError.usage("task-move requires --before, --after, --project, --parent, or --inbox")
        }

        if positionWasSet {
            switch destination {
            case .before, .after:
                throw CLIError.usage("--position can only be used with --project, --parent, or --inbox")
            case .project, .parent, .inbox:
                break
            }
        }

        return MoveTasks(ids: ids, destination: destination, position: position, dryRun: dryRun)
    }

    private static func parseRenameTask(_ args: [String]) throws -> RenameTask {
        var parser = OptionParser(args)
        guard let id = parser.next(), !id.hasPrefix("--") else {
            throw CLIError.usage("task-rename requires a task id\n\n\(help)")
        }

        var newName: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--to":
                newName = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for task-rename: \(arg)")
            }
        }

        guard let newName else {
            throw CLIError.usage("task-rename requires --to NEW_NAME")
        }

        return RenameTask(id: id, newName: newName, dryRun: dryRun)
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

    private static func parseMoveProject(_ args: [String]) throws -> MoveProject {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-move requires a project name\n\n\(help)")
        }

        var folder: String??
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--to-folder":
                folder = .some(try nullableValue(after: arg, parser: &parser))
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-move: \(arg)")
            }
        }

        guard let folder else {
            throw CLIError.usage("project-move requires --to-folder FOLDER_NAME|none")
        }

        return MoveProject(project: project, folder: folder, dryRun: dryRun)
    }

    private static func parseRenameProject(_ args: [String]) throws -> RenameProject {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-rename requires a project name\n\n\(help)")
        }

        var newName: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--to":
                newName = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-rename: \(arg)")
            }
        }

        guard let newName else {
            throw CLIError.usage("project-rename requires --to NEW_NAME")
        }

        return RenameProject(project: project, newName: newName, dryRun: dryRun)
    }

    private static func parseProjectNote(_ args: [String]) throws -> UpdateProjectNote {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-note requires a project name or id\n\n\(help)")
        }

        var mode: ProjectNoteMode?
        var text = ""
        var dryRun = false

        func setOperation(_ newMode: ProjectNoteMode, _ value: String) throws {
            guard mode == nil else {
                throw CLIError.usage("project-note accepts exactly one of --note, --note-file, or --prepend")
            }
            mode = newMode
            text = value
        }

        while let arg = parser.next() {
            switch arg {
            case "--note":
                let value = try parser.value(after: arg)
                if value == "none" {
                    try setOperation(.clear, "")
                } else {
                    try setOperation(.set, value)
                }
            case "--note-file":
                try setOperation(.set, try readNoteFile(try parser.value(after: arg)))
            case "--prepend":
                try setOperation(.prepend, try parser.value(after: arg))
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-note: \(arg)")
            }
        }

        guard let mode else {
            throw CLIError.usage("project-note requires one of --note TEXT, --note-file PATH, --prepend TEXT, or --note none")
        }

        return UpdateProjectNote(project: project, mode: mode, text: text, dryRun: dryRun)
    }

    private static func parseUpdateProjectCompletion(_ args: [String]) throws -> UpdateProjectCompletion {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-completion requires a project name\n\n\(help)")
        }

        var completeWithLastAction: Bool?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--complete-with-last-action", "--complete-with-children":
                completeWithLastAction = true
            case "--no-complete-with-last-action", "--no-complete-with-children":
                completeWithLastAction = false
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-completion: \(arg)")
            }
        }

        guard let completeWithLastAction else {
            throw CLIError.usage("project-completion requires --complete-with-last-action or --no-complete-with-last-action")
        }

        return UpdateProjectCompletion(project: project, completeWithLastAction: completeWithLastAction, dryRun: dryRun)
    }

    private static func parseCreateProject(_ args: [String]) throws -> CreateProject {
        var parser = OptionParser(args)
        guard let name = parser.next(), !name.hasPrefix("--") else {
            throw CLIError.usage("project-create requires a project name\n\n\(help)")
        }

        var folder: String?
        var singleton = false
        var onHold = false
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--folder":
                folder = try parser.value(after: arg)
            case "--singleton":
                singleton = true
            case "--on-hold":
                onHold = true
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-create: \(arg)")
            }
        }

        return CreateProject(name: name, folder: folder, singleton: singleton, onHold: onHold, dryRun: dryRun)
    }

    private static func parseProjectsQuery(_ args: [String]) throws -> ProjectsQuery {
        var parser = OptionParser(args)
        var query = ProjectsQuery(
            folder: nil,
            status: nil,
            dueForReview: false,
            limit: 100,
            format: .json
        )

        while let arg = parser.next() {
            switch arg {
            case "--folder":
                query.folder = try parser.value(after: arg)
            case "--status":
                let value = try parser.value(after: arg)
                guard let status = ProjectStatus(rawValue: value) else {
                    throw CLIError.usage("Unsupported project status: \(value)")
                }
                query.status = status
            case "--due-for-review":
                query.dueForReview = true
            case "--limit":
                let value = try parser.value(after: arg)
                guard let limit = Int(value), limit > 0 else {
                    throw CLIError.usage("--limit must be a positive integer")
                }
                query.limit = limit
            case "--all":
                query.limit = nil
            case "--include-notes":
                query.includeNotes = true
            case "--format":
                let value = try parser.value(after: arg)
                guard let format = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                query.format = format
            default:
                throw CLIError.usage("Unexpected argument for projects: \(arg)")
            }
        }

        return query
    }

    private static func parseUpdateProjectReview(_ args: [String]) throws -> UpdateProjectReview {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-review requires a project name\n\n\(help)")
        }

        var markReviewed = false
        var interval: String??
        var nextReview: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--mark-reviewed":
                markReviewed = true
            case "--interval":
                interval = .some(try nullableValue(after: arg, parser: &parser))
            case "--next-review":
                nextReview = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-review: \(arg)")
            }
        }

        return UpdateProjectReview(project: project, markReviewed: markReviewed, interval: interval, nextReview: nextReview, dryRun: dryRun)
    }

    private static func parseStateMutation(_ args: [String], command: String) throws -> StateMutation {
        var parser = OptionParser(args)
        let idLabel = command == "project-state" ? "a project name" : "a task id"
        guard let identifier = parser.next(), !identifier.hasPrefix("--") else {
            throw CLIError.usage("\(command) requires \(idLabel)\n\n\(help)")
        }

        var get = false
        var sets: [StateAssignment] = []
        var increments: [String] = []
        var clearKeys: [String] = []
        var clearAll = false
        var format = OutputFormat.json
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--get":
                get = true
            case "--set":
                let pair = try parser.value(after: arg)
                guard let eq = pair.firstIndex(of: "="), eq != pair.startIndex else {
                    throw CLIError.usage("--set requires KEY=VALUE (got: \(pair))")
                }
                let key = String(pair[pair.startIndex..<eq])
                let value = String(pair[pair.index(after: eq)...])
                sets.append(StateAssignment(key: key, value: value))
            case "--increment":
                increments.append(try parser.value(after: arg))
            case "--clear-key":
                clearKeys.append(try parser.value(after: arg))
            case "--clear":
                clearAll = true
            case "--format":
                let value = try parser.value(after: arg)
                guard let parsed = OutputFormat(rawValue: value) else {
                    throw CLIError.usage("Unsupported format: \(value)")
                }
                format = parsed
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for \(command): \(arg)")
            }
        }

        let hasMutation = !sets.isEmpty || !increments.isEmpty || !clearKeys.isEmpty || clearAll
        if get && hasMutation {
            throw CLIError.usage("\(command): --get cannot be combined with --set/--increment/--clear-key/--clear")
        }
        if !get && !hasMutation {
            throw CLIError.usage("\(command) requires --get or at least one of --set/--increment/--clear-key/--clear")
        }
        if clearAll && (!sets.isEmpty || !increments.isEmpty || !clearKeys.isEmpty) {
            throw CLIError.usage("\(command): --clear wipes the whole block and cannot be combined with --set/--increment/--clear-key")
        }

        return StateMutation(
            identifier: identifier,
            get: get,
            sets: sets,
            increments: increments,
            clearKeys: clearKeys,
            clearAll: clearAll,
            format: format,
            dryRun: dryRun
        )
    }

    private static func parseDeleteTasks(_ args: [String]) throws -> DeleteTasks {
        var parser = OptionParser(args)
        var ids: [String] = []

        while let arg = parser.peek(), !arg.hasPrefix("--") {
            _ = parser.next()
            ids.append(arg)
        }

        guard !ids.isEmpty else {
            throw CLIError.usage("task-delete requires at least one task id\n\n\(help)")
        }

        var dryRun = false
        while let arg = parser.next() {
            switch arg {
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for task-delete: \(arg)")
            }
        }

        return DeleteTasks(ids: ids, dryRun: dryRun)
    }

    private static func parseDeleteProject(_ args: [String]) throws -> DeleteProject {
        var parser = OptionParser(args)
        guard let project = parser.next(), !project.hasPrefix("--") else {
            throw CLIError.usage("project-delete requires a project name\n\n\(help)")
        }

        var dryRun = false
        while let arg = parser.next() {
            switch arg {
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for project-delete: \(arg)")
            }
        }

        return DeleteProject(project: project, dryRun: dryRun)
    }

    private static func parseCreateTag(_ args: [String]) throws -> CreateTag {
        var parser = OptionParser(args)
        guard let name = parser.next(), !name.hasPrefix("--") else {
            throw CLIError.usage("tag-create requires a tag name\n\n\(help)")
        }

        var parent: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--parent":
                parent = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for tag-create: \(arg)")
            }
        }

        return CreateTag(name: name, parent: parent, dryRun: dryRun)
    }

    private static func parseRenameTag(_ args: [String]) throws -> RenameTag {
        var parser = OptionParser(args)
        guard let tag = parser.next(), !tag.hasPrefix("--") else {
            throw CLIError.usage("tag-rename requires a tag path\n\n\(help)")
        }

        var newName: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--to":
                newName = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for tag-rename: \(arg)")
            }
        }

        guard let newName else {
            throw CLIError.usage("tag-rename requires --to NEW_NAME")
        }

        return RenameTag(tag: tag, newName: newName, dryRun: dryRun)
    }

    private static func parseDeleteTag(_ args: [String]) throws -> DeleteTag {
        var parser = OptionParser(args)
        guard let tag = parser.next(), !tag.hasPrefix("--") else {
            throw CLIError.usage("tag-delete requires a tag path\n\n\(help)")
        }

        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for tag-delete: \(arg)")
            }
        }

        return DeleteTag(tag: tag, dryRun: dryRun)
    }

    private static func parseMoveTag(_ args: [String]) throws -> MoveTag {
        var parser = OptionParser(args)
        guard let tag = parser.next(), !tag.hasPrefix("--") else {
            throw CLIError.usage("tag-move requires a tag path\n\n\(help)")
        }

        var newParent: String??
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--to-parent":
                newParent = .some(try nullableValue(after: arg, parser: &parser))
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for tag-move: \(arg)")
            }
        }

        guard let newParent else {
            throw CLIError.usage("tag-move requires --to-parent TAG_PATH|none")
        }

        return MoveTag(tag: tag, newParent: newParent, dryRun: dryRun)
    }

    private static func parseCreateFolder(_ args: [String]) throws -> CreateFolder {
        var parser = OptionParser(args)
        guard let name = parser.next(), !name.hasPrefix("--") else {
            throw CLIError.usage("folder-create requires a folder name\n\n\(help)")
        }

        var parent: String?
        var dryRun = false

        while let arg = parser.next() {
            switch arg {
            case "--parent":
                parent = try parser.value(after: arg)
            case "--dry-run":
                dryRun = true
            default:
                throw CLIError.usage("Unexpected argument for folder-create: \(arg)")
            }
        }

        return CreateFolder(name: name, parent: parent, dryRun: dryRun)
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

    func peek() -> String? {
        guard index < args.count else { return nil }
        return args[index]
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
