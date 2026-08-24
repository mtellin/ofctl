import Foundation
import Testing
@testable import OFCTLCore

@Test func parsesTaskQueryByTag() throws {
    let options = try CLI.parse(["ofctl", "tasks", "--tag", "Taylor Morgan", "--format", "text"])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
        perspective: nil,
        project: nil,
        folder: nil,
        tags: ["Taylor Morgan"],
        tagMode: .all,
        flagged: false,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .text
    ))))
}

@Test func parsesTaskQueryDateFilters() throws {
    let options = try CLI.parse([
        "ofctl", "tasks",
        "--available", "now",
        "--planned", "today",
        "--deferred", "before:now",
        "--due", "before:2026-05-25",
    ])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
        perspective: nil,
        project: nil,
        folder: nil,
        tags: [],
        tagMode: .all,
        flagged: false,
        available: "now",
        planned: "today",
        deferred: "before:now",
        due: "before:2026-05-25",
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .json
    ))))
}

@Test func parsesTaskQueryRepeatRuleFilter() throws {
    let options = try CLI.parse(["ofctl", "tasks", "--repeat-rule", "any"])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
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
        repeatRule: "any",
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .json
    ))))
}

@Test func parsesTaskQueryLimitAndAll() throws {
    let limited = try CLI.parse(["ofctl", "tasks", "--limit", "25"])
    #expect(limited == CommandLineOptions(command: .tasks(TaskQuery(
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
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 25,
        format: .json
    ))))

    let all = try CLI.parse(["ofctl", "tasks", "--all"])
    #expect(all == CommandLineOptions(command: .tasks(TaskQuery(
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
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: nil,
        format: .json
    ))))
}

@Test func parsesTaskQueryIncludeNotes() throws {
    let options = try CLI.parse(["ofctl", "tasks", "--include-notes"])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
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
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: true,
        limit: 100,
        format: .json
    ))))
}

@Test func parsesPerspectiveTaskQuery() throws {
    let options = try CLI.parse(["ofctl", "tasks", "--perspective", "Forecast", "--format", "text"])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
        perspective: "Forecast",
        project: nil,
        folder: nil,
        tags: [],
        tagMode: .all,
        flagged: false,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .text
    ))))
}

@Test func parsesExpandedTaskQueryFilters() throws {
    let options = try CLI.parse([
        "ofctl", "tasks",
        "--project", "Product",
        "--folder", "Work",
        "--tag", "@computer",
        "--tag", "Waiting On",
        "--tag-mode", "any",
        "--flagged",
        "--completed", "today",
        "--format", "text",
    ])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
        perspective: nil,
        project: "Product",
        folder: "Work",
        tags: ["@computer", "Waiting On"],
        tagMode: .any,
        flagged: true,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
        completed: "today",
        includeCompleted: true,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .text
    ))))
}

@Test func parsesTaskLookup() throws {
    let options = try CLI.parse(["ofctl", "task", "abc123", "--include-notes", "--include-children", "--format", "text"])

    #expect(options == CommandLineOptions(command: .task(TaskLookup(
        id: "abc123",
        includeNotes: true,
        includeChildren: true,
        format: .text
    ))))
}

@Test func parsesPerspectivesCommand() throws {
    let options = try CLI.parse(["ofctl", "perspectives", "--format", "text"])

    #expect(options == CommandLineOptions(command: .perspectives(.text)))
}

@Test func parsesAddTaskWithPlanningFields() throws {
    let options = try CLI.parse([
        "ofctl", "add", "Ask Taylor about launch date",
        "--project", "Product",
        "--tag", "Taylor Morgan",
        "--planned", "2026-05-18T09:00:00",
        "--duration", "30",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .add(AddTask(
        name: "Ask Taylor about launch date",
        project: "Product",
        parent: nil,
        tags: ["Taylor Morgan"],
        deferDate: nil,
        plannedDate: "2026-05-18T09:00:00",
        dueDate: nil,
        estimatedMinutes: 30,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        actionGroup: false,
        dryRun: true
    ))))
}

@Test func parsesAddTaskWithProjectFolder() throws {
    let options = try CLI.parse([
        "ofctl", "add", "Ask Taylor about launch date",
        "--project", "Product",
        "--folder", "Work/Planning",
    ])

    #expect(options == CommandLineOptions(command: .add(AddTask(
        name: "Ask Taylor about launch date",
        project: "Product",
        folder: "Work/Planning",
        parent: nil,
        tags: [],
        actionGroup: false,
        dryRun: false
    ))))
}

@Test func rejectsAddTaskFolderWithoutProject() throws {
    do {
        _ = try CLI.parse(["ofctl", "add", "Ask Taylor about launch date", "--folder", "Work"])
        Issue.record("Expected --folder without --project to fail")
    } catch let error as CLIError {
        #expect(error == .usage("--folder requires --project"))
    }
}

@Test func parsesAddTaskWithRepeatRule() throws {
    let options = try CLI.parse([
        "ofctl", "add", "Water plants",
        "--due", "2026-05-22",
        "--repeat-rule", "FREQ=WEEKLY;INTERVAL=1",
        "--repeat-method", "due",
    ])

    #expect(options == CommandLineOptions(command: .add(AddTask(
        name: "Water plants",
        project: nil,
        parent: nil,
        tags: [],
        deferDate: nil,
        plannedDate: nil,
        dueDate: "2026-05-22",
        repeatRule: "FREQ=WEEKLY;INTERVAL=1",
        repeatMethod: .due,
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        actionGroup: false,
        dryRun: false
    ))))
}

@Test func parsesAddTaskToActionGroup() throws {
    let options = try CLI.parse([
        "ofctl", "add", "Draft proposal",
        "--parent", "group123",
        "--tag", "Work",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .add(AddTask(
        name: "Draft proposal",
        project: nil,
        parent: "group123",
        tags: ["Work"],
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        actionGroup: false,
        dryRun: true
    ))))
}

@Test func parsesAddActionGroup() throws {
    let options = try CLI.parse([
        "ofctl", "add-group", "Launch checklist",
        "--project", "Product",
        "--sequential",
        "--complete-with-children",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .addGroup(AddTask(
        name: "Launch checklist",
        project: "Product",
        parent: nil,
        tags: [],
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        estimatedMinutes: nil,
        note: nil,
        sequential: true,
        completedByChildren: true,
        actionGroup: true,
        dryRun: true
    ))))
}

@Test func parsesAddTaskWithFlag() throws {
    let flagged = try CLI.parse(["ofctl", "add", "Ship the deck", "--flag"])
    #expect(flagged == CommandLineOptions(command: .add(AddTask(
        name: "Ship the deck",
        project: nil,
        parent: nil,
        tags: [],
        flagged: true,
        actionGroup: false,
        dryRun: false
    ))))

    let unflagged = try CLI.parse(["ofctl", "add", "Ship the deck", "--no-flag"])
    #expect(unflagged == CommandLineOptions(command: .add(AddTask(
        name: "Ship the deck",
        project: nil,
        parent: nil,
        tags: [],
        flagged: false,
        actionGroup: false,
        dryRun: false
    ))))

    let noFlagArg = try CLI.parse(["ofctl", "add", "Ship the deck"])
    #expect(noFlagArg == CommandLineOptions(command: .add(AddTask(
        name: "Ship the deck",
        project: nil,
        parent: nil,
        tags: [],
        flagged: nil,
        actionGroup: false,
        dryRun: false
    ))))
}

@Test func parsesUpdateTaskWithFlag() throws {
    let flagged = try CLI.parse(["ofctl", "update", "abc123", "--flag"])
    #expect(flagged == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        flagged: true,
        dryRun: false
    ))))

    let unflagged = try CLI.parse(["ofctl", "update", "abc123", "--no-flag"])
    #expect(unflagged == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        flagged: false,
        dryRun: false
    ))))
}

@Test func parsesAddTaskFormat() throws {
    let text = try CLI.parse(["ofctl", "add", "Ship the deck", "--format", "text"])
    guard case let .add(task) = text.command else {
        Issue.record("expected add command")
        return
    }
    #expect(task.format == .text)

    let byDefault = try CLI.parse(["ofctl", "add", "Ship the deck"])
    guard case let .add(defaulted) = byDefault.command else {
        Issue.record("expected add command")
        return
    }
    #expect(defaulted.format == .json)

    #expect(throws: CLIError.self) {
        _ = try CLI.parse(["ofctl", "add", "Ship the deck", "--format", "yaml"])
    }
}

