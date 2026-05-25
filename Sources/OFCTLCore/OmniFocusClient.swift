import Foundation

public struct PrivacyScope: Equatable, Sendable {
    public enum Name: String, Equatable, Sendable {
        case work
    }

    public var name: Name?
    public var allowedFolderNames: [String]
    public var allowInbox: Bool

    public static let unrestricted = PrivacyScope(name: nil, allowedFolderNames: [], allowInbox: true)
    public static let work = PrivacyScope(name: .work, allowedFolderNames: ["Work"], allowInbox: true)

    public var isRestricted: Bool {
        name != nil
    }

    public static func fromEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment,
        hostname: String = ProcessInfo.processInfo.hostName
    ) -> PrivacyScope {
        let configuredHostnames = Set((environment["OFCTL_WORK_HOSTNAMES"] ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .flatMap { [$0, $0.split(separator: ".").first.map(String.init)].compactMap { $0 } })

        guard !configuredHostnames.isEmpty else { return .unrestricted }

        let normalizedHostname = hostname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let shortHostname = normalizedHostname.split(separator: ".").first.map(String.init)
        let currentHostnames = Set([normalizedHostname, shortHostname].compactMap { $0 }.filter { !$0.isEmpty })

        return !configuredHostnames.isDisjoint(with: currentHostnames) ? .work : .unrestricted
    }
}

public struct OmniFocusClient {
    private let runner: AutomationRunning
    private let privacyScope: PrivacyScope

    public init(runner: AutomationRunning, privacyScope: PrivacyScope = .fromEnvironment()) {
        self.runner = runner
        self.privacyScope = privacyScope
    }

    public func tasks(matching query: TaskQuery) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.tasksQuery(query, privacyScope: privacyScope))
    }

    public func perspectives() throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.perspectivesQuery())
    }

    public func task(_ lookup: TaskLookup) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.taskLookup(lookup, privacyScope: privacyScope))
    }

    public func add(_ task: AddTask) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.addTask(task, privacyScope: privacyScope))
    }

    public func update(_ task: UpdateTask) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateTask(task, privacyScope: privacyScope))
    }

    public func updateProjectStatus(_ update: UpdateProjectStatus) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateProjectStatus(update, privacyScope: privacyScope))
    }

    public func moveProject(_ move: MoveProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.moveProject(move, privacyScope: privacyScope))
    }

    public func createProject(_ create: CreateProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.createProject(create, privacyScope: privacyScope))
    }

    public func createFolder(_ create: CreateFolder) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.createFolder(create, privacyScope: privacyScope))
    }

    public func tags(_ query: TagsQuery) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.tagsQuery())
    }

    public func createTag(_ create: CreateTag) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.createTag(create))
    }

    public func renameTag(_ rename: RenameTag) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.renameTag(rename))
    }

    public func deleteTag(_ delete: DeleteTag) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.deleteTag(delete))
    }

    public func moveTag(_ move: MoveTag) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.moveTag(move))
    }

    public func deleteTasks(_ delete: DeleteTasks) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.deleteTasks(delete, privacyScope: privacyScope))
    }

    public func deleteProject(_ delete: DeleteProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.deleteProject(delete, privacyScope: privacyScope))
    }
}

enum OmniJavaScript {
    static func tasksQuery(_ query: TaskQuery, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let perspective = try jsonLiteral(query.perspective)
        let project = try jsonLiteral(query.project)
        let folder = try jsonLiteral(query.folder)
        let tags = try jsonLiteral(query.tags)
        let tagMode = try jsonLiteral(query.tagMode.rawValue)
        let available = try jsonLiteral(query.available)
        let planned = try jsonLiteral(query.planned)
        let deferred = try jsonLiteral(query.deferred)
        let due = try jsonLiteral(query.due)
        let repeatRule = try jsonLiteral(query.repeatRule)
        let completed = try jsonLiteral(query.completed)
        let limit = query.limit.map(String.init) ?? "null"
        let privacy = try privacyPrelude(privacyScope)
        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)

          const perspectiveName = \(perspective);
          const projectName = \(project);
          const folderName = \(folder);
          const tagNames = \(tags);
          const tagMode = \(tagMode);
          const availableFilter = \(available);
          const plannedFilter = \(planned);
          const deferredFilter = \(deferred);
          const dueFilter = \(due);
          const repeatRuleFilter = \(repeatRule);
          const completedFilter = \(completed);
          const limit = \(limit);
          const includeNotes = \(query.includeNotes ? "true" : "false");
          const includeCompleted = \(query.includeCompleted ? "true" : "false");
          const includeDropped = \(query.includeDropped ? "true" : "false");
          const flaggedOnly = \(query.flagged ? "true" : "false");
          const projectIds = new Set(flattenedProjects.map(project => project.id.primaryKey));

          function perspectiveNamed(name) {
            if (!name) { return null; }

            const normalized = name.toLowerCase();
            const builtIn = Perspective.BuiltIn.all.find(p => p.name.toLowerCase() === normalized);
            if (builtIn) { return builtIn; }

            const custom = Perspective.Custom.byName(name);
            if (custom) { return custom; }

            const customByIdentifier = Perspective.Custom.byIdentifier(name);
            if (customByIdentifier) { return customByIdentifier; }

            throw new Error(`Perspective not found: ${name}`);
          }

          function tasksInPerspective(name) {
            const perspective = perspectiveNamed(name);
            const win = document.windows[0];
            const originalPerspective = win.perspective;
            const seen = new Set();
            const tasks = [];

            try {
              win.perspective = perspective;
              win.content.rootNode.apply(node => {
                const object = node.object;
                if (!(object instanceof Task)) { return; }
                if (seen.has(object.id.primaryKey)) { return; }
                seen.add(object.id.primaryKey);
                tasks.push(object);
              });
            } finally {
              if (originalPerspective) {
                win.perspective = originalPerspective;
              }
            }

            return tasks;
          }

          function tagMatches(task) {
            if (tagNames.length === 0) { return true; }
            const taskTagNames = new Set(task.tags.flatMap(tag => [tag.name, tagPath(tag)]));
            if (tagMode === "any") {
              return tagNames.some(name => taskTagNames.has(name));
            }
            return tagNames.every(name => taskTagNames.has(name));
          }

          function projectMatches(task) {
            if (!projectName) { return true; }
            return task.containingProject && task.containingProject.name === projectName;
          }

          function folderMatches(task) {
            if (!folderName) { return true; }
            return projectFolderNamesForTask(task).includes(folderName);
          }

