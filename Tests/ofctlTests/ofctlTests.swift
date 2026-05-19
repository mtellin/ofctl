import Testing
@testable import OFCTLCore

@Test func parsesTaskQueryByTag() throws {
    let options = try CLI.parse(["ofctl", "tasks", "--tag", "Taylor Morgan", "--format", "text"])

    #expect(options == CommandLineOptions(command: .tasks(TaskQuery(
        tag: "Taylor Morgan",
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
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
        tag: nil,
        available: "now",
        planned: "today",
        deferred: "before:now",
        due: "before:2026-05-25",
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
        tag: nil,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: false,
        limit: 25,
        format: .json
    ))))

    let all = try CLI.parse(["ofctl", "tasks", "--all"])
    #expect(all == CommandLineOptions(command: .tasks(TaskQuery(
        tag: nil,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
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
        tag: nil,
        available: nil,
        planned: nil,
        deferred: nil,
        due: nil,
        includeCompleted: false,
        includeDropped: false,
        includeNotes: true,
        limit: 100,
        format: .json
    ))))
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
        tags: ["Taylor Morgan"],
        deferDate: nil,
        plannedDate: "2026-05-18T09:00:00",
        dueDate: nil,
        estimatedMinutes: 30,
        note: nil,
        dryRun: true
    ))))
}

@Test func escapesAppleScriptStrings() {
    #expect(appleScriptStringLiteral("a \"quote\"\nnext") == "\"a \\\"quote\\\"\\nnext\"")
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
        tags: ["Taylor Morgan"],
        clearTags: false,
        deferDate: nil,
        plannedDate: .some(nil),
        dueDate: nil,
        estimatedMinutes: .some(45),
        note: nil,
        dryRun: true
    ))))
}