@Test func parsesUpdateTaskFormat() throws {
    let text = try CLI.parse(["ofctl", "update", "abc123", "--format", "text"])
    guard case let .update(task) = text.command else {
        Issue.record("expected update command")
        return
    }
    #expect(task.format == .text)

    let byDefault = try CLI.parse(["ofctl", "update", "abc123", "--complete"])
    guard case let .update(defaulted) = byDefault.command else {
        Issue.record("expected update command")
        return
    }
    #expect(defaulted.format == .json)
}

@Test func buildsFourCharacterAppleEventCodes() {
    #expect(fourCharCode("OFOC") == 0x4f464f43)
    #expect(fourCharCode("OFEJ") == 0x4f46454a)
}

@Test func omniFocusLaunchAttemptsPreferExistingAppPathsBeforeLaunchServicesLookups() {
    let attempts = omniFocusLaunchAttempts(
        configuration: OmniFocusLaunchConfiguration(
            bundleIdentifier: "com.omnigroup.OmniFocus4",
            applicationPath: "/Applications/OmniFocus.app",
            applicationName: "OmniFocus"
        ),
        workspaceApplicationPath: "/Users/taylor/Applications/OmniFocus.app",
        spotlightApplicationPaths: ["/Applications/OmniFocus.app", "/Volumes/Backup/OmniFocus.app"],
        fileExists: { path in
            path == "/Applications/OmniFocus.app" || path == "/Users/taylor/Applications/OmniFocus.app"
        }
    )

    #expect(attempts.map(\.arguments) == [
        ["/Applications/OmniFocus.app"],
        ["/Users/taylor/Applications/OmniFocus.app"],
        ["-b", "com.omnigroup.OmniFocus4"],
        ["-a", "OmniFocus"],
    ])
}

@Test func omniFocusLaunchAttemptsSkipMissingPathsButKeepBundleAndNameFallbacks() {
    let attempts = omniFocusLaunchAttempts(
        configuration: OmniFocusLaunchConfiguration(
            bundleIdentifier: "com.omnigroup.OmniFocus4",
            applicationPath: "/Applications/OmniFocus.app",
            applicationName: "OmniFocus"
        ),
        workspaceApplicationPath: nil,
        spotlightApplicationPaths: [],
        fileExists: { _ in false }
    )

    #expect(attempts.map(\.arguments) == [
        ["-b", "com.omnigroup.OmniFocus4"],
        ["-a", "OmniFocus"],
    ])
}

@Test func parsesUpdateTaskWithClearablePlanningFields() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--tag", "Taylor Morgan",
        "--planned", "none",
        "--duration", "45",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: ["Taylor Morgan"],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: .some(nil),
        dueDate: nil,
        estimatedMinutes: .some(45),
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        complete: false,
        completedAt: nil,
        incomplete: false,
        drop: false,
        dropAllOccurrences: false,
        skip: false,
        dryRun: true
    ))))
}

@Test func rejectsUpdateTaskFolderWithoutProject() throws {
    do {
        _ = try CLI.parse(["ofctl", "update", "abc123", "--folder", "Work"])
        Issue.record("Expected --folder without --project to fail")
    } catch let error as CLIError {
        #expect(error == .usage("--folder requires --project"))
    }
}

@Test func parsesUpdateTaskWithProjectAndFolder() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123", "def456",
        "--project", "Q3 Planning",
        "--folder", "Work",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123", "def456"],
        name: nil,
        project: .some("Q3 Planning"),
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        folder: "Work",
        dryRun: false
    ))))
}

@Test func parsesUpdateTaskWithFolderAndNoCreateProject() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--project", "Existing Project",
        "--folder", "Work",
        "--no-create-project",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: .some("Existing Project"),
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        createProjectIfMissing: false,
        folder: "Work",
        dryRun: false
    ))))
}

@Test func parsesUpdateTaskWithRepeatRule() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--repeat-rule", "none",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        repeatRule: .some(nil),
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
    ))))
}

@Test func parsesUpdateTaskModificationCommands() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--project", "none",
        "--add-tag", "Taylor Morgan",
        "--remove-tag", "Waiting On",
        "--defer", "none",
        "--due", "2026-05-25",
        "--complete",
        "--completed-at", "2026-05-20T13:00:00",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: .some(nil),
        addTags: ["Taylor Morgan"],
        removeTags: ["Waiting On"],
        clearTags: false,
        deferDate: .some(nil),
        plannedDate: nil,
        dueDate: .some("2026-05-25"),
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        complete: true,
        completedAt: "2026-05-20T13:00:00",
        incomplete: false,
        drop: false,
        dropAllOccurrences: false,
        skip: false,
        dryRun: false
    ))))
}

@Test func parsesUpdateTaskNoCreateProjectGuardrail() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--project", "Circuit Board Training",
        "--no-create-project",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: .some("Circuit Board Training"),
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        createProjectIfMissing: false,
        dryRun: false
    ))))
}

@Test func parsesUpdateActionGroupSettings() throws {
    let options = try CLI.parse([
        "ofctl", "update", "group123",
        "--parallel",
        "--no-complete-with-children",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["group123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        estimatedMinutes: nil,
        note: nil,
        sequential: false,
        completedByChildren: false,
        complete: false,
        completedAt: nil,
        incomplete: false,
        drop: false,
        dropAllOccurrences: false,
        skip: false,
        dryRun: false
    ))))
}

@Test func parsesUpdateTaskDropAndSkipValidation() throws {
    let dropped = try CLI.parse([
        "ofctl", "update", "abc123",
        "--drop",
        "--all-occurrences",
    ])

    #expect(dropped == CommandLineOptions(command: .update(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        complete: false,
        completedAt: nil,
        incomplete: false,
        drop: true,
        dropAllOccurrences: true,
        skip: false,
        dryRun: false
    ))))

    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "update", "abc123", "--skip", "--drop"])
    }
}

@Test func parsesUpdateTaskWithMultipleIDs() throws {
    let options = try CLI.parse([
        "ofctl", "update", "id1", "id2", "id3",
        "--flag",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        ids: ["id1", "id2", "id3"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
        flagged: true,
        dryRun: true
    ))))
}

@Test func parsesTaskRename() throws {
    let options = try CLI.parse([
        "ofctl", "task-rename", "abc123",
        "--to", "Updated task name",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .taskRename(RenameTask(
        id: "abc123",
        newName: "Updated task name",
        dryRun: true
    ))))
}

@Test func parsesTaskRenameRequiresToFlag() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-rename", "abc123"])
    }
}

@Test func parsesTaskMoveBeforeTarget() throws {
    let options = try CLI.parse([
        "ofctl", "task-move", "id1", "id2",
        "--before", "target",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .taskMove(MoveTasks(
        ids: ["id1", "id2"],
        destination: .before("target"),
        position: .ending,
        dryRun: true
    ))))
}

@Test func parsesTaskMoveAfterTarget() throws {
    let options = try CLI.parse(["ofctl", "task-move", "id1", "--after", "target"])

    #expect(options == CommandLineOptions(command: .taskMove(MoveTasks(
        ids: ["id1"],
        destination: .after("target"),
        position: .ending,
        dryRun: false
    ))))
}

@Test func parsesTaskMoveToProjectBeginning() throws {
    let options = try CLI.parse([
        "ofctl", "task-move", "id1",
        "--project", "Product Launch",
        "--position", "beginning",
    ])

    #expect(options == CommandLineOptions(command: .taskMove(MoveTasks(
        ids: ["id1"],
        destination: .project("Product Launch"),
        position: .beginning,
        dryRun: false
    ))))
}

@Test func parsesTaskMoveToParentAndInbox() throws {
    let parent = try CLI.parse(["ofctl", "task-move", "id1", "--parent", "parent123"])
    #expect(parent == CommandLineOptions(command: .taskMove(MoveTasks(
        ids: ["id1"],
        destination: .parent("parent123"),
        position: .ending,
        dryRun: false
    ))))

    let inbox = try CLI.parse(["ofctl", "task-move", "id1", "--inbox", "--position", "beginning"])
    #expect(inbox == CommandLineOptions(command: .taskMove(MoveTasks(
        ids: ["id1"],
        destination: .inbox,
        position: .beginning,
        dryRun: false
    ))))
}

@Test func parsesTaskMoveValidation() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-move"])
    }
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-move", "id1"])
    }
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-move", "id1", "--before", "target", "--after", "other"])
    }
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-move", "id1", "--before", "target", "--position", "beginning"])
    }
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-move", "id1", "--project", "Product", "--position", "middle"])
    }
}