          function localDate(value) {
            if (value === "now") {
              return new Date();
            }
            if (value === "today") {
              return startOfDay(new Date());
            }
            if (value === "tomorrow") {
              return addDays(startOfDay(new Date()), 1);
            }
            if (value === "yesterday") {
              return addDays(startOfDay(new Date()), -1);
            }

            const match = /^(\\d{4})-(\\d{2})-(\\d{2})$/.exec(value);
            if (match) {
              return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
            }

            const date = new Date(value);
            if (Number.isNaN(date.valueOf())) {
              throw new Error(`Invalid date filter: ${value}`);
            }
            return date;
          }

          function startOfDay(date) {
            return new Date(date.getFullYear(), date.getMonth(), date.getDate());
          }

          function addDays(date, days) {
            return new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
          }

          function dateMatches(date, filter, emptyMatchesNow) {
            if (!filter) { return true; }

            const now = new Date();
            const today = startOfDay(now);

            if (filter === "none") {
              return !date;
            }

            if (filter === "now") {
              if (!date) { return emptyMatchesNow; }
              return date <= now;
            }

            if (!date) { return false; }

            if (filter === "today") {
              return date >= today && date < addDays(today, 1);
            }
            if (filter === "tomorrow") {
              return date >= addDays(today, 1) && date < addDays(today, 2);
            }
            if (filter === "yesterday") {
              return date >= addDays(today, -1) && date < today;
            }
            if (filter.startsWith("before:")) {
              return date < localDate(filter.slice("before:".length));
            }
            if (filter.startsWith("after:")) {
              return date > localDate(filter.slice("after:".length));
            }
            if (filter.startsWith("on:")) {
              const target = localDate(filter.slice("on:".length));
              const start = startOfDay(target);
              return date >= start && date < addDays(start, 1);
            }

            throw new Error(`Unsupported date filter: ${filter}`);
          }

          function repeatRuleMatches(task, filter) {
            if (!filter) { return true; }
            const rule = task.repetitionRule;
            if (filter === "any") { return rule !== null; }
            if (filter === "none") { return rule === null; }
            return rule !== null && rule.ruleString === filter;
          }

          const sourceTasks = perspectiveName ? tasksInPerspective(perspectiveName) : flattenedTasks;
          const matchedTasks = sourceTasks.filter(task => {
            if (projectIds.has(task.id.primaryKey)) { return false; }
            if (!task.inInbox && task.parent === null && task.containingProject !== null) { return false; }
            if (!taskAllowedByPrivacyScope(task)) { return false; }
            if (!includeCompleted && !completedFilter && task.completed) { return false; }
            if (!includeDropped && task.dropDate) { return false; }
            if (!projectMatches(task)) { return false; }
            if (!folderMatches(task)) { return false; }
            if (!tagMatches(task)) { return false; }
            if (flaggedOnly && !task.flagged) { return false; }
            if (!dateMatches(task.effectiveDeferDate || task.deferDate, availableFilter, true)) { return false; }
            if (!dateMatches(task.effectivePlannedDate || task.plannedDate, plannedFilter, false)) { return false; }
            if (!dateMatches(task.deferDate, deferredFilter, false)) { return false; }
            if (!dateMatches(task.effectiveDueDate || task.dueDate, dueFilter, false)) { return false; }
            if (!repeatRuleMatches(task, repeatRuleFilter)) { return false; }
            if (!dateMatches(task.completionDate, completedFilter, false)) { return false; }
            return true;
          });

          const returnedTasks = limit === null ? matchedTasks : matchedTasks.slice(0, limit);
          const tasks = returnedTasks.map(task => serializeTask(task, includeNotes, false));

