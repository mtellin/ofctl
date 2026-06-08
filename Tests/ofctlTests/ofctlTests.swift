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

@Test func parsesProjectReviewClearInterval() throws {
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

@Test func workPrivacyScopeGuardsProjectsAndReview() throws {
    let projectsScript = try OmniJavaScript.projectsQuery(
        ProjectsQuery(folder: nil, status: nil, dueForReview: false, limit: 100, format: .json),
        privacyScope: .work
    )
    #expect(projectsScript.contains("projectAllowedByPrivacyScope(project)"))
    #expect(projectsScript.contains("privacyScope"))
    #expect(!projectsScript.contains("Project.ReviewInterval.Unit"))

    let reviewScript = try OmniJavaScript.updateProjectReview(
        UpdateProjectReview(project: "Work Notifications", markReviewed: true, interval: nil, dryRun: false),
        privacyScope: .work
    )
    #expect(reviewScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(reviewScript.contains("project.markReviewed()"))
    #expect(reviewScript.contains("w: \"weeks\""))
    #expect(!reviewScript.contains("Project.ReviewInterval.Unit"))
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
    #expect(script.contains("if (!includeCompleted && !completedFilter && taskEffectivelyCompleted(task))"))
    #expect(script.contains("if (!includeDropped && taskEffectivelyDropped(task))"))
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
    #expect(updateScript.contains("!dryRunProject.project || !projectAllowedByPrivacyScope(dryRunProject.project)"))
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