@Test func parsesProjectStatusUpdate() throws {
    let options = try CLI.parse([
        "ofctl", "project-status", "Product Launch",
        "--status", "on-hold",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .projectStatus(UpdateProjectStatus(
        project: "Product Launch",
        status: .onHold,
        dryRun: true
    ))))
}

@Test func parsesProjectMove() throws {
    let options = try CLI.parse([
        "ofctl", "project-move", "Home Maintenance",
        "--to-folder", "Home",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .projectMove(MoveProject(
        project: "Home Maintenance",
        folder: "Home",
        dryRun: true
    ))))
}

@Test func parsesProjectMoveToTopLevel() throws {
    let options = try CLI.parse([
        "ofctl", "project-move", "Home Maintenance",
        "--to-folder", "none",
    ])

    #expect(options == CommandLineOptions(command: .projectMove(MoveProject(
        project: "Home Maintenance",
        folder: nil,
        dryRun: false
    ))))
}

@Test func parsesProjectRename() throws {
    let options = try CLI.parse([
        "ofctl", "project-rename", "Home Maintenance",
        "--to", "House Maintenance",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .projectRename(RenameProject(
        project: "Home Maintenance",
        newName: "House Maintenance",
        dryRun: true
    ))))
}

@Test func parsesProjectRenameRequiresToFlag() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "project-rename", "Home Maintenance"])
    }
}

@Test func parsesProjectCompletionUpdate() throws {
    let enabled = try CLI.parse([
        "ofctl", "project-completion", "Product Launch",
        "--complete-with-last-action",
        "--dry-run",
    ])

    #expect(enabled == CommandLineOptions(command: .projectCompletion(UpdateProjectCompletion(
        project: "Product Launch",
        completeWithLastAction: true,
        dryRun: true
    ))))

    let disabled = try CLI.parse([
        "ofctl", "project-completion", "Product Launch",
        "--no-complete-with-last-action",
    ])

    #expect(disabled == CommandLineOptions(command: .projectCompletion(UpdateProjectCompletion(
        project: "Product Launch",
        completeWithLastAction: false,
        dryRun: false
    ))))
}

@Test func parsesProjectCompletionRequiresFlag() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "project-completion", "Product Launch"])
    }
}

@Test func parsesProjectCreate() throws {
    let options = try CLI.parse([
        "ofctl", "project-create", "Work Notifications",
        "--folder", "Work",
        "--singleton",
    ])

    #expect(options == CommandLineOptions(command: .projectCreate(CreateProject(
        name: "Work Notifications",
        folder: "Work",
        singleton: true,
        onHold: false,
        dryRun: false
    ))))
}

@Test func parsesProjectCreateOnHold() throws {
    let options = try CLI.parse([
        "ofctl", "project-create", "Someday Inbox",
        "--on-hold",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .projectCreate(CreateProject(
        name: "Someday Inbox",
        folder: nil,
        singleton: false,
        onHold: true,
        dryRun: true
    ))))
}

@Test func parsesTagsQuery() throws {
    let json = try CLI.parse(["ofctl", "tags"])
    #expect(json == CommandLineOptions(command: .tags(TagsQuery(format: .json))))

    let text = try CLI.parse(["ofctl", "tags", "--format", "text"])
    #expect(text == CommandLineOptions(command: .tags(TagsQuery(format: .text))))
}

@Test func parsesTagCreate() throws {
    let options = try CLI.parse([
        "ofctl", "tag-create", "Errands",
        "--parent", "Status",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .tagCreate(CreateTag(
        name: "Errands",
        parent: "Status",
        dryRun: true
    ))))
}

@Test func parsesTagCreateTopLevel() throws {
    let options = try CLI.parse(["ofctl", "tag-create", "Contexts"])
    #expect(options == CommandLineOptions(command: .tagCreate(CreateTag(
        name: "Contexts",
        parent: nil,
        dryRun: false
    ))))
}

@Test func parsesTagRename() throws {
    let options = try CLI.parse([
        "ofctl", "tag-rename", "Status/Errands",
        "--to", "Out & About",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .tagRename(RenameTag(
        tag: "Status/Errands",
        newName: "Out & About",
        dryRun: true
    ))))
}

@Test func parsesTagRenameRequiresToFlag() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "tag-rename", "Errands"])
    }
}

@Test func parsesTagDelete() throws {
    let options = try CLI.parse([
        "ofctl", "tag-delete", "Status/Errands",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .tagDelete(DeleteTag(
        tag: "Status/Errands",
        dryRun: true
    ))))
}

@Test func parsesTagMove() throws {
    let options = try CLI.parse([
        "ofctl", "tag-move", "Errands",
        "--to-parent", "Status",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .tagMove(MoveTag(
        tag: "Errands",
        newParent: "Status",
        dryRun: true
    ))))
}

@Test func parsesTagMoveToTopLevel() throws {
    let options = try CLI.parse(["ofctl", "tag-move", "Status/Errands", "--to-parent", "none"])
    #expect(options == CommandLineOptions(command: .tagMove(MoveTag(
        tag: "Status/Errands",
        newParent: nil,
        dryRun: false
    ))))
}

@Test func parsesTagMoveRequiresToParent() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "tag-move", "Errands"])
    }
}

@Test func parsesProjectsQuery() throws {
    let defaults = try CLI.parse(["ofctl", "projects"])
    #expect(defaults == CommandLineOptions(command: .projects(ProjectsQuery(
        folder: nil,
        status: nil,
        dueForReview: false,
        limit: 100,
        format: .json
    ))))

    let filtered = try CLI.parse([
        "ofctl", "projects",
        "--folder", "Work",
        "--status", "active",
        "--due-for-review",
        "--limit", "10",
        "--format", "text",
    ])
    #expect(filtered == CommandLineOptions(command: .projects(ProjectsQuery(
        folder: "Work",
        status: .active,
        dueForReview: true,
        limit: 10,
        format: .text
    ))))
}

@Test func parsesProjectsQueryAll() throws {
    let options = try CLI.parse(["ofctl", "projects", "--all"])
    #expect(options == CommandLineOptions(command: .projects(ProjectsQuery(
        folder: nil,
        status: nil,
        dueForReview: false,
        limit: nil,
        format: .json
    ))))
}

@Test func parsesProjectsQueryIncludeNotes() throws {
    let options = try CLI.parse(["ofctl", "projects", "--include-notes"])
    #expect(options == CommandLineOptions(command: .projects(ProjectsQuery(
        folder: nil,
        status: nil,
        dueForReview: false,
        limit: 100,
        format: .json,
        includeNotes: true
    ))))
}

@Test func parsesProjectNoteSet() throws {
    let options = try CLI.parse(["ofctl", "project-note", "My Project", "--note", "hello"])
    #expect(options == CommandLineOptions(command: .projectNote(UpdateProjectNote(
        project: "My Project",
        mode: .set,
        text: "hello",
        dryRun: false
    ))))
}

@Test func parsesProjectNoteByIdWithPrependAndDryRun() throws {
    let options = try CLI.parse([
        "ofctl", "project-note", "abc123XYZ",
        "--prepend", "[ref](obsidian://x)",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .projectNote(UpdateProjectNote(
        project: "abc123XYZ",
        mode: .prepend,
        text: "[ref](obsidian://x)",
        dryRun: true
    ))))
}

@Test func parsesProjectNoteClear() throws {
    let options = try CLI.parse(["ofctl", "project-note", "My Project", "--note", "none"])
    #expect(options == CommandLineOptions(command: .projectNote(UpdateProjectNote(
        project: "My Project",
        mode: .clear,
        text: "",
        dryRun: false
    ))))
}

@Test func parsesProjectNoteFromFile() throws {
    let path = NSTemporaryDirectory() + "ofctl-note-\(UUID().uuidString).md"
    try "from a file".write(toFile: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: path) }

    let options = try CLI.parse(["ofctl", "project-note", "My Project", "--note-file", path])
    #expect(options == CommandLineOptions(command: .projectNote(UpdateProjectNote(
        project: "My Project",
        mode: .set,
        text: "from a file",
        dryRun: false
    ))))
}

@Test func projectNoteRejectsMultipleOperations() throws {
    #expect(throws: CLIError.self) {
        _ = try CLI.parse(["ofctl", "project-note", "My Project", "--note", "a", "--prepend", "b"])
    }
}

@Test func projectNoteRequiresAnOperation() throws {
    #expect(throws: CLIError.self) {
        _ = try CLI.parse(["ofctl", "project-note", "My Project"])
    }
}

