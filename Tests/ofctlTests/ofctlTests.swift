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
        id: "abc123",
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
        id: "abc123",
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

@Test func parsesUpdateTaskWithClearablePlanningFields() throws {
    let options = try CLI.parse([
        "ofctl", "update", "abc123",
        "--tag", "Taylor Morgan",
        "--planned", "none",
        "--duration", "45",
        "--dry-run",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        id: "abc123",
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
        id: "abc123",
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
        id: "abc123",
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

@Test func parsesUpdateActionGroupSettings() throws {
    let options = try CLI.parse([
        "ofctl", "update", "group123",
        "--parallel",
        "--no-complete-with-children",
    ])

    #expect(options == CommandLineOptions(command: .update(UpdateTask(
        id: "group123",
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
        id: "abc123",
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
    let projectScript = try OmniJavaScript.updateProjectStatus(
        UpdateProjectStatus(project: "Product Launch", status: .onHold, dryRun: true),
        privacyScope: .work
    )

    #expect(addScript.contains("assertAddDestinationAvailable(dryRunProject, parentTask);"))
    #expect(addScript.contains("assertTaskAvailableInPrivacyScope(parentTask"))
    #expect(updateScript.contains("!task || !taskAllowedByPrivacyScope(task)"))
    #expect(updateScript.contains("!dryRunProject.project || !projectAllowedByPrivacyScope(dryRunProject.project)"))
    #expect(projectScript.contains("assertProjectAvailableInPrivacyScope(project"))

    let moveScript = try OmniJavaScript.moveProject(
        MoveProject(project: "Home Maintenance", folder: "Home", dryRun: true),
        privacyScope: .work
    )
    #expect(moveScript.contains("assertProjectAvailableInPrivacyScope(project"))
    #expect(moveScript.contains("folderAllowedByPrivacyScope(folder)"))
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
        id: "abc123",
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
        id: "abc123",
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
