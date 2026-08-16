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

    public func renameTask(_ rename: RenameTask) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.renameTask(rename, privacyScope: privacyScope))
    }

    public func moveTasks(_ move: MoveTasks) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.moveTasks(move, privacyScope: privacyScope))
    }

    public func updateProjectStatus(_ update: UpdateProjectStatus) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateProjectStatus(update, privacyScope: privacyScope))
    }

    public func moveProject(_ move: MoveProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.moveProject(move, privacyScope: privacyScope))
    }

    public func renameProject(_ rename: RenameProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.renameProject(rename, privacyScope: privacyScope))
    }

    public func updateProjectNote(_ update: UpdateProjectNote) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateProjectNote(update, privacyScope: privacyScope))
    }

    public func updateProjectCompletion(_ update: UpdateProjectCompletion) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateProjectCompletion(update, privacyScope: privacyScope))
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

    public func projects(_ query: ProjectsQuery) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.projectsQuery(query, privacyScope: privacyScope))
    }

    public func reviewProject(_ review: UpdateProjectReview) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateProjectReview(review, privacyScope: privacyScope))
    }

    public func deleteTasks(_ delete: DeleteTasks) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.deleteTasks(delete, privacyScope: privacyScope))
    }

    public func deleteProject(_ delete: DeleteProject) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.deleteProject(delete, privacyScope: privacyScope))
    }

    public func taskState(_ state: StateMutation) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.stateMutation(state, isProject: false, privacyScope: privacyScope))
    }

    public func projectState(_ state: StateMutation) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.stateMutation(state, isProject: true, privacyScope: privacyScope))
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

            // Custom perspectives are resolved BEFORE built-ins. Built-in matching is
            // case-insensitive, so checking it first lets any OmniFocus release that
            // ships a new built-in silently shadow a same-named custom perspective —
            // the built-in's (usually empty) contents get returned with no error. That
            // bug cost us a morning with a custom "Today"; "Completed" and "Changed"
            // are one release away from the same fate.
            const custom = Perspective.Custom.byName(name);
            if (custom) { return custom; }

            const customByIdentifier = Perspective.Custom.byIdentifier(name);
            if (customByIdentifier) { return customByIdentifier; }

            const normalized = name.toLowerCase();
            const builtIn = Perspective.BuiltIn.all.find(p => p.name.toLowerCase() === normalized);
            if (builtIn) { return builtIn; }

            const customInsensitive = Perspective.Custom.all.find(p => p.name.toLowerCase() === normalized);
            if (customInsensitive) { return customInsensitive; }

            throw new Error(`Perspective not found: ${name}`);
          }

          // --- custom perspective rule evaluation ----------------------------------
          // A custom perspective publishes its filter as declarative JSON through
          // `archivedFilterRules`. Evaluating that JSON against the database is the
          // only deterministic way to read a perspective. The alternative — assigning
          // the perspective to a window and walking `window.content.rootNode` — mutates
          // the user's front window AND races the outline's render, silently returning
          // an empty list when the scrape wins. OmniFocus exposes no way to force or
          // await that render (Window has only selectObjects/forecastDay* and
          // Window.content has no members at all), so the race cannot be closed.
          //
          // Unrecognized rules THROW rather than being skipped: a perspective read that
          // quietly ignores a filter it does not understand returns a plausible wrong
          // answer, which is the exact failure mode this function exists to remove.

          // Calendar arithmetic, not fixed millisecond offsets: a month is not 30 days, a
          // year is not 365, and adding raw ms across a DST boundary shifts the result by
          // an hour — enough to flip a task whose date sits near midnight.
          function perspectiveShiftDate(from, component, amount) {
            const d = new Date(from.getTime());
            if (component === "day") { d.setDate(d.getDate() + amount); return d; }
            if (component === "week") { d.setDate(d.getDate() + amount * 7); return d; }
            if (component === "month") { d.setMonth(d.getMonth() + amount); return d; }
            if (component === "year") { d.setFullYear(d.getFullYear() + amount); return d; }
            throw new Error(`Unsupported perspective date component: ${component}`);
          }

          // {} means "unbounded" — OmniFocus emits an empty spec for a one-sided range.
          // Callers MUST null-check the result; `date <= null` coerces to `date <= 0` and
          // silently excludes every task.
          function perspectiveDateBound(spec) {
            if (!spec || Object.keys(spec).length === 0) { return null; }
            if (spec.dynamic === "now") { return new Date(); }
            if (spec.dynamic === "today") { return startOfDay(new Date()); }
            if (typeof spec.relativeAfterAmount === "number") {
              return perspectiveShiftDate(new Date(), spec.relativeComponent, spec.relativeAfterAmount);
            }
            if (typeof spec.relativeBeforeAmount === "number") {
              return perspectiveShiftDate(new Date(), spec.relativeComponent, -spec.relativeBeforeAmount);
            }
            throw new Error(`Unsupported perspective date spec: ${JSON.stringify(spec)}`);
          }

          function perspectiveDateFor(task, field) {
            if (field === "planned") { return task.effectivePlannedDate; }
            if (field === "defer") { return task.effectiveDeferDate; }
            if (field === "due") { return task.effectiveDueDate; }
            if (field === "completed") { return task.effectiveCompletedDate; }
            if (field === "added") { return task.added; }
            if (field === "modified") { return task.modified; }
            throw new Error(`Unsupported perspective date field: ${field}`);
          }

          // Task.Status values are mutually exclusive, so "available" is a set of statuses.
          function perspectiveStatusIsAvailable(status) {
            return status === Task.Status.Available
              || status === Task.Status.Next
              || status === Task.Status.DueSoon
              || status === Task.Status.Overdue;
          }

          function perspectiveAvailabilityMatches(task, availability) {
            if (availability === "remaining") {
              return !taskEffectivelyCompleted(task) && !taskEffectivelyDropped(task);
            }
            if (availability === "completed") { return taskEffectivelyCompleted(task); }
            if (availability === "dropped") { return taskEffectivelyDropped(task); }
            if (availability === "available") {
              return perspectiveStatusIsAvailable(task.taskStatus);
            }
            if (availability === "firstAvailable") {
              // Can't just test Task.Status.Next: Overdue and DueSoon shadow it, so an
              // action stops reporting Next the moment it comes due. Testing for those
              // statuses instead would over-match — every overdue task in the database
              // would qualify, not just the first action of its container. Ask the
              // question directly: is this the first available task among its siblings?
              if (!perspectiveStatusIsAvailable(task.taskStatus)) { return false; }
              const container = task.parent || task.containingProject;
              if (!container) { return true; }
              const siblings = container.children.filter(child => child instanceof Task);
              const first = siblings.find(child => perspectiveStatusIsAvailable(child.taskStatus));
              return first === undefined || first.id.primaryKey === task.id.primaryKey;
            }
            throw new Error(`Unsupported perspective availability: ${availability}`);
          }

          function perspectiveStatusMatches(task, status) {
            // effectiveFlagged, not flagged: a task inherits its flag from a flagged
            // project or action group, and OmniFocus's own filter honors that.
            if (status === "flagged") { return task.effectiveFlagged; }
            if (status === "due") {
              return task.taskStatus === Task.Status.DueSoon || task.taskStatus === Task.Status.Overdue;
            }
            throw new Error(`Unsupported perspective action status: ${status}`);
          }

          // Focus ids may name a folder, a project, or an ancestor action group.
          function perspectiveWithinFocus(task, ids) {
            const wanted = new Set(ids);
            const project = task.containingProject;
            if (project) {
              if (wanted.has(project.id.primaryKey)) { return true; }
              let folder = project.parentFolder;
              while (folder) {
                if (wanted.has(folder.id.primaryKey)) { return true; }
                folder = folder.parent;
              }
            }
            let parent = task.parent;
            while (parent) {
              if (wanted.has(parent.id.primaryKey)) { return true; }
              parent = parent.parent;
            }
            return false;
          }

          function perspectiveProjectStatusMatches(task, wanted) {
            const project = task.containingProject;
            if (!project) { return false; }
            if (wanted === "active") { return project.status === Project.Status.Active; }
            if (wanted === "onHold") { return project.status === Project.Status.OnHold; }
            if (wanted === "done") { return project.status === Project.Status.Done; }
            if (wanted === "dropped") { return project.status === Project.Status.Dropped; }
            if (wanted === "stalled") {
              // "stalled" is not a Project.Status — it means active with nothing actionable.
              if (project.status !== Project.Status.Active) { return false; }
              return !project.flattenedTasks.some(candidate => {
                const status = candidate.taskStatus;
                return status === Task.Status.Available
                  || status === Task.Status.Next
                  || status === Task.Status.DueSoon
                  || status === Task.Status.Overdue;
              });
            }
            throw new Error(`Unsupported perspective project status: ${wanted}`);
          }

          function perspectiveSearchMatches(task, terms) {
            const haystack = ((task.name || "") + " " + (task.note || "")).toLowerCase();
            return terms.every(term => haystack.includes(String(term).toLowerCase()));
          }

          // OmniFocus tag filters are hierarchical: selecting a parent tag surfaces tasks
          // carrying any descendant of it. Matching only directly-assigned tags would make
          // any rule targeting a parent return nothing — and this tag tree is parent-heavy
          // (Context and Status hold no direct assignments at all, only descendants).
          const perspectiveTagFamilyCache = new Map();

          function perspectiveTagFamily(id) {
            const cached = perspectiveTagFamilyCache.get(id);
            if (cached) { return cached; }
            const family = new Set([id]);
            const root = flattenedTags.find(tag => tag.id.primaryKey === id);
            if (root) {
              root.flattenedChildren.forEach(child => family.add(child.id.primaryKey));
            }
            perspectiveTagFamilyCache.set(id, family);
            return family;
          }

          function perspectiveHasTags(task, ids, mode) {
            const taskTagIds = new Set(task.tags.map(tag => tag.id.primaryKey));
            const satisfied = id => {
              const family = perspectiveTagFamily(id);
              for (const tagId of taskTagIds) {
                if (family.has(tagId)) { return true; }
              }
              return false;
            };
            if (mode === "any") { return ids.some(satisfied); }
            return ids.every(satisfied);
          }

          function perspectiveTaskIsGroup(task) {
            return childTasks(task).length > 0;
          }

          // Every recognized key in a single rule object is ANDed together; OmniFocus
          // packs `actionDateField` alongside the date predicate it modifies.
          function perspectiveRuleMatches(task, rule) {
            // A disabled rule is retained in the JSON but must not constrain anything.
            if (rule.disabledRule !== undefined) { return true; }
            if (rule.aggregateRules !== undefined) {
              return perspectiveRulesMatch(task, rule.aggregateRules, rule.aggregateType);
            }

            const dateField = rule.actionDateField !== undefined ? rule.actionDateField : "due";

            for (const key of Object.keys(rule)) {
              const value = rule[key];
              switch (key) {
                case "actionDateField":
                  break;
                case "actionAvailability":
                  if (!perspectiveAvailabilityMatches(task, value)) { return false; }
                  break;
                case "actionStatus":
                  if (!perspectiveStatusMatches(task, value)) { return false; }
                  break;
                case "actionIsLeaf":
                  if (perspectiveTaskIsGroup(task) === value) { return false; }
                  break;
                case "actionIsProjectOrGroup":
                  if (perspectiveTaskIsGroup(task) !== value) { return false; }
                  break;
                case "actionIsInSingleActionsList": {
                  // OmniJS spells this `containsSingletonActions`; `singletonActionHolder`
                  // is the AppleScript name and reads back undefined here, which silently
                  // made this rule match nothing.
                  const project = task.containingProject;
                  const singleton = project !== null && project.containsSingletonActions === true;
                  if (singleton !== value) { return false; }
                  break;
                }
                case "actionRepeats":
                  if ((task.repetitionRule !== null) !== value) { return false; }
                  break;
                case "actionHasDeferDate":
                  if ((task.effectiveDeferDate !== null) !== value) { return false; }
                  break;
                case "actionHasPlannedDate":
                  if ((task.effectivePlannedDate !== null) !== value) { return false; }
                  break;
                case "actionHasAnyOfTags":
                  if (!perspectiveHasTags(task, value, "any")) { return false; }
                  break;
                case "actionHasAllOfTags":
                  if (!perspectiveHasTags(task, value, "all")) { return false; }
                  break;
                case "actionWithinFocus":
                  if (!perspectiveWithinFocus(task, value)) { return false; }
                  break;
                case "actionHasProjectWithStatus":
                  if (!perspectiveProjectStatusMatches(task, value)) { return false; }
                  break;
                case "actionMatchingSearch":
                  if (!perspectiveSearchMatches(task, value)) { return false; }
                  break;
                case "actionWithinDuration": {
                  const minutes = task.estimatedMinutes;
                  if (minutes === null || minutes > value) { return false; }
                  break;
                }
                case "actionDateIsToday": {
                  const date = perspectiveDateFor(task, dateField);
                  const today = startOfDay(new Date());
                  const isToday = date !== null && date >= today && date < addDays(today, 1);
                  if (isToday !== value) { return false; }
                  break;
                }
                case "actionDateIsInTheNext": {
                  const date = perspectiveDateFor(task, dateField);
                  if (date === null) { return false; }
                  const now = new Date();
                  const bound = perspectiveDateBound(value);
                  if (!(date >= now && date <= bound)) { return false; }
                  break;
                }
                case "actionDateIsInThePast": {
                  const date = perspectiveDateFor(task, dateField);
                  if (date === null) { return false; }
                  const now = new Date();
                  const bound = perspectiveDateBound(value);
                  if (!(date <= now && date >= bound)) { return false; }
                  break;
                }
                case "actionDateIsBeforeDateSpec": {
                  const bound = perspectiveDateBound(value);
                  if (bound === null) { break; }
                  const date = perspectiveDateFor(task, dateField);
                  if (date === null || !(date < bound)) { return false; }
                  break;
                }
                case "actionDateIsAfterDateSpec": {
                  const bound = perspectiveDateBound(value);
                  if (bound === null) { break; }
                  const date = perspectiveDateFor(task, dateField);
                  if (date === null || !(date > bound)) { return false; }
                  break;
                }
                default:
                  throw new Error(`Unsupported perspective rule: ${key}`);
              }
            }
            return true;
          }

          function perspectiveRulesMatch(task, allRules, aggregateType) {
            const type = aggregateType || "all";
            // A rule the user switched off in the perspective editor is retained in the
            // JSON wrapped as `disabledRule`. It must be REMOVED from the group, not
            // treated as true: inside an `any` group an always-true member matches every
            // task (a disabled rule silently turned "Due Soon" into 447 of 475), and
            // inside `none` it would exclude everything.
            const rules = allRules.filter(rule => rule.disabledRule === undefined);
            if (rules.length === 0) {
              // An emptied group constrains nothing; `none` of nothing excludes nothing.
              return true;
            }
            if (type === "all") { return rules.every(rule => perspectiveRuleMatches(task, rule)); }
            if (type === "any") { return rules.some(rule => perspectiveRuleMatches(task, rule)); }
            if (type === "none") { return !rules.some(rule => perspectiveRuleMatches(task, rule)); }
            throw new Error(`Unsupported perspective aggregate type: ${type}`);
          }

          // Built-ins publish no rules, so they still need the window walk. Guard it so
          // a failed assignment or an unrendered outline is an error, not a silent zero.
          function tasksInBuiltInPerspective(perspective, name) {
            const win = document.windows[0];
            const originalPerspective = win.perspective;
            const seen = new Set();
            const tasks = [];

            try {
              win.perspective = perspective;
              if (win.perspective !== perspective) {
                throw new Error(`Could not switch window to perspective: ${name}`);
              }
              const rootNode = win.content ? win.content.rootNode : null;
              if (!rootNode) {
                throw new Error(`Perspective "${name}" produced no window content tree`);
              }
              rootNode.apply(node => {
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

          // A perspective whose rules ask for completed/dropped tasks must not then have
          // them stripped by the default outer filter. These are set while resolving the
          // perspective and consulted by the main predicate below.
          let perspectiveSelectsCompleted = false;
          let perspectiveSelectsDropped = false;

          function noteAvailabilitySelections(rules) {
            (function walk(rule) {
              if (Array.isArray(rule)) { return rule.forEach(walk); }
              if (!rule || typeof rule !== "object") { return; }
              Object.keys(rule).forEach(key => {
                if (key === "disabledRule") { return; }
                if (key === "actionAvailability") {
                  if (rule[key] === "completed") { perspectiveSelectsCompleted = true; }
                  if (rule[key] === "dropped") { perspectiveSelectsDropped = true; }
                  return;
                }
                walk(rule[key]);
              });
            })(rules);
          }

          function tasksInPerspective(name) {
            const perspective = perspectiveNamed(name);

            if (perspective instanceof Perspective.Custom) {
              const rules = perspective.archivedFilterRules;
              // `!rules` alone lets an empty array through, and an empty rule list matches
              // every task — the perspective would silently resolve to the whole database.
              if (!rules || rules.length === 0) {
                throw new Error(`Perspective "${name}" exposes no filter rules`);
              }
              noteAvailabilitySelections(rules);
              const source = privacyScope ? privacyScopedSourceTasks() : flattenedTasks;
              return source.filter(task => perspectiveRulesMatch(task, rules, "all"));
            }

            return tasksInBuiltInPerspective(perspective, name);
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

            if (filter === "all") { return true; }

            if (filter === "none") {
              return !date;
            }

            if (filter === "now") {
              if (!date) { return emptyMatchesNow; }
              return date <= now;
            }

            if (filter === "today") {
              if (!date) { return emptyMatchesNow; }
              if (emptyMatchesNow) {
                // availability semantics: available at any point today (past or future within today)
                return date < addDays(today, 1);
              }
              return date >= today && date < addDays(today, 1);
            }

            if (!date) { return false; }
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

          // Enumerate the smallest set of tasks that could contain a privacy-allowed
          // match. When a privacy scope is active (e.g. the work scope on a work
          // machine), this walks only the inbox (if allowed) and the projects whose
          // folder is in scope — it NEVER traverses personal folders. That makes the
          // privacy scope a real query boundary rather than a post-filter, and is
          // also the dominant speedup: OmniFocus's global `flattenedTasks` getter
          // walks the ENTIRE database (personal included) and is by far the slowest
          // step. The predicate below still applies every filter — including the
          // privacy check — so results are identical to filtering flattenedTasks:
          // the only tasks skipped here are ones that could never pass the scope
          // (personal-folder tasks), plus project root tasks and project-less
          // orphans, both of which the predicate already excludes.
          function privacyScopedSourceTasks() {
            const out = [];
            if (privacyAllowInbox) {
              inbox.forEach(task => out.push(task));
            }
            flattenedProjects.forEach(project => {
              if (!projectAllowedByPrivacyScope(project)) { return; }
              project.flattenedTasks.forEach(task => out.push(task));
            });
            return out;
          }

          const sourceTasks = perspectiveName
            ? tasksInPerspective(perspectiveName)
            : (privacyScope ? privacyScopedSourceTasks() : flattenedTasks);
          const matchedTasks = sourceTasks.filter(task => {
            if (projectIds.has(task.id.primaryKey)) { return false; }
            if (!task.inInbox && task.parent === null && task.containingProject !== null) { return false; }
            if (!taskAllowedByPrivacyScope(task)) { return false; }
            if (availableFilter !== null) {
              // --available implies filtering to active tasks; completed/dropped are never available
              if (taskEffectivelyCompleted(task) || taskEffectivelyDropped(task)) { return false; }
              // a task under an on-hold/done/dropped project is never available, at any date
              const container = task.containingProject;
              if (container !== null && container.status !== Project.Status.Active) { return false; }
              // point-in-time query: honor OmniFocus blocking too (sequential predecessors,
              // on-hold ancestors) — matches what the OF UI shows as available right now
              if (availableFilter === "now" && task.taskStatus === Task.Status.Blocked) { return false; }
            } else {
              // no --available flag: raw mode — respect explicit --include-completed / --include-dropped flags only.
              // A perspective that explicitly selects completed/dropped tasks implies the
              // matching flag: otherwise its own result set is stripped back out here and
              // the command reports an empty perspective with no error.
              if (!includeCompleted && !completedFilter && !perspectiveSelectsCompleted && taskEffectivelyCompleted(task)) { return false; }
              if (!includeDropped && !perspectiveSelectsDropped && taskEffectivelyDropped(task)) { return false; }
            }
            if (!projectMatches(task)) { return false; }
            if (!folderMatches(task)) { return false; }
            if (!tagMatches(task)) { return false; }
            if (flaggedOnly && !task.flagged) { return false; }
            if (!dateMatches(task.effectiveDeferDate || task.deferDate, availableFilter, true)) { return false; }
            if (!dateMatches(task.effectivePlannedDate || task.plannedDate, plannedFilter, false)) { return false; }
            if (!dateMatches(task.deferDate, deferredFilter, false)) { return false; }
            if (!dateMatches(task.effectiveDueDate || task.dueDate, dueFilter, false)) { return false; }
            if (!repeatRuleMatches(task, repeatRuleFilter)) { return false; }
            if (!dateMatches(task.effectiveCompletedDate || task.completionDate, completedFilter, false)) { return false; }
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
        let folder = try jsonLiteral(task.folder)
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
          \(folderSupport)

          const input = {
            name: \(name),
            project: \(project),
            folder: \(folder),
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
            if (input.folder !== null) {
              const folder = folderForPath(input.folder);
              const folderProjectMatches = flattenedProjects.filter(project => (
                project.name === name && projectFolderNamesForProject(project).join("/") === folderPath(folder).join("/")
              ));
              if (folderProjectMatches.length === 1) { return { project: folderProjectMatches[0], created: false }; }
              if (folderProjectMatches.length > 1) {
                throw new Error(`Ambiguous project in folder: ${input.folder}/${name}`);
              }
              return { project: null, created: false };
            }
            return { project: resolveProjectByNameOrId(name), created: false };
          }

          function projectNamedOrCreated(name) {
            if (!name) { return { project: null, created: false }; }
            const existingResult = existingProjectNamed(name);
            const existing = existingResult.project;
            if (existing) { return { project: existing, created: false }; }
            if (input.folder !== null) {
              const folder = folderForPath(input.folder);
              if (!folderAllowedByPrivacyScope(folder)) {
                throw new Error(`Destination folder not available in current privacy scope: ${input.folder}`);
              }
              return { project: new Project(name, folder.ending), created: true };
            }
            if (privacyScope) {
              throw new Error(`Creating a project at the top level is not allowed in the current privacy scope`);
            }
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
            if (input.folder !== null) {
              const folder = folderForPath(input.folder);
              if (!folderAllowedByPrivacyScope(folder)) {
                throw new Error(`Destination folder not available in current privacy scope: ${input.folder}`);
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
        let ids = try jsonLiteral(task.ids)
        let name = try jsonLiteral(task.name)
        let project = optionalJSONAssignment(task.project)
        let folder = try jsonLiteral(task.folder)
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
          \(folderSupport)

          const input = {
            ids: \(ids),
            name: \(name),
            project: \(project),
            folder: \(folder),
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
            createProjectIfMissing: \(task.createProjectIfMissing ? "true" : "false"),
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

          const allowedFolderList = Array.from(privacyAllowedFolderNames);
          const effectiveFolder = input.folder !== null
            ? input.folder
            : ((privacyScope && allowedFolderList.length === 1) ? allowedFolderList[0] : null);

          function existingProjectNamed(name) {
            if (!name) { return { project: null, created: false }; }
            // Only constrain resolution to a folder when the caller EXPLICITLY
            // passed --folder. effectiveFolder (the privacy-scope default) is a
            // creation destination only — using it to filter resolution would
            // exclude every project living in a subfolder of the allowed folder.
            if (input.folder !== null) {
              const folder = folderForPath(input.folder);
              const folderProjectMatches = flattenedProjects.filter(project => (
                project.name === name && projectFolderNamesForProject(project).join("/") === folderPath(folder).join("/")
              ));
              if (folderProjectMatches.length === 1) { return { project: folderProjectMatches[0], created: false }; }
              if (folderProjectMatches.length > 1) {
                throw new Error(`Ambiguous project in folder: ${input.folder}/${name}`);
              }
              return { project: null, created: false };
            }
            return { project: resolveProjectByNameOrId(name), created: false };
          }

          function projectNamedOrCreated(name) {
            if (!name) { return { project: null, created: false }; }
            const existingResult = existingProjectNamed(name);
            const existing = existingResult.project;
            if (existing) { return { project: existing, created: false }; }
            if (effectiveFolder !== null) {
              const folder = folderForPath(effectiveFolder);
              if (!folderAllowedByPrivacyScope(folder)) {
                throw new Error(`Destination folder not available in current privacy scope: ${effectiveFolder}`);
              }
              return { project: new Project(name, folder.ending), created: true };
            }
            if (privacyScope) {
              throw new Error(`Creating a project at the top level is not allowed in the current privacy scope`);
            }
            return { project: new Project(name, library.ending), created: true };
          }

          const resolvedTasks = input.ids.map(id => {
            const t = Task.byIdentifier(id);
            if (!t || !taskAllowedByPrivacyScope(t)) {
              throw new Error(`Task not found or not available in current privacy scope: ${id}`);
            }
            return t;
          });

          const resolvedProjectResult = input.project === undefined || input.project === null
            ? { project: null, created: false }
            : existingProjectNamed(input.project);
          if (privacyScope && resolvedProjectResult.project && !projectAllowedByPrivacyScope(resolvedProjectResult.project)) {
            throw new Error(`Project not found or not available in current privacy scope: ${input.project}`);
          }
          if (!input.createProjectIfMissing && input.project !== undefined && input.project !== null && !resolvedProjectResult.project) {
            throw new Error(`Project not found: ${input.project}`);
          }
          const dryRunAddTags = input.addTags.map(name => existingTagNamedOrPath(name));
          const dryRunRemoveTags = input.removeTags.map(name => existingTagNamedOrPath(name));

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              tasks: resolvedTasks.map(t => ({ id: t.id.primaryKey, name: t.name })),
              meta: {
                privacyScope,
                projectExists: input.project !== undefined && input.project !== null ? resolvedProjectResult.project !== null : null,
                wouldCreateProject: input.project !== undefined && input.project !== null && resolvedProjectResult.project === null && input.createProjectIfMissing,
                folder: input.project !== undefined && input.project !== null ? effectiveFolder : null,
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
          if (input.project !== undefined) {
            const projectResult = input.project === null
              ? { project: null, created: false }
              : (input.createProjectIfMissing ? projectNamedOrCreated(input.project) : existingProjectNamed(input.project));
            if (input.project !== null && !projectResult.project) {
              throw new Error(`Project not found: ${input.project}`);
            }
            projectCreated = projectResult.created;
            const insertion = projectResult.project === null ? inbox.ending : projectResult.project.ending;
            moveTasks(resolvedTasks, insertion);
          }

          const resultTasks = resolvedTasks.map(task => {
            if (input.name !== null) { task.name = input.name; }
            if (input.note !== null) { setMarkdownNote(task, input.note); }
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
            if (input.incomplete) { task.markIncomplete(); }
            if (input.complete) { resultTask = task.markComplete(parseDate(input.completedAt)); }
            if (input.drop) { task.drop(input.dropAllOccurrences); }
            if (input.skip) { task.drop(false); }

            return serializeTask(resultTask, false, input.sequential !== undefined || input.completedByChildren !== undefined);
          });

          return JSON.stringify({
            tasks: resultTasks,
            meta: {
              privacyScope,
              createdProject: projectCreated
            }
          }, null, 2);
        })();
        """
    }

    static func renameTask(_ rename: RenameTask, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let id = try jsonLiteral(rename.id)
        let newName = try jsonLiteral(rename.newName)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            id: \(id),
            newName: \(newName),
            dryRun: \(rename.dryRun ? "true" : "false")
          };

          const task = Task.byIdentifier(input.id);
          if (!task || !taskAllowedByPrivacyScope(task)) {
            throw new Error(`Task not found or not available in current privacy scope: ${input.id}`);
          }

          const previousName = task.name;
          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              task: {
                id: task.id.primaryKey,
                name: previousName,
                newName: input.newName
              },
              meta: { privacyScope }
            }, null, 2);
          }

          task.name = input.newName;

          return JSON.stringify({
            task: serializeTask(task, false, false),
            meta: {
              privacyScope,
              previousName
            }
          }, null, 2);
        })();
        """
    }

    static func moveTasks(_ move: MoveTasks, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let ids = try jsonLiteral(move.ids)
        let destinationKind: String
        let destinationTarget: String?
        switch move.destination {
        case .before(let id):
            destinationKind = "before"
            destinationTarget = id
        case .after(let id):
            destinationKind = "after"
            destinationTarget = id
        case .project(let name):
            destinationKind = "project"
            destinationTarget = name
        case .parent(let id):
            destinationKind = "parent"
            destinationTarget = id
        case .inbox:
            destinationKind = "inbox"
            destinationTarget = nil
        }
        let kind = try jsonLiteral(destinationKind)
        let target = try jsonLiteral(destinationTarget)
        let position = try jsonLiteral(move.position.rawValue)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            ids: \(ids),
            destination: {
              kind: \(kind),
              target: \(target),
              position: \(position)
            },
            dryRun: \(move.dryRun ? "true" : "false")
          };

          function taskById(id, role) {
            const task = Task.byIdentifier(id);
            if (!task || !taskAllowedByPrivacyScope(task)) {
              throw new Error(`${role} task not found or not available in current privacy scope: ${id}`);
            }
            return task;
          }

          function isDescendantOf(task, possibleAncestor) {
            let current = task.parent;
            while (current) {
              if (current.id.primaryKey === possibleAncestor.id.primaryKey) { return true; }
              current = current.parent;
            }
            return false;
          }

          function assertNoSourceTargetConflict(resolvedTasks, targetTask, label) {
            if (!targetTask) { return; }
            resolvedTasks.forEach(task => {
              if (task.id.primaryKey === targetTask.id.primaryKey) {
                throw new Error(`Cannot move a task ${label} itself: ${task.id.primaryKey}`);
              }
              if (isDescendantOf(targetTask, task)) {
                throw new Error(`Cannot move a task ${label} its own descendant: ${task.name}`);
              }
            });
          }

          const resolvedTasks = input.ids.map(id => taskById(id, "Source"));
          const sourceIds = new Set(resolvedTasks.map(task => task.id.primaryKey));
          if (sourceIds.size !== resolvedTasks.length) {
            throw new Error("task-move source task ids must be unique");
          }

          let destinationLocation;
          let destinationInfo;

          switch (input.destination.kind) {
          case "before": {
            const targetTask = taskById(input.destination.target, "Target");
            assertNoSourceTargetConflict(resolvedTasks, targetTask, "before");
            destinationLocation = targetTask.before;
            destinationInfo = { kind: "before", task: { id: targetTask.id.primaryKey, name: targetTask.name } };
            break;
          }
          case "after": {
            const targetTask = taskById(input.destination.target, "Target");
            assertNoSourceTargetConflict(resolvedTasks, targetTask, "after");
            destinationLocation = targetTask.after;
            destinationInfo = { kind: "after", task: { id: targetTask.id.primaryKey, name: targetTask.name } };
            break;
          }
          case "project": {
            const project = resolveProjectByNameOrId(input.destination.target);
            if (!project) { throw new Error(`Project not found: ${input.destination.target}`); }
            assertProjectAvailableInPrivacyScope(project, `Project not available in current privacy scope: ${input.destination.target}`);
            destinationLocation = input.destination.position === "beginning" ? project.beginning : project.ending;
            destinationInfo = { kind: "project", project: { id: project.id.primaryKey, name: project.name }, position: input.destination.position };
            break;
          }
          case "parent": {
            const parentTask = taskById(input.destination.target, "Parent");
            assertNoSourceTargetConflict(resolvedTasks, parentTask, "under");
            destinationLocation = input.destination.position === "beginning" ? parentTask.beginning : parentTask.ending;
            destinationInfo = { kind: "parent", task: { id: parentTask.id.primaryKey, name: parentTask.name }, position: input.destination.position };
            break;
          }
          case "inbox": {
            if (privacyScope && !privacyAllowInbox) {
              throw new Error("Inbox is not available in current privacy scope");
            }
            destinationLocation = input.destination.position === "beginning" ? inbox.beginning : inbox.ending;
            destinationInfo = { kind: "inbox", position: input.destination.position };
            break;
          }
          default:
            throw new Error(`Unsupported task move destination: ${input.destination.kind}`);
          }

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              tasks: resolvedTasks.map(task => ({ id: task.id.primaryKey, name: task.name })),
              destination: destinationInfo,
              meta: { privacyScope }
            }, null, 2);
          }

          moveTasks(resolvedTasks, destinationLocation);

          return JSON.stringify({
            tasks: resolvedTasks.map(task => serializeTask(task, false, false)),
            destination: destinationInfo,
            meta: { privacyScope }
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
            const project = resolveProjectByNameOrId(name);
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
            const project = resolveProjectByNameOrId(name);
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

    static func renameProject(_ rename: RenameProject, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(rename.project)
        let newName = try jsonLiteral(rename.newName)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            project: \(project),
            newName: \(newName),
            dryRun: \(rename.dryRun ? "true" : "false")
          };

          function projectNamed(name) {
            const project = resolveProjectByNameOrId(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          const project = projectNamed(input.project);
          assertProjectAvailableInPrivacyScope(project, `Project not found or not available in current privacy scope: ${input.project}`);

          const previousName = project.name;
          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              project: {
                id: project.id.primaryKey,
                name: previousName,
                newName: input.newName
              },
              meta: { privacyScope }
            }, null, 2);
          }

          project.name = input.newName;

          return JSON.stringify({
            project: {
              id: project.id.primaryKey,
              name: project.name,
              previousName,
              folder: projectFolderNamesForProject(project)
            },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func updateProjectCompletion(_ update: UpdateProjectCompletion, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(update.project)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)

          const input = {
            project: \(project),
            completeWithLastAction: \(update.completeWithLastAction ? "true" : "false"),
            dryRun: \(update.dryRun ? "true" : "false")
          };

          function projectNamed(name) {
            const project = resolveProjectByNameOrId(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          const project = projectNamed(input.project);
          assertProjectAvailableInPrivacyScope(project, `Project not found or not available in current privacy scope: ${input.project}`);
          if (project.containsSingletonActions) {
            throw new Error(`Complete with last action only applies to parallel and sequential projects: ${input.project}`);
          }

          const previousCompleteWithLastAction = project.completedByChildren;
          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              project: {
                id: project.id.primaryKey,
                name: project.name,
                sequential: project.sequential,
                completeWithLastAction: input.completeWithLastAction,
                previousCompleteWithLastAction
              },
              meta: { privacyScope }
            }, null, 2);
          }

          project.completedByChildren = input.completeWithLastAction;

          return JSON.stringify({
            project: {
              id: project.id.primaryKey,
              name: project.name,
              sequential: project.sequential,
              completeWithLastAction: project.completedByChildren,
              previousCompleteWithLastAction
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

    static func projectsQuery(_ query: ProjectsQuery, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let folder = try jsonLiteral(query.folder)
        let status = try jsonLiteral(query.status?.rawValue)
        let limit = query.limit.map(String.init) ?? "null"
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(markdownNoteSupport)
          \(taskSerializationSupport)
          \(projectSerializationSupport)

          const folderFilter = \(folder);
          const statusFilter = \(status);
          const dueForReview = \(query.dueForReview ? "true" : "false");
          const includeNotes = \(query.includeNotes ? "true" : "false");
          const limit = \(limit);
          const now = new Date();

          const matched = flattenedProjects.filter(project => {
            if (!projectAllowedByPrivacyScope(project)) { return false; }
            if (folderFilter && !projectFolderNamesForProject(project).includes(folderFilter)) { return false; }
            if (statusFilter && projectStatusName(project.status) !== statusFilter) { return false; }
            if (dueForReview) {
              // Mirror OmniFocus's native Review perspective: only active/on-hold
              // projects appear for review — completed/dropped never do.
              const reviewStatus = projectStatusName(project.status);
              if (reviewStatus === "completed" || reviewStatus === "dropped") { return false; }
              if (!(project.nextReviewDate && project.nextReviewDate <= now)) { return false; }
            }
            return true;
          });

          const returned = limit === null ? matched : matched.slice(0, limit);
          const projects = returned.map(p => serializeProject(p, includeNotes));

          return JSON.stringify({
            projects,
            meta: {
              folder: folderFilter,
              status: statusFilter,
              dueForReview,
              privacyScope,
              total: matched.length,
              count: projects.length,
              limit,
              truncated: limit !== null && matched.length > limit
            }
          }, null, 2);
        })();
        """
    }

    static func updateProjectReview(_ review: UpdateProjectReview, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let project = try jsonLiteral(review.project)
        let interval = optionalJSONAssignment(review.interval)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(privacy)
          \(taskSerializationSupport)
          \(projectSerializationSupport)

          const input = {
            project: \(project),
            markReviewed: \(review.markReviewed ? "true" : "false"),
            interval: \(interval),
            dryRun: \(review.dryRun ? "true" : "false")
          };

          // Validate the interval spec WITHOUT touching the database, so `--dry-run`
          // rejects exactly what a real run would. Returns {steps, unit} or throws.
          function parseIntervalSpec(spec) {
            if (!spec) {
              // OmniFocus rejects a null reviewInterval outright ("must be set to a
              // non-null value"), so there is no way to clear one. Fail with an
              // actionable message instead of surfacing the raw bridge error.
              throw new Error("OmniFocus does not allow clearing a review interval — every project must have one. Set a long interval instead, e.g. --interval 1y.");
            }
            const match = /^(\\d+)([dwmy])$/.exec(spec);
            if (!match) { throw new Error(`Invalid interval spec "${spec}" — use format like 1w, 2m, 3d, 1y`); }
            const unitMap = {
              d: "days",
              w: "weeks",
              m: "months",
              y: "years"
            };
            return { steps: Number(match[1]), unit: unitMap[match[2]] };
          }

          // OmniJS gives no way to *construct* a review interval. All four obvious routes
          // were tried against a live database and all fail:
          //   - the constructor form throws "CallbackObject is not a constructor"
          //   - calling the type as a function throws "is not a function"
          //   - an object built from its prototype is rejected by the setter
          //   - a plain {steps, unit} object is rejected by the setter
          // The only working path is to mutate the project's own existing instance and
          // assign it back. Deliberately NOT borrowing an instance from another project:
          // that would hinge on reads returning a copy, and if that ever stopped holding
          // it would silently rewrite an unrelated (possibly out-of-privacy-scope)
          // project's cadence. OmniFocus guarantees every project has an interval, so the
          // fallback is a loud error, not a cross-project write.
          function applyReviewInterval(project, parsed) {
            const interval = project.reviewInterval;
            if (!interval) {
              throw new Error("Cannot set a review interval: this project has none to modify, and OmniJS provides no way to construct one. Set any interval on this project in OmniFocus first.");
            }
            interval.steps = parsed.steps;
            interval.unit = parsed.unit;
            project.reviewInterval = interval;
          }

          const project = resolveProjectByNameOrId(input.project);
          if (!project) { throw new Error(`Project not found: ${input.project}`); }
          assertProjectAvailableInPrivacyScope(project, `Project not available in current privacy scope: ${input.project}`);

          // Parse before the dry-run return so a preview fails on exactly what a real run
          // would. docs/claude-integration.md tells callers to dry-run first; a green
          // preview followed by a hard failure would make that advice actively misleading.
          const parsedInterval = input.interval !== undefined ? parseIntervalSpec(input.interval) : null;

          // A never-reviewed project has no lastReviewDate to derive nextReviewDate from,
          // so changing its interval cannot move it into the review queue. Report that
          // rather than letting the caller assume the new cadence took effect.
          const willRecomputeNextReview = parsedInterval === null
            ? null
            : Boolean(input.markReviewed || project.lastReviewDate);

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              project: serializeProject(project),
              meta: { privacyScope, interval: parsedInterval, nextReviewDateRecomputed: willRecomputeNextReview }
            }, null, 2);
          }

          if (parsedInterval) {
            applyReviewInterval(project, parsedInterval);
            // Setting the interval alone does NOT recompute nextReviewDate; OmniFocus only
            // derives it when lastReviewDate is assigned. Without this, `--interval` looks
            // like a no-op until the project is next reviewed. Re-assigning the existing
            // value forces the recompute while preserving real review history. Skipped when
            // --mark-reviewed will overwrite it below anyway.
            if (!input.markReviewed && project.lastReviewDate) {
              project.lastReviewDate = project.lastReviewDate;
            }
          }
          if (input.markReviewed) {
            // OmniFocus has no project.markReviewed() method; setting lastReviewDate to now
            // recomputes nextReviewDate from the review interval, which is what "mark reviewed" means.
            project.lastReviewDate = new Date();
          }

          return JSON.stringify({
            project: serializeProject(project),
            meta: { privacyScope, nextReviewDateRecomputed: willRecomputeNextReview }
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

          const project = resolveProjectByNameOrId(input.project);
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
          // Fall back to an identifier lookup: duplicate tag names under one parent
          // produce an ambiguous path, and the id is then the only way to name the
          // specific tag to delete.
          const tag = tagNamedByPath(parts) || flattenedTags.find(t => t.id.primaryKey === input.tag);
          if (!tag) {
            throw new Error(`Tag not found: ${input.tag}`);
          }

          // Deleting a tag also deletes its descendants and their assignments, so a count
          // of only directly-assigned tasks understates an irreversible delete. Reporting
          // "0 tasks" for a parent tag whose children hold hundreds is how a dry-run gives
          // false confidence.
          const tagDescendants = tag.flattenedChildren;
          const tagDescendantTaskIds = new Set();
          tagDescendants.forEach(child => {
            child.tasks.forEach(task => tagDescendantTaskIds.add(task.id.primaryKey));
          });
          tag.tasks.forEach(task => tagDescendantTaskIds.add(task.id.primaryKey));

          const tagInfo = {
            id: tag.id.primaryKey,
            name: tag.name,
            path: tagPath(tag),
            childCount: tag.tags.length,
            descendantTagCount: tagDescendants.length,
            // Tag has no `flattenedTasks` in OmniJS — reading it threw a TypeError and
            // made tag-delete unusable, dry-run included.
            taskCount: tag.tasks.length,
            remainingTaskCount: tag.remainingTasks.length,
            // What the delete actually touches, including via child tags.
            affectedTaskCount: tagDescendantTaskIds.size
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

    static func updateProjectNote(_ update: UpdateProjectNote, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let identifier = try jsonLiteral(update.project)
        let mode = try jsonLiteral(update.mode.rawValue)
        let text = try jsonLiteral(update.text)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)
          \(stateBlockSupport)
          \(projectNoteSupport)

          const input = {
            identifier: \(identifier),
            mode: \(mode),
            text: \(text),
            dryRun: \(update.dryRun ? "true" : "false")
          };

          const project = resolveProjectByNameOrId(input.identifier);
          if (!project) { throw new Error(`Project not found: ${input.identifier}`); }
          assertProjectAvailableInPrivacyScope(project, `Project not found or not available in current privacy scope: ${input.identifier}`);

          const newMarkdown = applyProjectNoteEdit(project, input.mode, input.text);

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              project: { id: project.id.primaryKey, name: project.name, note: newMarkdown },
              meta: { privacyScope }
            }, null, 2);
          }

          setMarkdownNote(project, newMarkdown);

          return JSON.stringify({
            project: { id: project.id.primaryKey, name: project.name, note: newMarkdown },
            meta: { privacyScope }
          }, null, 2);
        })();
        """
    }

    static func stateMutation(_ state: StateMutation, isProject: Bool, privacyScope: PrivacyScope = .unrestricted) throws -> String {
        let identifier = try jsonLiteral(state.identifier)
        let sets = try jsonLiteral(state.sets.map { ["key": $0.key, "value": $0.value] })
        let increments = try jsonLiteral(state.increments)
        let clearKeys = try jsonLiteral(state.clearKeys)
        let privacy = try privacyPrelude(privacyScope)

        return """
        (() => {
          \(markdownNoteSupport)
          \(privacy)
          \(taskSerializationSupport)
          \(stateBlockSupport)

          const input = {
            identifier: \(identifier),
            isProject: \(isProject ? "true" : "false"),
            get: \(state.get ? "true" : "false"),
            sets: \(sets),
            increments: \(increments),
            clearKeys: \(clearKeys),
            clearAll: \(state.clearAll ? "true" : "false"),
            dryRun: \(state.dryRun ? "true" : "false")
          };

          let target;
          if (input.isProject) {
            target = resolveProjectByNameOrId(input.identifier);
            if (!target) { throw new Error(`Project not found: ${input.identifier}`); }
            assertProjectAvailableInPrivacyScope(target, `Project not found or not available in current privacy scope: ${input.identifier}`);
          } else {
            target = Task.byIdentifier(input.identifier);
            if (!target || !taskAllowedByPrivacyScope(target)) {
              throw new Error(`Task not found or not available in current privacy scope: ${input.identifier}`);
            }
          }

          const parsed = parseStateBlock(noteTextToMarkdown(target.noteText));

          if (input.get) {
            return JSON.stringify({
              id: target.id.primaryKey,
              isProject: input.isProject,
              hasBlock: parsed.hasBlock,
              order: parsed.order,
              state: parsed.state,
              meta: { privacyScope }
            }, null, 2);
          }

          let stateMap = parsed.state;
          let order = parsed.order.slice();
          const ensureKey = (k) => { if (order.indexOf(k) === -1) { order.push(k); } };

          if (input.clearAll) {
            stateMap = {};
            order = [];
          }
          input.clearKeys.forEach(k => {
            delete stateMap[k];
            order = order.filter(o => o !== k);
          });
          input.increments.forEach(k => {
            const current = parseInt(stateMap[k], 10);
            stateMap[k] = String((Number.isNaN(current) ? 0 : current) + 1);
            ensureKey(k);
          });
          input.sets.forEach(pair => {
            stateMap[pair.key] = pair.value;
            ensureKey(pair.key);
          });

          const newMarkdown = composeStateNote(parsed.freeform, stateMap, order);

          if (input.dryRun) {
            return JSON.stringify({
              dryRun: true,
              id: target.id.primaryKey,
              isProject: input.isProject,
              order: order,
              state: stateMap,
              note: newMarkdown,
              meta: { privacyScope }
            }, null, 2);
          }

          setMarkdownNote(target, newMarkdown);

          return JSON.stringify({
            id: target.id.primaryKey,
            isProject: input.isProject,
            order: order,
            state: stateMap,
            note: newMarkdown,
            meta: { privacyScope }
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

private let projectSerializationSupport = #"""
function projectStatusName(status) {
  if (status === Project.Status.Active) { return "active"; }
  if (status === Project.Status.OnHold) { return "on-hold"; }
  if (status === Project.Status.Done) { return "completed"; }
  if (status === Project.Status.Dropped) { return "dropped"; }
  return String(status);
}

function reviewIntervalUnitName(unit) {
  // `reviewInterval.unit` is already a String ("days" | "weeks" | "months" | "years").
  // A previous version compared it against a nonexistent OmniJS unit enum; the
  // ReferenceError was swallowed by a catch and every project reported
  // `"unit": null`. Never re-introduce that silent fallback.
  if (unit == null) { return null; }
  if (typeof unit === "string" && unit.length > 0) { return unit; }
  // Do not coerce: String(someObject) yields "[object Object]", which is a quieter
  // version of the same bug. If the bridge ever stops handing back a string, say so.
  throw new Error(`Unexpected review interval unit type "${typeof unit}" from OmniFocus — expected a string.`);
}

function serializeProject(project, includeNotes) {
  const ri = project.reviewInterval;
  const result = {
    id: project.id.primaryKey,
    name: project.name,
    folder: projectFolderNamesForProject(project),
    status: projectStatusName(project.status),
    singleton: project.containsSingletonActions,
    sequential: project.sequential,
    completedByChildren: project.completedByChildren,
    reviewInterval: ri ? { steps: ri.steps, unit: reviewIntervalUnitName(ri.unit) } : null,
    nextReviewDate: iso(project.nextReviewDate),
    lastReviewDate: iso(project.lastReviewDate)
  };
  if (includeNotes) {
    // noteTextToMarkdown is provided by markdownNoteSupport; only referenced when
    // the caller opts in (and includes that support block).
    result.note = noteTextToMarkdown(project.noteText);
  }
  return result;
}
"""#

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

// Inverse of escapeMarkdownText: strip the escaping backslash from an escaped
// markdown-special character. markdownRuns must apply this to every text
// fragment it writes back so the read (escape) / write cycle is symmetric.
// Without it, each note round trip (e.g. every task-state --set) re-escaped
// already-escaped text and backslashes accumulated exponentially for any note
// containing _ * [ ] ` or \ (e.g. Salesforce field names like Some_Field__c).
function unescapeMarkdownText(value) {
  return value.replace(/\\([\\*_`\[\]])/g, "$1");
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
  // Opening delimiters are guarded with (?<!\\) so an *escaped* delimiter is not
  // treated as a token. On read, escapeMarkdownText backslash-escapes literal
  // * ** ` [ ] in note text; those escaped forms must fall through to
  // unescapeMarkdownText below (restoring the literal character) rather than be
  // re-parsed as bold/italic/code/link markup, which would strip the delimiters
  // and mangle the note. Genuine markup (unescaped delimiters) still matches.
  const tokenPattern = /(?<!\\)(\[([^\]\n]+)\]\((?:"([^"\n]+)"|'([^'\n]+)'|<([^>\n]+)>|([^)\n]+))\))|(?<!\\)(\*\*([^*\n]+)\*\*)|(?<!\\)(`([^`\n]+)`)|(?<![\\*])\*([^*\n]+)\*(?!\*)/g;
  let lastIndex = 0;
  let match;

  while ((match = tokenPattern.exec(markdown)) !== null) {
    if (match.index > lastIndex) {
      plain += unescapeMarkdownText(markdown.slice(lastIndex, match.index));
    }

    const start = plain.length;
    let text;
    let style = {};

    // Unescape inline (per fragment) rather than once at the end: the run
    // start/end offsets below index into plain, and setMarkdownNote applies
    // styles at those offsets, so plain must already be in its final
    // (unescaped) form as each run is recorded or the style ranges misalign.
    if (match[1]) {
      const url = markdownLinkDestination(match[3] || match[4] || match[5] || match[6] || "");
      text = unescapeMarkdownText(match[2]) + " (" + url + ")";
    } else if (match[7]) {
      text = unescapeMarkdownText(match[8]);
      style.bold = true;
    } else if (match[9]) {
      text = unescapeMarkdownText(match[10]);
      style.code = true;
    } else {
      text = unescapeMarkdownText(match[11]);
      style.italic = true;
    }

    plain += text;
    runs.push({ start, end: plain.length, style });
    lastIndex = tokenPattern.lastIndex;
  }

  plain += unescapeMarkdownText(markdown.slice(lastIndex));

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
      // Emit a bare URL when the visible text is itself a URL. OmniFocus
      // auto-links bare URLs but stores a normalized link target that differs
      // from the visible text (raw !== link.string), which would otherwise
      // re-wrap the URL as [url](url) on every read. On the next write,
      // markdownRuns() flattens [text](url) back to "text (url)", leaving a
      // duplicate copy that OmniFocus re-auto-links — so each state-block
      // round trip accumulated another copy. Bare-emitting URL-valued text
      // keeps the round trip idempotent.
      const rawIsUrl = /^\w[\w+.-]*:\/\//.test(raw.trim());
      text = (raw === link.string || rawIsUrl) ? escapeMarkdownText(raw) : markdownLinkRun(raw, link.string);
    }

    return text;
  }).join("");

  return normalizeOmniMarkdown(markdown);
}
"""#

// Helpers for the note state block: a delimited key/value section at the end
// of a task or project note. The marker is intentionally NOT a markdown heading
// ("### ...") because markdownRuns() strips heading markers on write while
// noteTextToMarkdown() never re-emits them on read — a heading marker would not
// survive the round trip. "=== ofctl-state ===" contains no characters that the
// markdown converters interpret, so it round-trips verbatim.
private let stateBlockSupport = #"""
const STATE_MARKER = "=== ofctl-state ===";

function parseStateBlock(markdown) {
  const text = (markdown || "").replace(/\r\n/g, "\n");
  const lines = text.split("\n");
  let markerIndex = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() === STATE_MARKER) { markerIndex = i; break; }
  }
  if (markerIndex === -1) {
    return { hasBlock: false, freeform: text, state: {}, order: [] };
  }
  const freeform = lines.slice(0, markerIndex).join("\n").replace(/\s+$/, "");
  const state = {};
  const order = [];
  for (let i = markerIndex + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim().length === 0) { continue; }
    const colon = line.indexOf(":");
    if (colon <= 0) { continue; }
    const key = line.slice(0, colon).trim();
    let value = line.slice(colon + 1);
    if (value.startsWith(" ")) { value = value.slice(1); }
    if (key.length === 0) { continue; }
    if (!Object.prototype.hasOwnProperty.call(state, key)) { order.push(key); }
    state[key] = value;
  }
  return { hasBlock: true, freeform: freeform, state: state, order: order };
}

function composeStateNote(freeform, state, order) {
  const trimmedFreeform = (freeform || "").replace(/\s+$/, "");
  const keys = order.filter(k => state[k] !== undefined && state[k] !== null);
  if (keys.length === 0) { return trimmedFreeform; }
  const blockLines = keys.map(k => k + ": " + state[k]);
  const block = STATE_MARKER + "\n" + blockLines.join("\n");
  if (trimmedFreeform.length === 0) { return block; }
  return trimmedFreeform + "\n\n" + block;
}
"""#

// Edits a project's freeform note (set / prepend / clear) while preserving the
// trailing "=== ofctl-state ===" block verbatim. Depends on parseStateBlock and
// composeStateNote from stateBlockSupport, and noteTextToMarkdown from
// markdownNoteSupport.
private let projectNoteSupport = #"""
function applyProjectNoteEdit(project, mode, text) {
  const parsed = parseStateBlock(noteTextToMarkdown(project.noteText));
  let newFreeform;
  if (mode === "clear") {
    newFreeform = "";
  } else if (mode === "prepend") {
    const existing = (parsed.freeform || "").replace(/^\s+/, "");
    newFreeform = existing.length ? (text + "\n\n" + existing) : text;
  } else {
    newFreeform = text;
  }
  if (parsed.hasBlock) {
    return composeStateNote(newFreeform, parsed.state, parsed.order);
  }
  return (newFreeform || "").replace(/\s+$/, "");
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

// Resolve a project by exact name first, then fall back to its primary-key id.
// Name match wins when both a name and a same-string id could match; passing an
// id targets a specific project unambiguously (e.g. a dropped twin that shares a
// name with an active project). Never does fuzzy/substring matching.
function resolveProjectByNameOrId(name) {
  if (name === null || name === undefined) { return null; }
  const byName = flattenedProjects.byName(name);
  if (byName) { return byName; }
  return flattenedProjects.find(project => project.id.primaryKey === name) || null;
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
  const effectivelyCompleted = taskEffectivelyCompleted(task);
  const effectivelyDropped = taskEffectivelyDropped(task);
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
    creationDate: iso(task.added),
    effectiveCompletionDate: iso(task.effectiveCompletedDate),
    effectiveDropDate: iso(task.effectiveDropDate),
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
    completed: effectivelyCompleted,
    dropped: effectivelyDropped,
    individuallyCompleted: task.completed,
    individuallyDropped: task.dropDate !== null,
    effectivelyCompleted,
    effectivelyDropped,
    path: pathForTask(task)
  };
}

function taskEffectivelyCompleted(task) {
  return task.effectiveCompletedDate !== null;
}

function taskEffectivelyDropped(task) {
  return task.effectiveDropDate !== null;
}
"""#