@Test func projectNoteRequiresProject() throws {
    #expect(throws: CLIError.self) {
        _ = try CLI.parse(["ofctl", "project-note", "--note", "a"])
    }
}

@Test func parsesProjectReview() throws {
    let options = try CLI.parse([
        "ofctl", "project-review", "Home Maintenance",
        "--mark-reviewed",
        "--interval", "1w",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .projectReview(UpdateProjectReview(
        project: "Home Maintenance",
        markReviewed: true,
        interval: .some("1w"),
        dryRun: true
    ))))
}

/// `--interval none` still parses (it is rejected at the bridge with an
/// explanatory error, not at parse time), but it no longer *clears* anything.
@Test func parsesProjectReviewNoneInterval() throws {
    let options = try CLI.parse([
        "ofctl", "project-review", "Home Maintenance",
        "--interval", "none",
    ])
    #expect(options == CommandLineOptions(command: .projectReview(UpdateProjectReview(
        project: "Home Maintenance",
        markReviewed: false,
        interval: .some(nil),
        dryRun: false
    ))))
}

@Test func parsesProjectReviewNextReview() throws {
    let options = try CLI.parse([
        "ofctl", "project-review", "Home Maintenance",
        "--mark-reviewed",
        "--next-review", "2026-09-15",
    ])
    #expect(options == CommandLineOptions(command: .projectReview(UpdateProjectReview(
        project: "Home Maintenance",
        markReviewed: true,
        interval: nil,
        nextReview: "2026-09-15",
        dryRun: false
    ))))
}

/// An explicit `--next-review` must be assigned AFTER `--mark-reviewed`: setting
/// lastReviewDate recomputes nextReviewDate from the interval, so an earlier
/// assignment would be silently overwritten.
@Test func projectReviewNextReviewOverridesDerivedDate() throws {
    let script = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(
            project: "Home Maintenance",
            markReviewed: true,
            interval: nil,
            nextReview: "2026-09-15",
            dryRun: false
        ),
        privacyScope: .unrestricted
    )

    // Input-dependent: the date must actually reach the script.
    #expect(script.contains("nextReview: \"2026-09-15\""))
    #expect(script.contains("project.nextReviewDate = parsedNextReview"))

    let markIndex = try #require(script.range(of: "project.lastReviewDate = new Date()"))
    let assignIndex = try #require(script.range(of: "project.nextReviewDate = parsedNextReview"))
    #expect(markIndex.lowerBound < assignIndex.lowerBound)

    // Parsed before the dry-run return, so a preview rejects the dates a real run would.
    let parseIndex = try #require(script.range(of: "const parsedNextReview"))
    let dryRunIndex = try #require(script.range(of: "if (input.dryRun)"))
    #expect(parseIndex.lowerBound < dryRunIndex.lowerBound)

    // Out-of-range dates must be rejected, not rolled over: `new Date(2026, 1, 30)` is
    // Mar 2, and 2026-00-10 is Dec 10 2025 — writing a PAST date the caller never asked
    // for and silently dropping the project into the due-for-review queue.
    #expect(script.contains("date.getFullYear() !== year"))
    #expect(script.contains("date.getDate() !== day"))
    // Empty string must fail loudly rather than no-op with a success-shaped payload.
    #expect(script.contains("if (value === null) { return null; }"))
    #expect(!script.contains("function parseDate(value) {\n            if (!value) { return null; }"))
    // --dry-run must surface the resolved date, or a preview hides a bad one.
    #expect(script.contains("nextReview: parsedNextReview ? parsedNextReview.toISOString() : null"))

    // Omitting the flag must leave nextReviewDate alone.
    let withoutScript = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(project: "Home Maintenance", markReviewed: true, interval: nil, dryRun: false),
        privacyScope: .unrestricted
    )
    #expect(withoutScript.contains("nextReview: null"))
}

@Test func workPrivacyScopeGuardsProjectsAndReview() throws {
    let projectsScript = try OmniJavaScript.projectsQuery(
        ProjectsQuery(folder: nil, status: nil, dueForReview: false, limit: 100, format: .json),
        privacyScope: .work
    )
    #expect(projectsScript.contains("projectAllowedByPrivacyScope(project)"))
    #expect(projectsScript.contains("privacyScope"))
    #expect(!projectsScript.contains("ReviewInterval.Unit"))

    let reviewScript = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(project: "Work Notifications", markReviewed: true, interval: nil, dryRun: false),
        privacyScope: .work
    )
    #expect(reviewScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(reviewScript.contains("project.lastReviewDate = new Date()"))
    #expect(reviewScript.contains("w: \"weeks\""))
    #expect(!reviewScript.contains("ReviewInterval.Unit"))
}

/// OmniJS exposes no `ReviewInterval` class: the global is undefined and
/// `Project.ReviewInterval` is a plain object, so `new Project.ReviewInterval(...)`
/// throws "CallbackObject is not a constructor" and `--interval` never worked.
/// The read path had the mirror bug — comparing against `ReviewInterval.Unit.*`
/// threw into a catch that returned null, so every project reported `unit: null`.
///
/// The prior guards asserted only on `"Project.ReviewInterval.Unit"`, which matched
/// neither real defect. Assert on the constructs that actually broke.
@Test func reviewIntervalUsesPlainObjectNotConstructor() throws {
    let reviewScript = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(project: "Home Maintenance", markReviewed: false, interval: "2w", dryRun: false),
        privacyScope: .unrestricted
    )

    // Input-dependent: the spec must actually reach the script. Asserting only on the
    // static template text would pass for ANY input — the earlier version of this test
    // did exactly that and would not have caught the spec being dropped en route.
    #expect(reviewScript.contains("interval: \"2w\""))

    // Write path: mutate an existing instance; never construct one.
    #expect(!reviewScript.contains("new Project.ReviewInterval"))
    #expect(!reviewScript.contains("new ReviewInterval"))
    #expect(reviewScript.contains("interval.steps = parsed.steps"))
    #expect(reviewScript.contains("interval.unit = parsed.unit"))
    // Never borrow an interval instance from another project — that could rewrite an
    // unrelated, possibly out-of-privacy-scope project's cadence. (Don't assert on
    // `flattenedProjects.find`; resolveProjectByNameOrId legitimately uses it.)
    #expect(!reviewScript.contains("donor"))
    #expect(reviewScript.contains("this project has none to modify"))
    // Changing the interval must force nextReviewDate to recompute.
    #expect(reviewScript.contains("project.lastReviewDate = project.lastReviewDate"))
    // The spec is parsed before the dry-run return, so a preview rejects what a real run would.
    let parseIndex = try #require(reviewScript.range(of: "const parsedInterval"))
    let dryRunIndex = try #require(reviewScript.range(of: "if (input.dryRun)"))
    #expect(parseIndex.lowerBound < dryRunIndex.lowerBound)

    // Clearing is impossible in OmniFocus; the attempt must fail with our own message.
    let clearScript = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(project: "Home Maintenance", markReviewed: false, interval: .some(nil), dryRun: false),
        privacyScope: .unrestricted
    )
    #expect(clearScript.contains("interval: null"))
    #expect(clearScript.contains("does not allow clearing a review interval"))

    let projectsScript = try OmniJavaScript.projectsQuery(
        ProjectsQuery(folder: nil, status: nil, dueForReview: true, limit: 100, format: .json),
        privacyScope: .unrestricted
    )

    // Read path: the unit is already a String; no lookup against a nonexistent enum,
    // and no catch that silently degrades a real unit to null.
    #expect(!projectsScript.contains("ReviewInterval.Unit"))
    #expect(projectsScript.contains("typeof unit === \"string\""))
}

@Test func updateTaskScriptCanRefuseMissingProjectCreation() throws {
    var update = defaultUpdateTask()
    update.createProjectIfMissing = false

    let script = try OmniJavaScript.updateTask(update)

    #expect(script.contains("createProjectIfMissing: false"))
    #expect(script.contains("Project not found: ${input.project}"))
    #expect(script.contains("input.createProjectIfMissing ? projectNamedOrCreated(input.project) : existingProjectNamed(input.project)"))
}

@Test func parsesTaskDelete() throws {
    let single = try CLI.parse(["ofctl", "task-delete", "abc123"])
    #expect(single == CommandLineOptions(command: .taskDelete(DeleteTasks(ids: ["abc123"], dryRun: false))))

    let multi = try CLI.parse([
        "ofctl", "task-delete", "abc123", "def456", "ghi789", "--dry-run",
    ])
    #expect(multi == CommandLineOptions(command: .taskDelete(DeleteTasks(
        ids: ["abc123", "def456", "ghi789"],
        dryRun: true
    ))))
}