          return JSON.stringify({
            tasks,
            meta: {
              perspective: perspectiveName,
              project: projectName,
              folder: folderName,
              tags: tagNames,
              tagMode,
              repeatRule: repeatRuleFilter,
              privacyScope,
              total: matchedTasks.length,
              count: tasks.length,
              limit,
              truncated: limit !== null && matchedTasks.length > limit
            }
          }, null, 2);
        })();
        """
    }

    static func taskLookup(_ lookup: TaskLookup, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let id = try jsonLiteral(lookup.id)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)

          const taskId = \(id);
          const task = Task.byIdentifier(taskId);
          const includeNotes = \(lookup.includeNotes ? "true" : "false");
          const includeChildren = \(lookup.includeChildren ? "true" : "false");
          if (!task || !taskAllowedByPrivacyScope(task)) {
            throw new Error(`Task not found or not available in current privacy scope: ${taskId}`);
          }

          return JSON.stringify({
            task: serializeTask(task, includeNotes, includeChildren)
          }, null, 2);
        })();
        """
    }

    static func perspectivesQuery() -> String {
        """
        (() => {
          const builtIn = Perspective.BuiltIn.all.map(perspective => ({
            name: perspective.name,
            type: "built-in",
            identifier: null
          }));

          const custom = Perspective.Custom.all.map(perspective => ({
            name: perspective.name,
            type: "custom",
            identifier: perspective.identifier || null
          }));

          return JSON.stringify({
            perspectives: builtIn.concat(custom),
            meta: {
              count: builtIn.length + custom.length,
              builtIn: builtIn.length,
              custom: custom.length
            }
          }, null, 2);
        })();
        """
    }

    static func addTask(_ task: AddTask, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let name = try jsonLiteral(task.name)
        let project = try jsonLiteral(task.project)
        let parent = try jsonLiteral(task.parent)
        let tags = try jsonLiteral(task.tags)
        let deferDate = try jsonLiteral(task.deferDate)
        let plannedDate = try jsonLiteral(task.plannedDate)
        let dueDate = try jsonLiteral(task.dueDate)
        let repeatRule = try jsonLiteral(task.repeatRule)
        let repeatMethod = try jsonLiteral(task.repeatMethod?.rawValue)
        let note = try jsonLiteral(task.note)
        let estimatedMinutes = task.estimatedMinutes.map(String.init) ?? "null"
        let sequential = optionalBoolAssignment(task.sequential)
        let completedByChildren = optionalBoolAssignment(task.completedByChildren)
        let flagged = optionalBoolAssignment(task.flagged)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            name: \(name),
            project: \(project),
            parent: \(parent),
            tags: \(tags),
            deferDate: \(deferDate),
            plannedDate: \(plannedDate),
            dueDate: \(dueDate),
            repeatRule: \(repeatRule),
            repeatMethod: \(repeatMethod),
            estimatedMinutes: \(estimatedMinutes),
            note: \(note),
            sequential: \(sequential),
            completedByChildren: \(completedByChildren),
            flagged: \(flagged),
            actionGroup: \(task.actionGroup ? "true" : "false"),
            dryRun: \(task.dryRun ? "true" : "false")
          };

          function parseDate(value) {
            if (!value) { return null; }
            const midnight = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
            if (value === "now") { return new Date(); }
            if (value === "today") { return midnight(); }
            if (value === "tomorrow") { const d = midnight(); d.setDate(d.getDate() + 1); return d; }
            if (value === "yesterday") { const d = midnight(); d.setDate(d.getDate() - 1); return d; }
            const ymd = value.match(/^(\\d{4})-(\\d{2})-(\\d{2})$/);
            if (ymd) { return new Date(Number(ymd[1]), Number(ymd[2]) - 1, Number(ymd[3])); }
            const date = new Date(value);
            if (Number.isNaN(date.valueOf())) {
              throw new Error(`Invalid date: ${value}`);
            }
            return date;
          }

          function repetitionMethodNamed(name) {
            switch (name || "fixed") {
            case "fixed":
              return Task.RepetitionMethod.Fixed;
            case "due":
              return Task.RepetitionMethod.DueDate;
            case "defer":
              return Task.RepetitionMethod.DeferUntilDate;
            default:
              throw new Error(`Unsupported repeat method: ${name}`);
            }
          }

          function repetitionRule(ruleString, methodName) {
            if (!ruleString) { return null; }
            return new Task.RepetitionRule(ruleString, repetitionMethodNamed(methodName));
          }

          function existingProjectNamed(name) {
            if (!name) { return { project: null, created: false }; }
            const project = flattenedProjects.byName(name);
            return { project, created: false };
          }

          function projectNamedOrCreated(name) {
            if (!name) { return { project: null, created: false }; }
            const existing = flattenedProjects.byName(name);
            if (existing) { return { project: existing, created: false }; }
            return { project: new Project(name, library.ending), created: true };
          }

          function parentTaskNamed(id) {
            if (!id) { return null; }
            const parent = Task.byIdentifier(id);
            if (!parent) {
              throw new Error(`Parent task not found: ${id}`);
            }
            return parent;
          }

          function assertAddDestinationAvailable(projectResult, parentTask) {
            if (!privacyScope) { return; }
            if (parentTask) {
              assertTaskAvailableInPrivacyScope(parentTask, `Parent task not found or not available in current privacy scope: ${input.parent}`);
              return;
            }
            if (input.project === null) {
              if (!privacyAllowInbox) {
                throw new Error("Inbox is not available in current privacy scope");
              }
              return;
            }
            if (!projectResult.project || !projectAllowedByPrivacyScope(projectResult.project)) {
              throw new Error(`Project not found or not available in current privacy scope: ${input.project}`);
            }
          }

          const dryRunProject = existingProjectNamed(input.project);
          const parentTask = parentTaskNamed(input.parent);
          assertAddDestinationAvailable(dryRunProject, parentTask);
          const parsedDeferDate = parseDate(input.deferDate);
          const parsedPlannedDate = parseDate(input.plannedDate);
          const parsedDueDate = parseDate(input.dueDate);
          const parsedRepetitionRule = repetitionRule(input.repeatRule, input.repeatMethod);
          const dryRunTags = input.tags.map(name => existingTagNamedOrPath(name));

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              task: input,
              meta: {
                privacyScope,
                projectExists: dryRunProject.project !== null,
                wouldCreateProject: input.project !== null && dryRunProject.project === null,
                parent: parentTask ? { id: parentTask.id.primaryKey, name: parentTask.name } : null,
                tags: dryRunTags.map(result => ({
                  input: result.input,
                  exists: result.tag !== null,
                  path: result.tag ? tagPath(result.tag) : result.path,
                  wouldCreate: result.tag === null
                }))
              }
            }, null, 2);
          }

          const projectResult = projectNamedOrCreated(input.project);
          const project = projectResult.project;
          const insertion = parentTask ? parentTask.ending : (project ? project.ending : inbox.ending);
          const task = new Task(input.name, insertion);
          setMarkdownNote(task, input.note || "");
          task.deferDate = parsedDeferDate;
          task.plannedDate = parsedPlannedDate;
          task.dueDate = parsedDueDate;
          task.repetitionRule = parsedRepetitionRule;
          task.estimatedMinutes = input.estimatedMinutes;
          if (input.sequential !== undefined) { task.sequential = input.sequential; }
          if (input.completedByChildren !== undefined) { task.completedByChildren = input.completedByChildren; }
          if (input.flagged !== undefined) { task.flagged = input.flagged; }
          input.tags.map(name => tagNamedOrCreated(name)).forEach(tag => task.addTag(tag));

          return JSON.stringify({
            task: serializeTask(task, false, input.actionGroup),
            meta: {
              privacyScope,
              createdProject: projectResult.created
            }
          }, null, 2);
        })();
        """
    }

    static func updateTask(_ task: UpdateTask, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let id = try jsonLiteral(task.id)
        let name = try jsonLiteral(task.name)
        let project = optionalJSONAssignment(task.project)
        let addTags = try jsonLiteral(task.addTags)
        let removeTags = try jsonLiteral(task.removeTags)
        let clearTags = task.clearTags ? "true" : "false"
        let deferDate = optionalJSONAssignment(task.deferDate)
        let plannedDate = optionalJSONAssignment(task.plannedDate)
        let dueDate = optionalJSONAssignment(task.dueDate)
        let repeatRule = optionalJSONAssignment(task.repeatRule)
        let repeatMethod = try jsonLiteral(task.repeatMethod?.rawValue)
        let estimatedMinutes = optionalIntAssignment(task.estimatedMinutes)
        let note = try jsonLiteral(task.note)
        let completedAt = try jsonLiteral(task.completedAt)
        let sequential = optionalBoolAssignment(task.sequential)
        let completedByChildren = optionalBoolAssignment(task.completedByChildren)
        let flagged = optionalBoolAssignment(task.flagged)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            id: \(id),
            name: \(name),
            project: \(project),
            addTags: \(addTags),
            removeTags: \(removeTags),
            clearTags: \(clearTags),
            deferDate: \(deferDate),
            plannedDate: \(plannedDate),
            dueDate: \(dueDate),
            repeatRule: \(repeatRule),
            repeatMethod: \(repeatMethod),
            estimatedMinutes: \(estimatedMinutes),
            note: \(note),
            sequential: \(sequential),
            completedByChildren: \(completedByChildren),
            flagged: \(flagged),
            complete: \(task.complete ? "true" : "false"),
            completedAt: \(completedAt),
            incomplete: \(task.incomplete ? "true" : "false"),
            drop: \(task.drop ? "true" : "false"),
            dropAllOccurrences: \(task.dropAllOccurrences ? "true" : "false"),
            skip: \(task.skip ? "true" : "false"),
            dryRun: \(task.dryRun ? "true" : "false")
          };

          function parseDate(value) {
            if (value === null) { return null; }
            const midnight = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
            if (value === "now") { return new Date(); }
            if (value === "today") { return midnight(); }
            if (value === "tomorrow") { const d = midnight(); d.setDate(d.getDate() + 1); return d; }
            if (value === "yesterday") { const d = midnight(); d.setDate(d.getDate() - 1); return d; }
            const ymd = value.match(/^(\\d{4})-(\\d{2})-(\\d{2})$/);
            if (ymd) { return new Date(Number(ymd[1]), Number(ymd[2]) - 1, Number(ymd[3])); }
            const date = new Date(value);
            if (Number.isNaN(date.valueOf())) {
              throw new Error(`Invalid date: ${value}`);
            }
            return date;
          }

          function repetitionMethodNamed(name) {
            switch (name || "fixed") {
            case "fixed":
              return Task.RepetitionMethod.Fixed;
            case "due":
              return Task.RepetitionMethod.DueDate;
            case "defer":
              return Task.RepetitionMethod.DeferUntilDate;
            default:
              throw new Error(`Unsupported repeat method: ${name}`);
            }
          }

          function repetitionRule(ruleString, methodName) {
            if (ruleString === null) { return null; }
            return new Task.RepetitionRule(ruleString, repetitionMethodNamed(methodName));
          }

          function existingTagNamed(name) {
            const tag = existingTagNamedOrPath(name).tag;
            if (!tag) {
              throw new Error(`Tag not found: ${name}`);
            }
            return tag;
          }

          function existingProjectNamed(name) {
            if (!name) { return { project: null, created: false }; }
            const project = flattenedProjects.byName(name);
            return { project, created: false };
          }

          function projectNamedOrCreated(name) {
            if (!name) { return { project: null, created: false }; }
            const existing = flattenedProjects.byName(name);
            if (existing) { return { project: existing, created: false }; }
            return { project: new Project(name, library.ending), created: true };
          }

          const task = Task.byIdentifier(input.id);
          if (!task || !taskAllowedByPrivacyScope(task)) {
            throw new Error(`Task not found or not available in current privacy scope: ${input.id}`);
          }

          const dryRunProject = input.project === undefined || input.project === null
            ? { project: null, created: false }
            : existingProjectNamed(input.project);
          if (privacyScope && input.project !== undefined && input.project !== null) {
            if (!dryRunProject.project || !projectAllowedByPrivacyScope(dryRunProject.project)) {
              throw new Error(`Project not found or not available in current privacy scope: ${input.project}`);
            }
          }
          const dryRunAddTags = input.addTags.map(name => existingTagNamedOrPath(name));
          const dryRunRemoveTags = input.removeTags.map(name => existingTagNamedOrPath(name));

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              task: input,
              meta: {
                privacyScope,
                projectExists: input.project !== undefined && input.project !== null ? dryRunProject.project !== null : null,
                wouldCreateProject: input.project !== undefined && input.project !== null && dryRunProject.project === null,
                addTags: dryRunAddTags.map(result => ({
                  input: result.input,
                  exists: result.tag !== null,
                  path: result.tag ? tagPath(result.tag) : result.path,
                  wouldCreate: result.tag === null
                })),
                removeTags: dryRunRemoveTags.map(result => ({
                  input: result.input,
                  exists: result.tag !== null,
                  path: result.tag ? tagPath(result.tag) : result.path
                }))
              }
            }, null, 2);
          }

          let projectCreated = false;
          if (input.name !== null) { task.name = input.name; }
          if (input.note !== null) { setMarkdownNote(task, input.note); }
          if (input.project !== undefined) {
            const projectResult = input.project === null
              ? { project: null, created: false }
              : projectNamedOrCreated(input.project);
            projectCreated = projectResult.created;
            const insertion = projectResult.project === null ? inbox.ending : projectResult.project.ending;
            moveTasks([task], insertion);
          }
          if (input.deferDate !== undefined) { task.deferDate = parseDate(input.deferDate); }
          if (input.plannedDate !== undefined) { task.plannedDate = parseDate(input.plannedDate); }
          if (input.dueDate !== undefined) { task.dueDate = parseDate(input.dueDate); }
          if (input.repeatRule !== undefined) { task.repetitionRule = repetitionRule(input.repeatRule, input.repeatMethod); }
          if (input.estimatedMinutes !== undefined) { task.estimatedMinutes = input.estimatedMinutes; }
          if (input.sequential !== undefined) { task.sequential = input.sequential; }
          if (input.completedByChildren !== undefined) { task.completedByChildren = input.completedByChildren; }
          if (input.flagged !== undefined) { task.flagged = input.flagged; }
          if (input.clearTags) { task.clearTags(); }
          input.removeTags.forEach(name => task.removeTag(existingTagNamed(name)));
          input.addTags.forEach(name => task.addTag(tagNamedOrCreated(name)));

          let resultTask = task;
          if (input.incomplete) {
            task.markIncomplete();
          }
          if (input.complete) {
            resultTask = task.markComplete(parseDate(input.completedAt));
          }
          if (input.drop) {
            task.drop(input.dropAllOccurrences);
          }
          if (input.skip) {
            task.drop(false);
          }

          return JSON.stringify({
            task: serializeTask(resultTask, false, input.sequential !== undefined || input.completedByChildren !== undefined),
            meta: {
              privacyScope,
              createdProject: projectCreated
            }
          }, null, 2);
        })();
        """
    }

    static func updateProjectStatus(_ update: UpdateProjectStatus, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(update.project)
        let status = try jsonLiteral(update.status.rawValue)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            project: \(project),
            status: \(status),
            dryRun: \(update.dryRun ? "true" : "false")
          };

          function projectNamed(name) {
            const project = flattenedProjects.byName(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          function statusNamed(name) {
            switch (name) {
            case "active":
              return Project.Status.Active;
            case "on-hold":
              return Project.Status.OnHold;
            case "completed":
              return Project.Status.Done;
            case "dropped":
              return Project.Status.Dropped;
            default:
              throw new Error(`Unsupported project status: ${name}`);
            }
          }

          const project = projectNamed(input.project);
          assertProjectAvailableInPrivacyScope(project, `Project not found or not available in current privacy scope: ${input.project}`);
          const status = statusNamed(input.status);

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, project: input, meta: { privacyScope } }, null, 2);
          }

          project.status = status;

          return JSON.stringify({
            project: {
              id: project.id.primaryKey,
              name: project.name,
              status: input.status
            },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func moveProject(_ move: MoveProject, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(move.project)
        let folder = try jsonLiteral(move.folder)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)
          \(folderSupport)

          const input = {
            project: \(project),
            folder: \(folder),
            dryRun: \(move.dryRun ? "true" : "false")
          };

          function projectNamed(name) {
            const project = flattenedProjects.byName(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          const project = projectNamed(input.project);
          assertProjectAvailableInPrivacyScope(project, `Project not found or not available in current privacy scope: ${input.project}`);

          let folder = null;
          if (input.folder !== null) {
            folder = folderForPath(input.folder);
            if (!folderAllowedByPrivacyScope(folder)) {
              throw new Error(`Destination folder not available in current privacy scope: ${input.folder}`);
            }
          } else if (privacyScope) {
            throw new Error(`Moving a project to the top level is not allowed in the current privacy scope`);
          }

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, project: input, meta: { privacyScope } }, null, 2);
          }

          const destination = folder ? folder.ending : library.ending;
          moveSections([project], destination);

          return JSON.stringify({
            project: {
              id: project.id.primaryKey,
              name: project.name,
              folder: folder ? folderPath(folder) : []
            },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func createProject(_ create: CreateProject, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let name = try jsonLiteral(create.name)
        let folder = try jsonLiteral(create.folder)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)
          \(folderSupport)

          const input = {
            name: \(name),
            folder: \(folder),
            singleton: \(create.singleton ? "true" : "false"),
            onHold: \(create.onHold ? "true" : "false"),
            dryRun: \(create.dryRun ? "true" : "false")
          };

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, project: input, meta: { privacyScope } }, null, 2);
          }

          const existing = flattenedProjects.byName(input.name);
          if (existing) {
            throw new Error(`Project already exists: ${input.name}`);
          }

          let folder = null;
          if (input.folder !== null) {
            folder = folderForPath(input.folder);
            if (!folderAllowedByPrivacyScope(folder)) {
              throw new Error(`Destination folder not available in current privacy scope: ${input.folder}`);
            }
          } else if (privacyScope) {
            throw new Error(`Creating a project at the top level is not allowed in the current privacy scope`);
          }

          const destination = folder ? folder.ending : library.ending;
          const project = new Project(input.name, destination);

          if (input.singleton) {
            project.sequential = false;
            project.containsSingletonActions = true;
          }
          if (input.onHold) { project.status = Project.Status.onHold; }

          return JSON.stringify({
            project: {
              id: project.id.primaryKey,
              name: project.name,
              folder: folder ? folderPath(folder) : [],
              singleton: project.containsSingletonActions,
              status: project.status.name
            },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func createFolder(_ create: CreateFolder, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let name = try jsonLiteral(create.name)
        let parent = try jsonLiteral(create.parent)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)
          \(folderSupport)

          const input = {
            name: \(name),
            parent: \(parent),
            dryRun: \(create.dryRun ? "true" : "false")
          };

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, folder: input, meta: { privacyScope } }, null, 2);
          }

          let parentFolder = null;
          if (input.parent !== null) {
            parentFolder = folderForPath(input.parent);
            if (!folderAllowedByPrivacyScope(parentFolder)) {
              throw new Error(`Destination folder not available in current privacy scope: ${input.parent}`);
            }
          } else if (privacyScope) {
            throw new Error(`Creating a folder at the top level is not allowed in the current privacy scope`);
          }

          const destination = parentFolder ? parentFolder.ending : library.ending;
          const folder = new Folder(input.name, destination);

          return JSON.stringify({
            folder: {
              id: folder.id.primaryKey,
              name: folder.name,
              path: folderPath(folder)
            },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func deleteTasks(_ delete: DeleteTasks, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let ids = try jsonLiteral(delete.ids)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            ids: \(ids),
            dryRun: \(delete.dryRun ? "true" : "false")
          };

          const resolved = input.ids.map(id => {
            const task = Task.byIdentifier(id);
            if (!task) { throw new Error(`Task not found: ${id}`); }
            if (!taskAllowedByPrivacyScope(task)) {
              throw new Error(`Task not available in current privacy scope: ${id}`);
            }
            return task;
          });

          const results = resolved.map(task => {
            const result = { id: task.id.primaryKey, name: task.name, deleted: !input.dryRun };
            if (!input.dryRun) { deleteObject(task); }
            return result;
          });

          return JSON.stringify({ tasks: results, dryRun: input.dryRun, meta: { privacyScope } }, null, 2);
        })();
        """
    }

    static func deleteProject(_ delete: DeleteProject, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(delete.project)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            project: \(project),
            dryRun: \(delete.dryRun ? "true" : "false")
          };

          const project = flattenedProjects.byName(input.project);
          if (!project) { throw new Error(`Project not found: ${input.project}`); }
          assertProjectAvailableInPrivacyScope(project, `Project not available in current privacy scope: ${input.project}`);

          const projectInfo = {
            id: project.id.primaryKey,
            name: project.name,
            folder: projectFolderNamesForProject(project)
          };

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, project: projectInfo, meta: { privacyScope } }, null, 2);
          }

          deleteObject(project);
          return JSON.stringify({ deleted: true, project: projectInfo, meta: { privacyScope } }, null, 2);
        })();
        """
    }

    static func tagsQuery() -> String {
        """
        (() => {
          \(taskSerializationSupport)

          const tagList = flattenedTags.map(tag => ({
            id: tag.id.primaryKey,
            name: tag.name,
            path: tagPath(tag),
            parent: tag.parent ? tag.parent.name : null,
            parentPath: tag.parent ? tagPath(tag.parent) : null,
            childCount: tag.tags.length
          }));

          return JSON.stringify({
            tags: tagList,
            meta: { count: tagList.length }
          }, null, 2);
        })();
        """
    }

    static func createTag(_ create: CreateTag) throws -> String {
        let name = try jsonLiteral(create.name)
        let parent = try jsonLiteral(create.parent)

        return """
        (() => {
          \(taskSerializationSupport)

          const input = {
            name: \(name),
            parent: \(parent),
            dryRun: \(create.dryRun ? "true" : "false")
          };

          let parentTag = null;
          if (input.parent !== null) {
            const parts = tagPathParts(input.parent);
            parentTag = tagNamedByPath(parts);
            if (!parentTag) {
              throw new Error(`Parent tag not found: ${input.parent}`);
            }
          }

          const targetPath = parentTag ? tagPath(parentTag) + "/" + input.name : input.name;
          const existing = parentTag ? childTagNamed(parentTag, input.name) : rootTagNamed(input.name);
          if (existing) {
            throw new Error(`Tag already exists: ${targetPath}`);
          }

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, tag: input, meta: { targetPath } }, null, 2);
          }

          const newTag = parentTag ? new Tag(input.name, parentTag.ending) : new Tag(input.name);

          return JSON.stringify({
            tag: {
              id: newTag.id.primaryKey,
              name: newTag.name,
              path: tagPath(newTag)
            }
          }, null, 2);
        })();
        """
    }

    static func renameTag(_ rename: RenameTag) throws -> String {
        let tag = try jsonLiteral(rename.tag)
        let newName = try jsonLiteral(rename.newName)

        return """
        (() => {
          \(taskSerializationSupport)

          const input = {
            tag: \(tag),
            newName: \(newName),
            dryRun: \(rename.dryRun ? "true" : "false")
          };

          const parts = tagPathParts(input.tag);
          const tag = tagNamedByPath(parts);
          if (!tag) {
            throw new Error(`Tag not found: ${input.tag}`);
          }

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, tag: input, meta: { from: tagPath(tag) } }, null, 2);
          }

          const oldPath = tagPath(tag);
          tag.name = input.newName;

          return JSON.stringify({
            tag: {
              id: tag.id.primaryKey,
              name: tag.name,
              path: tagPath(tag),
              renamedFrom: oldPath
            }
          }, null, 2);
        })();
        """
    }

    static func deleteTag(_ delete: DeleteTag) throws -> String {
        let tag = try jsonLiteral(delete.tag)

        return """
        (() => {
          \(taskSerializationSupport)

          const input = {
            tag: \(tag),
            dryRun: \(delete.dryRun ? "true" : "false")
          };

          const parts = tagPathParts(input.tag);
          const tag = tagNamedByPath(parts);
          if (!tag) {
            throw new Error(`Tag not found: ${input.tag}`);
          }

          const tagInfo = {
            id: tag.id.primaryKey,
            name: tag.name,
            path: tagPath(tag),
            childCount: tag.tags.length,
            taskCount: tag.flattenedTasks.length
          };

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, tag: tagInfo }, null, 2);
          }

          deleteObject(tag);

          return JSON.stringify({ deleted: true, tag: tagInfo }, null, 2);
        })();
        """
    }

    static func moveTag(_ move: MoveTag) throws -> String {
        let tag = try jsonLiteral(move.tag)
        let newParent = try jsonLiteral(move.newParent)

        return """
        (() => {
          \(taskSerializationSupport)

          const input = {
            tag: \(tag),
            newParent: \(newParent),
            dryRun: \(move.dryRun ? "true" : "false")
          };

          const tagParts = tagPathParts(input.tag);
          const tag = tagNamedByPath(tagParts);
          if (!tag) {
            throw new Error(`Tag not found: ${input.tag}`);
          }

          let newParentTag = null;
          if (input.newParent !== null) {
            const parentParts = tagPathParts(input.newParent);
            newParentTag = tagNamedByPath(parentParts);
            if (!newParentTag) {
              throw new Error(`Destination tag not found: ${input.newParent}`);
            }
          }

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              tag: input,
              meta: {
                from: tagPath(tag),
                to: newParentTag ? tagPath(newParentTag) : null
              }
            }, null, 2);
          }

          const destination = newParentTag ? newParentTag.ending : tags.ending;
          moveTags([tag], destination);

          return JSON.stringify({
            tag: {
              id: tag.id.primaryKey,
              name: tag.name,
              path: tagPath(tag)
            }
          }, null, 2);
        })();
        """
    }

    private static func jsonLiteral<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    private static func optionalJSONAssignment(_ value: String??) -> String {
        guard let value else { return "undefined" }
        guard let value else { return "null" }
        return (try? jsonLiteral(value)) ?? "null"
    }

    private static func optionalIntAssignment(_ value: Int??) -> String {
        guard let value else { return "undefined" }
        guard let value else { return "null" }
        return String(value)
    }

    private static func optionalBoolAssignment(_ value: Bool?) -> String {
        guard let value else { return "undefined" }
        return value ? "true" : "false"
    }

    private static func privacyPrelude(_ privacyScope: PrivacyScope) throws -> String {
        let scopeName = try jsonLiteral(privacyScope.name?.rawValue)
        let folderNames = try jsonLiteral(privacyScope.allowedFolderNames)
        return """
        const privacyScope = \(scopeName);
        const privacyAllowedFolderNames = new Set(\(folderNames));
        const privacyAllowInbox = \(privacyScope.allowInbox ? "true" : "false");
        """
    }
}

private let folderSupport = #"""
function folderForPath(pathStr) {
  const segments = pathStr.split("/").map(s => s.trim()).filter(s => s.length > 0);
  if (segments.length === 0) {
    throw new Error(`Invalid folder path: ${pathStr}`);
  }
  const joined = segments.join("/");
  const exactMatches = flattenedFolders.filter(f => folderPath(f).join("/") === joined);
  if (exactMatches.length === 1) { return exactMatches[0]; }
  if (exactMatches.length > 1) {
    throw new Error(`Ambiguous folder path: ${pathStr} — use a more specific path`);
  }
  if (segments.length === 1) {
    const leafMatches = flattenedFolders.filter(f => f.name === segments[0]);
    if (leafMatches.length === 1) { return leafMatches[0]; }
    if (leafMatches.length > 1) {
      throw new Error(`Ambiguous folder name: ${pathStr} — use a path like Parent/${pathStr}`);
    }
  }
  throw new Error(`Folder not found: ${pathStr}`);
}

function folderAllowedByPrivacyScope(folder) {
  if (!privacyScope) { return true; }
  if (!folder) { return false; }
  return folderPath(folder).some(name => privacyAllowedFolderNames.has(name));
}
"""#

private let markdownNoteSupport = #"""
function escapeMarkdownText(value) {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/\*/g, "\\*")
    .replace(/_/g, "\\_")
    .replace(/`/g, "\\`")
    .replace(/\[/g, "\\[")
    .replace(/\]/g, "\\]");
}