@Test func parsesTaskDeleteRequiresId() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-delete"])
    }
}

@Test func parsesProjectDelete() throws {
    let options = try CLI.parse([
        "ofctl", "project-delete", "Home Maintenance",
        "--dry-run",
    ])
    #expect(options == CommandLineOptions(command: .projectDelete(DeleteProject(
        project: "Home Maintenance",
        dryRun: true
    ))))
}

@Test func workPrivacyScopeGuardsDeletes() throws {
    let taskScript = try OmniJavaScript.deleteTasks(
        DeleteTasks(ids: ["abc123"], dryRun: false),
        privacyScope: .work
    )
    #expect(taskScript.contains("taskAllowedByPrivacyScope"))
    #expect(taskScript.contains("Task not available in current privacy scope"))

    let projectScript = try OmniJavaScript.deleteProject(
        DeleteProject(project: "Home Maintenance", dryRun: false),
        privacyScope: .work
    )
    #expect(projectScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(projectScript.contains("Project not available in current privacy scope"))
}

@Test func parsesFolderCreate() throws {
    let options = try CLI.parse([
        "ofctl", "folder-create", "Home Maintenance",
        "--parent", "Personal",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .folderCreate(CreateFolder(
        name: "Home Maintenance",
        parent: "Personal",
        dryRun: true
    ))))
}

@Test func parsesFolderCreateTopLevel() throws {
    let options = try CLI.parse(["ofctl", "folder-create", "Work Projects"])

    #expect(options == CommandLineOptions(command: .folderCreate(CreateFolder(
        name: "Work Projects",
        parent: nil,
        dryRun: false
    ))))
}

@Test func parsesFolderCreateRequiresName() {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "folder-create"])
    }
}

@Test func workPrivacyScopeActivatesFromEnvironmentHostnames() {
    #expect(PrivacyScope.fromEnvironment(
        ["OFCTL_WORK_HOSTNAMES": "office-mbp, other-host"],
        hostname: "office-mbp.local"
    ) == .work)

    #expect(PrivacyScope.fromEnvironment(
        ["OFCTL_WORK_HOSTNAMES": "office-mbp"],
        hostname: "personal-mac.local"
    ) == .unrestricted)

    #expect(PrivacyScope.fromEnvironment([:], hostname: "office-mbp.local") == .unrestricted)
}

@Test func workPrivacyScopeFiltersTaskQueries() throws {
    let script = try OmniJavaScript.tasksQuery(defaultTaskQuery(), privacyScope: .work)

    #expect(script.contains("const privacyScope = \"work\";"))
    #expect(script.contains("const privacyAllowedFolderNames = new Set([\"Work\"]);"))
    #expect(script.contains("if (!taskAllowedByPrivacyScope(task)) { return false; }"))
    #expect(script.contains("privacyScope,"))
}

@Test func taskQueryUsesEffectiveCompletionAndDropState() throws {
    let script = try OmniJavaScript.tasksQuery(defaultTaskQuery())

    #expect(script.contains("taskEffectivelyCompleted(task)"))
    #expect(script.contains("taskEffectivelyDropped(task)"))
    // A perspective whose own rules select completed/dropped tasks relaxes these guards,
    // so its result set is not stripped back out by the default filter.
    #expect(script.contains("if (!includeCompleted && !completedFilter && !perspectiveSelectsCompleted && taskEffectivelyCompleted(task))"))
    #expect(script.contains("if (!includeDropped && !perspectiveSelectsDropped && taskEffectivelyDropped(task))"))
    #expect(script.contains("task.effectiveCompletedDate || task.completionDate"))
    #expect(script.contains("return task.effectiveCompletedDate !== null;"))
    #expect(script.contains("return task.effectiveDropDate !== null;"))
    #expect(script.contains("completed: effectivelyCompleted"))
    #expect(script.contains("dropped: effectivelyDropped"))
    #expect(script.contains("individuallyCompleted: task.completed"))
    #expect(script.contains("individuallyDropped: task.dropDate !== null"))
    #expect(script.contains("effectiveCompletionDate: iso(task.effectiveCompletedDate)"))
    #expect(script.contains("effectiveDropDate: iso(task.effectiveDropDate)"))
}

@Test func taskQueryAvailableRespectsContainerStatusAndBlocking() throws {
    let script = try OmniJavaScript.tasksQuery(defaultTaskQuery())

    // --available must never surface tasks under an on-hold/done/dropped project…
    #expect(script.contains("container.status !== Project.Status.Active"))
    // …and point-in-time queries also honor OmniFocus task blocking
    #expect(script.contains("availableFilter === \"now\" && task.taskStatus === Task.Status.Blocked"))
}

@Test func workPrivacyScopeGuardsDirectTaskLookup() throws {
    let script = try OmniJavaScript.taskLookup(
        TaskLookup(id: "abc123", includeNotes: true, includeChildren: true, format: .json),
        privacyScope: .work
    )

    #expect(script.contains("!task || !taskAllowedByPrivacyScope(task)"))
    #expect(script.contains("Task not found or not available in current privacy scope"))
}

@Test func workPrivacyScopeGuardsWrites() throws {
    let addScript = try OmniJavaScript.addTask(defaultAddTask(), privacyScope: .work)
    let updateScript = try OmniJavaScript.updateTask(defaultUpdateTask(), privacyScope: .work)
    let moveTasksScript = try OmniJavaScript.moveTasks(
        MoveTasks(ids: ["abc123"], destination: .before("def456"), position: .ending, dryRun: false),
        privacyScope: .work
    )
    let projectScript = try OmniJavaScript.updateProjectStatus(
        UpdateProjectStatus(project: "Product Launch", status: .onHold, dryRun: true),
        privacyScope: .work
    )
    let projectCompletionScript = try OmniJavaScript.updateProjectCompletion(
        UpdateProjectCompletion(project: "Product Launch", completeWithLastAction: true, dryRun: true),
        privacyScope: .work
    )

    #expect(addScript.contains("assertAddDestinationAvailable(dryRunProject, parentTask);"))
    #expect(addScript.contains("assertTaskAvailableInPrivacyScope(parentTask"))
    #expect(updateScript.contains("!t || !taskAllowedByPrivacyScope(t)"))
    #expect(updateScript.contains("resolvedProjectResult.project && !projectAllowedByPrivacyScope(resolvedProjectResult.project)"))
    // update mirrors add: folder-aware create + top-level guard under privacy scope
    #expect(updateScript.contains("folderAllowedByPrivacyScope(folder)"))
    #expect(updateScript.contains("Creating a project at the top level is not allowed in the current privacy scope"))
    #expect(moveTasksScript.contains("!task || !taskAllowedByPrivacyScope(task)"))
    #expect(moveTasksScript.contains("assertNoSourceTargetConflict(resolvedTasks, targetTask"))
    #expect(moveTasksScript.contains("moveTasks(resolvedTasks, destinationLocation)"))
    #expect(projectScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(projectCompletionScript.contains("assertProjectAvailableInPrivacyScope(project"))

    let moveScript = try OmniJavaScript.moveProject(
        MoveProject(project: "Home Maintenance", folder: "Home", dryRun: true),
        privacyScope: .work
    )
    #expect(moveScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(moveScript.contains("folderAllowedByPrivacyScope(folder)"))

    let createFolderScript = try OmniJavaScript.createFolder(
        CreateFolder(name: "Work Projects", parent: "Work", dryRun: false),
        privacyScope: .work
    )
    #expect(createFolderScript.contains("folderAllowedByPrivacyScope(parentFolder)"))
    #expect(createFolderScript.contains("Creating a folder at the top level is not allowed in the current privacy scope"))
}

@Test func omniJavaScriptSupportsAddProjectFolder() throws {
    let addScript = try OmniJavaScript.addTask(AddTask(
        name: "Ask Taylor about launch date",
        project: "Product",
        folder: "Work/Planning"
    ))

    #expect(addScript.contains("folder: \"Work\\/Planning\""))
    #expect(addScript.contains("const folder = folderForPath(input.folder);"))
    #expect(addScript.contains("new Project(name, folder.ending)"))
}