function wrapMarkdownRun(raw, opener, closer) {
  const match = /^([\s\S]*?)(\s*)$/.exec(raw);
  const body = match ? match[1] : raw;
  const trailing = match ? match[2] : "";
  if (body.length === 0) { return escapeMarkdownText(raw); }
  return opener + escapeMarkdownText(body) + closer + trailing;
}

function markdownLinkRun(raw, url) {
  const match = /^([\s\S]*?)(\s*)$/.exec(raw);
  const body = match ? match[1] : raw;
  const trailing = match ? match[2] : "";
  if (body.length === 0) { return escapeMarkdownText(raw); }
  return "[" + escapeMarkdownText(body) + "](" + url + ")" + trailing;
}

function markdownLinkDestination(raw) {
  const trimmed = raw.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.slice(1, -1);
  }
  if (trimmed.startsWith("<") && trimmed.endsWith(">")) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function normalizeOmniMarkdown(markdown) {
  return markdown
    .replace(/^\t•\t/gm, "- ")
    .replace(/^\t◦\t/gm, "  - ")
    .replace(/^•\t/gm, "- ")
    .replace(/^◦\t/gm, "  - ")
    .replace(/\t•\t/g, "\n- ")
    .replace(/\t◦\t/g, "\n  - ")
    .replace(/\t/g, "  ");
}