@Test func omniJavaScriptSupportsRepeatRules() throws {
    let addScript = try OmniJavaScript.addTask(AddTask(
        name: "Water plants",
        project: nil,
        parent: nil,
        tags: [],
        deferDate: nil,
        plannedDate: nil,
        dueDate: "2026-05-22",
        repeatRule: "FREQ=WEEKLY;INTERVAL=1",
        repeatMethod: .due,
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        actionGroup: false,
        dryRun: false
    ))
    let updateScript = try OmniJavaScript.updateTask(UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: nil,
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        repeatRule: .some(nil),
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
    ))
    let queryScript = try OmniJavaScript.tasksQuery(TaskQuery(
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
        repeatRule: "any",
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .json
    ))

    #expect(addScript.contains("task.repetitionRule = parsedRepetitionRule;"))
    #expect(addScript.contains("Task.RepetitionMethod.DueDate"))
    #expect(updateScript.contains("task.repetitionRule = repetitionRule(input.repeatRule, input.repeatMethod);"))
    #expect(queryScript.contains("repeatRuleMatches(task, repeatRuleFilter)"))
    #expect(queryScript.contains("repeatRule: repetitionRule ? repetitionRule.ruleString : null"))
}

@Test func generatedRenameScriptsUseNativeNameAssignment() throws {
    let taskScript = try OmniJavaScript.renameTask(RenameTask(
        id: "abc123",
        newName: "Updated task name",
        dryRun: false
    ))
    let projectScript = try OmniJavaScript.renameProject(RenameProject(
        project: "Home Maintenance",
        newName: "House Maintenance",
        dryRun: false
    ))

    #expect(taskScript.contains("task.name = input.newName;"))
    #expect(projectScript.contains("project.name = input.newName;"))
}

@Test func generatedProjectCompletionScriptSetsCompletedByChildren() throws {
    let projectScript = try OmniJavaScript.updateProjectCompletion(UpdateProjectCompletion(
        project: "Product Launch",
        completeWithLastAction: true,
        dryRun: false
    ))

    #expect(projectScript.contains("project.completedByChildren = input.completeWithLastAction;"))
    #expect(projectScript.contains("Complete with last action only applies to parallel and sequential projects"))
    #expect(projectScript.contains("completeWithLastAction: project.completedByChildren"))
}

private func defaultTaskQuery() -> TaskQuery {
    TaskQuery(
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
        completed: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 100,
        format: .json
    )
}

private func defaultAddTask() -> AddTask {
    AddTask(
        name: "Ask Taylor",
        project: "Product Launch",
        parent: nil,
        tags: [],
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
        estimatedMinutes: nil,
        note: nil,
        sequential: nil,
        completedByChildren: nil,
        actionGroup: false,
        dryRun: false
    )
}

private func defaultUpdateTask() -> UpdateTask {
    UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: .some("Product Launch"),
        addTags: [],
        removeTags: [],
        clearTags: false,
        deferDate: nil,
        plannedDate: nil,
        dueDate: nil,
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
}

@Test func transientAutomationDetectionMatchesResurrectionErrors() throws {
    // The crash we are guarding against: a stale object reference invalidated by a sync.
    #expect(OmniJavaScriptRunner.isTransientAutomationMessage(
        "Reference of object which could not be resurrected Task/aO-MSEDxXqN"))
    #expect(OmniJavaScriptRunner.isTransientAutomationMessage(
        "could not be RESURRECTED")) // case-insensitive
    // Genuine, non-transient errors must not be retried.
    #expect(!OmniJavaScriptRunner.isTransientAutomationMessage("Task not found: abc123"))
    #expect(!OmniJavaScriptRunner.isTransientAutomationMessage("Project not found: Foo"))
}

@Test func parsesTaskStateGet() throws {
    let options = try CLI.parse(["ofctl", "task-state", "abc123", "--get", "--format", "json"])

    #expect(options == CommandLineOptions(command: .taskState(StateMutation(
        identifier: "abc123",
        get: true,
        format: .json
    ))))
}

@Test func parsesTaskStateSetIncrementClearKey() throws {
    let options = try CLI.parse([
        "ofctl", "task-state", "abc123",
        "--set", "priority=P1",
        "--set", "why=committed via sync: blocks Brian",
        "--increment", "slip-count",
        "--clear-key", "stale",
        "--dry-run"
    ])

    #expect(options == CommandLineOptions(command: .taskState(StateMutation(
        identifier: "abc123",
        sets: [
            StateAssignment(key: "priority", value: "P1"),
            StateAssignment(key: "why", value: "committed via sync: blocks Brian")
        ],
        increments: ["slip-count"],
        clearKeys: ["stale"],
        dryRun: true
    ))))
}

@Test func parsesProjectStateClear() throws {
    let options = try CLI.parse(["ofctl", "project-state", "My Project", "--clear"])

    #expect(options == CommandLineOptions(command: .projectState(StateMutation(
        identifier: "My Project",
        clearAll: true
    ))))
}

@Test func rejectsStateWithGetAndMutation() throws {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-state", "abc123", "--get", "--set", "priority=P1"])
    }
}

@Test func rejectsStateWithNoOperation() throws {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-state", "abc123"])
    }
}

@Test func rejectsStateClearCombinedWithSet() throws {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-state", "abc123", "--clear", "--set", "priority=P1"])
    }
}

@Test func rejectsStateMalformedSet() throws {
    #expect(throws: CLIError.self) {
        try CLI.parse(["ofctl", "task-state", "abc123", "--set", "noequalsign"])
    }
}

// The note read/write cycle (noteTextToMarkdown -> markdownRuns) is pure OmniJS
// embedded as a Swift string, so it cannot be exercised by Swift unit tests
// directly. This test extracts the markdownNoteSupport block from source and
// runs the escape (read) / markdownRuns (write) round trip under Node, asserting
// it is idempotent. It guards against the backslash-accumulation regression:
// escapeMarkdownText escapes _ * [ ] ` \ on read, so markdownRuns must unescape
// them on write or every note round trip (e.g. each task-state --set) doubles
// the backslashes. Skipped only when Node is unavailable (CI has it).
@Test func markdownNoteRoundTripIsIdempotentUnderNode() throws {
    let thisFile = URL(fileURLWithPath: #filePath)
    let repoRoot = thisFile
        .deletingLastPathComponent()   // ofctlTests/
        .deletingLastPathComponent()   // Tests/
        .deletingLastPathComponent()   // repo root
    let source = repoRoot.appendingPathComponent("Sources/OFCTLCore/OmniFocusClient.swift")

    let text = try String(contentsOf: source, encoding: .utf8)
    let lines = text.components(separatedBy: "\n")
    guard let open = lines.firstIndex(where: { $0.contains("private let markdownNoteSupport = #\"\"\"") }) else {
        Issue.record("could not locate markdownNoteSupport block in \(source.path)")
        return
    }
    var close = -1
    for i in (open + 1)..<lines.count where lines[i].trimmingCharacters(in: .whitespaces) == "\"\"\"#" {
        close = i
        break
    }
    #expect(close > open)
    let js = lines[(open + 1)..<close].joined(separator: "\n")

    let harness = #"""

const rt = x => markdownRuns(escapeMarkdownText(x)).plain;

// Literal note text: every markdown-special character (_ * ` [ ] \) must survive
// the read (escape) + write (markdownRuns) cycle unchanged. Covers URLs and
// Salesforce field names with underscores, plus literal delimiters that must not
// be re-parsed as markup.
const identity = [
  "Salesforce POC__c and Sales_Engineer_Name__c",
  "https://example.com/a_b/c-d?x=1&y=2",
  "literal *stars* and double **asterisks** stay literal",
  "inline `ticks` and a glob shell/*.swift",
  "a [ref](https://x.com/p_q) written as plain text",
  "See [ref] and item [2] here",
  "C:\\path\\to\\file",
  "mix _under_ *star* [br] `code` back\\slash",
  "plain note, nothing special"
];

// An already-damaged note must not grow further (idempotent) even though the fix
// does not retroactively heal it.
const stableOnly = ["POC\\_\\_c"];

const fails = [];
for (const s of identity) {
  const o = rt(s);
  if (o !== s) fails.push("identity " + JSON.stringify(s) + " -> " + JSON.stringify(o));
}
for (const s of identity.concat(stableOnly)) {
  const a = rt(s), b = rt(a);
  if (a !== b) fails.push("idempotency " + JSON.stringify(s) + " a=" + JSON.stringify(a) + " b=" + JSON.stringify(b));
}

// The (?<!\\) delimiter guards must suppress only escaped delimiters, not genuine
// markup emitted by noteTextToMarkdown for styled runs.
if (!markdownRuns("**bold**").runs.some(r => r.style.bold)) fails.push("genuine **bold** no longer parses");
if (!markdownRuns("*ital*").runs.some(r => r.style.italic)) fails.push("genuine *ital* no longer parses");
if (!markdownRuns("`code`").runs.some(r => r.style.code)) fails.push("genuine `code` no longer parses");

if (fails.length) { console.error(fails.join("\n")); process.exit(1); }
console.log("ok");
"""#

    let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("ofctl-roundtrip-\(UUID().uuidString).mjs")
    try (js + harness).write(to: tmp, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = ["node", tmp.path]
    let err = Pipe()
    proc.standardError = err
    proc.standardOutput = Pipe()
    do {
        try proc.run()
    } catch {
        Issue.record("could not launch node: \(error)")
        return
    }
    proc.waitUntilExit()

    if proc.terminationStatus == 127 {
        return  // node not installed on this machine; CI covers this case
    }
    let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    #expect(proc.terminationStatus == 0, "note round trip not idempotent:\n\(stderr)")
}

// Regression: `update --project NAME` must resolve projects living in subfolders
// even under a privacy scope (which auto-fills a default top-level folder). The
// bug gated resolution on `effectiveFolder`, excluding every subfolder project.
// Resolution must go through the shared name-or-id resolver and must NOT filter
// by the privacy-default folder unless the caller explicitly passed --folder.
@Test func updateResolvesProjectAcrossSubfoldersAndById() throws {
    let update = UpdateTask(
        ids: ["abc123"],
        name: nil,
        project: "Some Project",
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
        createProjectIfMissing: false,
        folder: nil,
        dryRun: true
    )
    let script = try OmniJavaScript.updateTask(update, privacyScope: .work)
    #expect(script.contains("function resolveProjectByNameOrId"))
    // existingProjectNamed's no-folder branch must resolve globally via the
    // resolver (was `flattenedProjects.byName(name)` gated on effectiveFolder).
    #expect(script.contains("return { project: resolveProjectByNameOrId(name), created: false };"))
    // The folder filter inside existingProjectNamed must key off the explicit
    // --folder input, not the privacy-default effectiveFolder.
    #expect(script.contains("if (input.folder !== null) {"))
}

// Regression: project-scoped mutations must accept a primary-key id so a caller
// can target a specific project unambiguously (e.g. a dropped twin sharing a
// name with an active project, which byName alone always resolves to the active).
@Test func projectStatusResolvesByNameOrId() throws {
    let status = UpdateProjectStatus(project: "abc123id", status: .dropped, dryRun: true)
    let script = try OmniJavaScript.updateProjectStatus(status, privacyScope: .work)
    #expect(script.contains("function resolveProjectByNameOrId"))
    #expect(script.contains("resolveProjectByNameOrId(name)"))
}

// Executes the extracted perspective rule evaluator under Node against synthetic
// tasks. Every case below corresponds to a defect that shipped: the evaluator was
// validated only by eyeballing counts against the live database, and ten bugs got
// through that way. Stubs replace the OmniJS globals the block reads.
@Test func perspectiveRuleEvaluatorUnderNode() throws {
    let thisFile = URL(fileURLWithPath: #filePath)
    let repoRoot = thisFile
        .deletingLastPathComponent()   // ofctlTests/
        .deletingLastPathComponent()   // Tests/
        .deletingLastPathComponent()   // repo root
    let source = repoRoot.appendingPathComponent("Sources/OFCTLCore/OmniFocusClient.swift")

    let text = try String(contentsOf: source, encoding: .utf8)
    let lines = text.components(separatedBy: "\n")
    guard let open = lines.firstIndex(where: { $0.contains("private let perspectiveRuleSupport = #\"\"\"") }) else {
        Issue.record("could not locate perspectiveRuleSupport block in \(source.path)")
        return
    }
    var close = -1
    for i in (open + 1)..<lines.count where lines[i].trimmingCharacters(in: .whitespaces) == "\"\"\"#" {
        close = i
        break
    }
    #expect(close > open)
    let js = lines[(open + 1)..<close].joined(separator: "\n")

    let harness = #"""

// --- OmniJS stubs ---------------------------------------------------------
// Task must be a constructor, not a plain object: the evaluator uses
// `child instanceof Task` when resolving firstAvailable.
function Task(){}
Task.Status = { Available:"Available", Blocked:"Blocked", Completed:"Completed",
  Dropped:"Dropped", DueSoon:"DueSoon", Next:"Next", Overdue:"Overdue" };
const Project = { Status: { Active:"Active", OnHold:"OnHold", Done:"Done", Dropped:"Dropped" } };

function startOfDay(d){ return new Date(d.getFullYear(), d.getMonth(), d.getDate()); }
function addDays(d,n){ return new Date(d.getFullYear(), d.getMonth(), d.getDate()+n); }
function taskEffectivelyCompleted(t){ return t.effectiveCompletedDate !== null; }
function taskEffectivelyDropped(t){ return t.effectiveDropDate !== null; }
function childTasks(t){ return t.children || []; }

// Tag tree: Context is a parent holding no direct assignments (mirrors the real
// database, where Context and Status have 0 direct and 900+ descendant tasks).
const tagInside = {id:{primaryKey:"tag-inside"}, name:"@home-inside", flattenedChildren:[]};
const tagOutside = {id:{primaryKey:"tag-outside"}, name:"@home-outside", flattenedChildren:[]};
const tagContext = {id:{primaryKey:"tag-context"}, name:"Context", flattenedChildren:[tagInside, tagOutside]};
const flattenedTags = [tagContext, tagInside, tagOutside];

const DAY = 86400000;
const now = new Date();
const yesterday = new Date(now.getTime() - DAY);
const tomorrow  = new Date(now.getTime() + DAY);
const lastWeek  = new Date(now.getTime() - 7*DAY);
const nextYear  = new Date(now.getTime() + 300*DAY);

function mkTask(o){
  return Object.assign(new Task(), {
    id:{primaryKey:"t"+(mkTask.n=(mkTask.n||0)+1)},
    name:"task", note:"", tags:[], children:[], parent:null, containingProject:null,
    taskStatus:Task.Status.Available, flagged:false, effectiveFlagged:false,
    effectiveCompletedDate:null, effectiveDropDate:null,
    effectivePlannedDate:null, effectiveDeferDate:null, effectiveDueDate:null,
    repetitionRule:null, estimatedMinutes:null, added:now, modified:now
  }, o);
}
const activeProject = {id:{primaryKey:"p1"}, name:"P", status:Project.Status.Active,
  containsSingletonActions:false, parentFolder:null, flattenedTasks:[]};

const fails = [];
function check(label, rules, task, expected){
  let got;
  try { got = perspectiveRulesMatch(task, rules, "all"); }
  catch(e){ got = "THREW: " + e.message; }
  if (got !== expected) fails.push(label + " -> expected " + expected + ", got " + got);
}
function checkThrows(label, rules, task){
  try { perspectiveRulesMatch(task, rules, "all"); fails.push(label + " -> expected a throw, got none"); }
  catch(e){ /* expected */ }
}

// --- availability ---------------------------------------------------------
check("available: Available", [{actionAvailability:"available"}], mkTask({}), true);
check("available: Overdue counts", [{actionAvailability:"available"}], mkTask({taskStatus:Task.Status.Overdue}), true);
check("available: Blocked excluded", [{actionAvailability:"available"}], mkTask({taskStatus:Task.Status.Blocked}), false);
check("remaining: not completed", [{actionAvailability:"remaining"}], mkTask({}), true);
check("remaining: completed excluded", [{actionAvailability:"remaining"}], mkTask({effectiveCompletedDate:now}), false);
check("completed: matches", [{actionAvailability:"completed"}], mkTask({effectiveCompletedDate:now}), true);
check("dropped: matches", [{actionAvailability:"dropped"}], mkTask({effectiveDropDate:now}), true);

// firstAvailable is positional. Testing Task.Status.Next alone silently drops an
// action the moment it comes due, because Overdue/DueSoon shadow Next.
const firstT = mkTask({taskStatus:Task.Status.Overdue});
const secondT = mkTask({taskStatus:Task.Status.Available});
const seqParent = {id:{primaryKey:"g1"}, children:[firstT, secondT]};
firstT.parent = seqParent; secondT.parent = seqParent;
check("firstAvailable: overdue first action still counts", [{actionAvailability:"firstAvailable"}], firstT, true);
check("firstAvailable: second action does not", [{actionAvailability:"firstAvailable"}], secondT, false);

// --- status ---------------------------------------------------------------
check("flagged: direct", [{actionStatus:"flagged"}], mkTask({flagged:true, effectiveFlagged:true}), true);
check("flagged: inherited from project", [{actionStatus:"flagged"}], mkTask({flagged:false, effectiveFlagged:true}), true);
check("flagged: unflagged", [{actionStatus:"flagged"}], mkTask({}), false);
check("due: overdue", [{actionStatus:"due"}], mkTask({taskStatus:Task.Status.Overdue}), true);
check("due: available is not due", [{actionStatus:"due"}], mkTask({}), false);

// --- tags (hierarchical) --------------------------------------------------
const inside = mkTask({tags:[tagInside]});
check("anyOfTags: direct match", [{actionHasAnyOfTags:["tag-inside"]}], inside, true);
check("anyOfTags: parent matches descendant", [{actionHasAnyOfTags:["tag-context"]}], inside, true);
check("anyOfTags: unrelated tag", [{actionHasAnyOfTags:["tag-outside"]}], inside, false);
check("anyOfTags: deleted tag id matches nothing", [{actionHasAnyOfTags:["ghost"]}], inside, false);
check("allOfTags: needs every tag", [{actionHasAllOfTags:["tag-inside","tag-outside"]}], inside, false);
// A dead tag in a `none` block must not silently stop excluding.
check("none + dead tag still excludes nothing", [{aggregateRules:[{actionHasAnyOfTags:["ghost"]}], aggregateType:"none"}], inside, true);

// --- dates ----------------------------------------------------------------
const plannedPast = mkTask({effectivePlannedDate:yesterday});
const plannedFuture = mkTask({effectivePlannedDate:tomorrow});
const beforeNow = [{actionDateField:"planned", actionDateIsAfterDateSpec:{}, actionDateIsBeforeDateSpec:{dynamic:"now"}}];
check("planned before now: past matches", beforeNow, plannedPast, true);
check("planned before now: future excluded", beforeNow, plannedFuture, false);
check("planned before now: unset excluded", beforeNow, mkTask({}), false);
// The unbounded {} spec must be a no-op. Treating null as a bound compares
// `date <= null`, which coerces to `date <= 0` and excludes every task.
check("unbounded after-spec is a no-op", [{actionDateField:"planned", actionDateIsAfterDateSpec:{}}], plannedPast, true);
check("dateIsToday: today matches", [{actionDateField:"planned", actionDateIsToday:true}], mkTask({effectivePlannedDate:now}), true);
check("dateIsToday: yesterday does not", [{actionDateField:"planned", actionDateIsToday:true}], plannedPast, false);
check("inTheNext 365d: tomorrow matches",
  [{actionDateField:"defer", actionDateIsInTheNext:{relativeAfterAmount:365, relativeComponent:"day"}}],
  mkTask({effectiveDeferDate:tomorrow}), true);
check("inTheNext 365d: past does not",
  [{actionDateField:"defer", actionDateIsInTheNext:{relativeAfterAmount:365, relativeComponent:"day"}}],
  mkTask({effectiveDeferDate:yesterday}), false);
check("inThePast 30d: last week matches",
  [{actionDateField:"planned", actionDateIsInThePast:{relativeBeforeAmount:30, relativeComponent:"day"}}],
  mkTask({effectivePlannedDate:lastWeek}), true);
check("inThePast 30d: 300 days ago does not",
  [{actionDateField:"planned", actionDateIsInThePast:{relativeBeforeAmount:30, relativeComponent:"day"}}],
  mkTask({effectivePlannedDate:new Date(now.getTime()-300*DAY)}), false);
// Calendar arithmetic, not 30-day months: 1 month out must still contain a date
// ~29 days ahead regardless of which month it is.
check("inTheNext 1 month uses calendar months",
  [{actionDateField:"defer", actionDateIsInTheNext:{relativeAfterAmount:1, relativeComponent:"month"}}],
  mkTask({effectiveDeferDate:new Date(now.getTime()+28*DAY)}), true);

// --- structural -----------------------------------------------------------
const group = mkTask({children:[mkTask({})]});
check("isLeaf: leaf matches", [{actionIsLeaf:true}], mkTask({}), true);
check("isLeaf: group excluded", [{actionIsLeaf:true}], group, false);
check("isProjectOrGroup: group matches", [{actionIsProjectOrGroup:true}], group, true);
check("repeats: recurring matches", [{actionRepeats:true}], mkTask({repetitionRule:{}}), true);
check("repeats: one-off excluded", [{actionRepeats:true}], mkTask({}), false);
check("hasDeferDate", [{actionHasDeferDate:true}], mkTask({effectiveDeferDate:tomorrow}), true);
check("hasPlannedDate false-form", [{actionHasPlannedDate:false}], mkTask({}), true);
check("withinDuration 15: 10m matches", [{actionWithinDuration:15}], mkTask({estimatedMinutes:10}), true);
check("withinDuration 15: 30m excluded", [{actionWithinDuration:15}], mkTask({estimatedMinutes:30}), false);
check("withinDuration 15: unestimated excluded", [{actionWithinDuration:15}], mkTask({}), false);
check("singleActionsList", [{actionIsInSingleActionsList:true}],
  mkTask({containingProject:Object.assign({}, activeProject, {containsSingletonActions:true})}), true);
check("projectWithStatus active", [{actionHasProjectWithStatus:"active"}], mkTask({containingProject:activeProject}), true);
check("matchingSearch hits name", [{actionMatchingSearch:["someday"]}], mkTask({name:"A Someday thing"}), true);
check("matchingSearch miss", [{actionMatchingSearch:["nope"]}], mkTask({name:"A Someday thing"}), false);

// --- aggregation ----------------------------------------------------------
const flaggedT = mkTask({flagged:true, effectiveFlagged:true});
check("any: one branch true", [{aggregateRules:[{actionStatus:"flagged"},{actionStatus:"due"}], aggregateType:"any"}], flaggedT, true);
check("any: no branch true", [{aggregateRules:[{actionStatus:"flagged"},{actionStatus:"due"}], aggregateType:"any"}], mkTask({}), false);
check("all: both required", [{aggregateRules:[{actionStatus:"flagged"},{actionIsLeaf:true}], aggregateType:"all"}], flaggedT, true);
check("none: excludes match", [{aggregateRules:[{actionStatus:"flagged"}], aggregateType:"none"}], flaggedT, false);
check("none: passes non-match", [{aggregateRules:[{actionStatus:"flagged"}], aggregateType:"none"}], mkTask({}), true);

// A rule switched off in the editor persists as `disabledRule`. Treating it as
// true made an `any` group match every task — this turned Due Soon into 447/475.
check("disabled rule inside any does not match everything",
  [{aggregateRules:[{actionStatus:"flagged"},{disabledRule:{actionHasAnyOfTags:["ghost"]}}], aggregateType:"any"}],
  mkTask({}), false);
check("disabled rule inside all is a no-op",
  [{aggregateRules:[{actionIsLeaf:true},{disabledRule:{actionStatus:"flagged"}}], aggregateType:"all"}],
  mkTask({}), true);
check("disabled rule inside none excludes nothing",
  [{aggregateRules:[{disabledRule:{actionStatus:"flagged"}}], aggregateType:"none"}],
  flaggedT, true);

// An unknown rule must fail loudly rather than be skipped: silently ignoring a
// filter returns a plausible wrong answer, which is the whole failure mode here.
checkThrows("unknown rule key throws", [{actionSomethingNewInOmniFocus:true}], mkTask({}));
checkThrows("unknown aggregate type throws", [{aggregateRules:[{actionIsLeaf:true}], aggregateType:"most"}], mkTask({}));

if (fails.length) { console.error(fails.join("\n")); process.exit(1); }
console.log("ok");
"""#

    let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("ofctl-perspective-\(UUID().uuidString).mjs")
    try (js + harness).write(to: tmp, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    proc.arguments = ["node", tmp.path]
    let err = Pipe()
    proc.standardError = err
    proc.standardOutput = Pipe()
    do {
        try proc.run()
    } catch {
        Issue.record("could not launch node: \(error)")
        return
    }
    proc.waitUntilExit()

    if proc.terminationStatus == 127 {
        return  // node not installed on this machine; CI covers this case
    }
    let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    #expect(proc.terminationStatus == 0, "perspective rule evaluator failures:\n\(stderr)")
}