function markdownRuns(markdown) {
  const runs = [];
  let plain = "";
  const tokenPattern = /(\[([^\]\n]+)\]\((?:"([^"\n]+)"|'([^'\n]+)'|<([^>\n]+)>|([^)\n]+))\))|(\*\*([^*\n]+)\*\*)|(`([^`\n]+)`)|(?<!\*)\*([^*\n]+)\*(?!\*)/g;
  let lastIndex = 0;
  let match;

  while ((match = tokenPattern.exec(markdown)) !== null) {
    if (match.index > lastIndex) {
      plain += markdown.slice(lastIndex, match.index);
    }

    const start = plain.length;
    let text;
    let style = {};

    if (match[1]) {
      const url = markdownLinkDestination(match[3] || match[4] || match[5] || match[6] || "");
      text = match[2] + " (" + url + ")";
    } else if (match[7]) {
      text = match[8];
      style.bold = true;
    } else if (match[9]) {
      text = match[10];
      style.code = true;
    } else {
      text = match[11];
      style.italic = true;
    }

    plain += text;
    runs.push({ start, end: plain.length, style });
    lastIndex = tokenPattern.lastIndex;
  }

  plain += markdown.slice(lastIndex);

  const headingPattern = /(^|\n)(#{1,3}) ([^\n]+)/g;
  while ((match = headingPattern.exec(plain)) !== null) {
    const lineStart = match.index + match[1].length;
    const marker = match[2];
    const content = match[3];
    const markerEnd = lineStart + marker.length + 1;
    plain = plain.slice(0, lineStart) + content + plain.slice(markerEnd + content.length);
    const removed = marker.length + 1;
    runs.forEach(run => {
      if (run.start >= markerEnd) {
        run.start -= removed;
        run.end -= removed;
      }
    });
    runs.push({
      start: lineStart,
      end: lineStart + content.length,
      style: { heading: marker.length }
    });
    headingPattern.lastIndex -= removed;
  }

  return { plain, runs };
}

function textRangeForOffsets(textObj, start, end) {
  const characters = textObj.characters;
  if (start >= end || start >= characters.length) { return null; }
  const startPosition = characters[start].range.start;
  const endPosition = end >= characters.length ? textObj.range.end : characters[end].range.start;
  return new Text.Range(startPosition, endPosition);
}

function setMarkdownNote(task, markdown) {
  const parsed = markdownRuns(markdown || "");
  task.note = parsed.plain;
  const noteObj = task.noteText;

  parsed.runs.forEach(run => {
    const range = textRangeForOffsets(noteObj, run.start, run.end);
    if (!range) { return; }
    const style = noteObj.styleForRange(range);

    if (run.style.bold) {
      style.set(Style.Attribute.FontWeight, 9);
    }
    if (run.style.italic) {
      style.set(Style.Attribute.FontItalic, true);
    }
    if (run.style.code) {
      style.set(Style.Attribute.FontFamily, "Menlo");
      style.set(Style.Attribute.FontFixedPitch, true);
    }
    if (run.style.heading) {
      style.set(Style.Attribute.FontWeight, 9);
      style.set(Style.Attribute.FontSize, run.style.heading === 1 ? 20 : (run.style.heading === 2 ? 17 : 15));
    }
  });
}

function noteTextToMarkdown(noteObj) {
  if (!noteObj || noteObj.range.isEmpty) { return ""; }

  const ranges = noteObj.ranges(TextComponent.AttributeRuns);
  const markdown = ranges.map(range => {
    const raw = noteObj.textInRange(range).string;
    const style = noteObj.styleForRange(range);
    const link = style.get(Style.Attribute.Link);
    const fontWeight = style.get(Style.Attribute.FontWeight);
    const fontItalic = style.get(Style.Attribute.FontItalic);
    const fixedPitch = style.get(Style.Attribute.FontFixedPitch);

    let text = escapeMarkdownText(raw);

    if (fixedPitch) {
      text = wrapMarkdownRun(raw.replace(/`/g, "\\`"), "`", "`");
    }
    if (fontItalic) {
      text = wrapMarkdownRun(raw, "*", "*");
    }
    if (fontWeight >= 7) {
      text = wrapMarkdownRun(raw, "**", "**");
    }
    if (link && link.string && link.string.length > 0) {
      text = raw === link.string ? escapeMarkdownText(raw) : markdownLinkRun(raw, link.string);
    }

    return text;
  }).join("");

  return normalizeOmniMarkdown(markdown);
}
"""#

private let taskSerializationSupport = #"""
function tagPath(tag) {
  const parts = [];
  let current = tag;
  while (current) {
    parts.unshift(current.name);
    current = current.parent;
  }
  return parts.join("/");
}

function tagPathParts(input) {
  return input.split("/").map(part => part.trim()).filter(part => part.length > 0);
}

function rootTagNamed(name) {
  return tags.find(tag => tag.name === name) || null;
}

function childTagNamed(parent, name) {
  return parent.tags.find(tag => tag.name === name) || null;
}

function tagNamedByPath(parts) {
  if (parts.length === 0) { return null; }
  let current = rootTagNamed(parts[0]);
  for (let index = 1; current && index < parts.length; index += 1) {
    current = childTagNamed(current, parts[index]);
  }
  return current || null;
}

function preferredTagForFlatName(name) {
  const status = rootTagNamed("Status");
  if (name === "Work") {
    const workStatus = status ? childTagNamed(status, "Work 💼") : null;
    if (workStatus) { return workStatus; }
  }

  if (status && ["Waiting On"].includes(name)) {
    const statusTag = childTagNamed(status, name);
    if (statusTag) { return statusTag; }
  }

  const exact = flattenedTags.byName(name);
  if (exact) { return exact; }

  return null;
}

function defaultParentForNewFlatTag(name) {
  const status = rootTagNamed("Status");
  if (status && ["Waiting On", "Work"].includes(name)) {
    return status;
  }

  const people = rootTagNamed("People");
  if (people && /\s/.test(name) && !name.startsWith("@")) {
    return people;
  }
  return null;
}

function existingTagNamedOrPath(input) {
  const parts = tagPathParts(input);
  if (parts.length === 0) {
    return { input, tag: null, path: input };
  }

  if (parts.length === 1) {
    const tag = preferredTagForFlatName(parts[0]);
    const parent = tag ? null : defaultParentForNewFlatTag(parts[0]);
    return {
      input,
      tag,
      path: tag ? tagPath(tag) : (parent ? tagPath(parent) + "/" + parts[0] : parts[0])
    };
  }

  return {
    input,
    tag: tagNamedByPath(parts),
    path: parts.join("/")
  };
}

function tagNamedOrCreated(input) {
  const parts = tagPathParts(input);
  if (parts.length === 0) {
    throw new Error("Tag name cannot be empty");
  }

  if (parts.length === 1) {
    const existing = preferredTagForFlatName(parts[0]);
    if (existing) { return existing; }

    const parent = defaultParentForNewFlatTag(parts[0]);
    return parent ? new Tag(parts[0], parent.ending) : new Tag(parts[0]);
  }

  let current = rootTagNamed(parts[0]);
  if (!current) {
    current = new Tag(parts[0]);
  }

  for (let index = 1; index < parts.length; index += 1) {
    let child = childTagNamed(current, parts[index]);
    if (!child) {
      child = new Tag(parts[index], current.ending);
    }
    current = child;
  }

  return current;
}

function iso(date) {
  return date ? date.toISOString() : null;
}

function repeatMethodName(method) {
  if (!method) { return null; }
  if (method === Task.RepetitionMethod.Fixed) { return "fixed"; }
  if (method === Task.RepetitionMethod.DueDate) { return "due"; }
  if (method === Task.RepetitionMethod.DeferUntilDate) { return "defer"; }
  if (method === Task.RepetitionMethod.None) { return "none"; }
  return String(method);
}

function pathForTask(task) {
  if (task.inInbox) { return ["Inbox", task.name]; }
  const parts = [];
  let current = task;
  while (current) {
    parts.unshift(current.name);
    current = current.parent;
  }
  return parts;
}

function folderPath(folder) {
  const names = [];
  let current = folder;
  while (current) {
    names.unshift(current.name);
    current = current.parent;
  }
  return names;
}

const projectFolderNamesById = (() => {
  const map = new Map();
  flattenedFolders.forEach(folder => {
    const path = folderPath(folder);
    folder.children.forEach(child => {
      if (child instanceof Project) {
        map.set(child.id.primaryKey, path);
      }
    });
  });
  return map;
})();

function projectFolderNamesForProject(project) {
  if (!project) { return []; }
  return projectFolderNamesById.get(project.id.primaryKey) || [];
}

function projectFolderNamesForTask(task) {
  const project = task.containingProject;
  return projectFolderNamesForProject(project);
}

function projectAllowedByPrivacyScope(project) {
  if (!privacyScope) { return true; }
  return projectFolderNamesForProject(project).some(name => privacyAllowedFolderNames.has(name));
}

function taskAllowedByPrivacyScope(task) {
  if (!privacyScope) { return true; }
  if (privacyAllowInbox && task.inInbox) { return true; }
  return projectAllowedByPrivacyScope(task.containingProject);
}

function assertTaskAvailableInPrivacyScope(task, message) {
  if (!taskAllowedByPrivacyScope(task)) {
    throw new Error(message || "Task not found or not available in current privacy scope");
  }
}

function assertProjectAvailableInPrivacyScope(project, message) {
  if (!projectAllowedByPrivacyScope(project)) {
    throw new Error(message || "Project not found or not available in current privacy scope");
  }
}

function childTasks(task) {
  return task.children.filter(child => child instanceof Task);
}

function serializeTask(task, includeNotes, includeChildren) {
  const children = childTasks(task);
  const repetitionRule = task.repetitionRule;
  return {
    id: task.id.primaryKey,
    name: task.name,
    note: includeNotes ? noteTextToMarkdown(task.noteText) : undefined,
    notePlain: includeNotes ? (task.note || "") : undefined,
    project: task.containingProject ? task.containingProject.name : null,
    folders: projectFolderNamesForTask(task),
    inInbox: task.inInbox,
    tags: task.tags.map(tag => tag.name),
    tagPaths: task.tags.map(tag => tagPath(tag)),
    deferDate: iso(task.deferDate),
    plannedDate: iso(task.plannedDate),
    dueDate: iso(task.dueDate),
    completionDate: iso(task.completionDate),
    effectiveDeferDate: iso(task.effectiveDeferDate),
    effectivePlannedDate: iso(task.effectivePlannedDate),
    effectiveDueDate: iso(task.effectiveDueDate),
    repeatRule: repetitionRule ? repetitionRule.ruleString : null,
    repeatMethod: repetitionRule ? repeatMethodName(repetitionRule.method) : null,
    repetitionRule: repetitionRule ? {
      ruleString: repetitionRule.ruleString,
      method: repeatMethodName(repetitionRule.method)
    } : null,
    estimatedMinutes: task.estimatedMinutes,
    parent: task.parent ? {
      id: task.parent.id.primaryKey,
      name: task.parent.name
    } : null,
    hasChildren: children.length > 0,
    childCount: children.length,
    sequential: task.sequential,
    completedByChildren: task.completedByChildren,
    children: includeChildren ? children.map(child => serializeTask(child, includeNotes, true)) : undefined,
    flagged: task.flagged,
    completed: task.completed,
    dropped: task.dropDate !== null,
    path: pathForTask(task)
  };
}
"""#
