import Foundation

public struct OmniFocusClient {
    private let runner: AutomationRunning

    public init(runner: AutomationRunning) {
        self.runner = runner
    }

    public func tasks(matching query: TaskQuery) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.tasksQuery(query))
    }

    public func add(_ task: AddTask) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.addTask(task))
    }

    public func update(_ task: UpdateTask) throws -> String {
        try runner.runOmniJavaScript(OmniJavaScript.updateTask(task))
    }
}

enum OmniJavaScript {
    static func tasksQuery(_ query: TaskQuery) throws -> String {
        let tag = try jsonLiteral(query.tag)
        let available = try jsonLiteral(query.available)
        let planned = try jsonLiteral(query.planned)
        let deferred = try jsonLiteral(query.deferred)
        let due = try jsonLiteral(query.due)
        let limit = query.limit.map(String.init) ?? "null"
        return """
        (() => {
          \(markdownNoteSupport)

          const tagName = \(tag);
          const availableFilter = \(available);
          const plannedFilter = \(planned);
          const deferredFilter = \(deferred);
          const dueFilter = \(due);
          const limit = \(limit);
          const includeNotes = \(query.includeNotes ? "true" : "false");
          const includeCompleted = \(query.includeCompleted ? "true" : "false");
          const includeDropped = \(query.includeDropped ? "true" : "false");
          const projectIds = new Set(flattenedProjects.map(project => project.id.primaryKey));

          function iso(date) {
            return date ? date.toISOString() : null;
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

          const matchedTasks = flattenedTasks.filter(task => {
            if (projectIds.has(task.id.primaryKey)) { return false; }
            if (!task.inInbox && task.parent === null && task.containingProject !== null) { return false; }
            if (!includeCompleted && task.completed) { return false; }
            if (!includeDropped && task.dropDate) { return false; }
            if (tagName && !task.tags.some(tag => tag.name === tagName)) { return false; }
            if (!dateMatches(task.effectiveDeferDate || task.deferDate, availableFilter, true)) { return false; }
            if (!dateMatches(task.effectivePlannedDate || task.plannedDate, plannedFilter, false)) { return false; }
            if (!dateMatches(task.deferDate, deferredFilter, false)) { return false; }
            if (!dateMatches(task.effectiveDueDate || task.dueDate, dueFilter, false)) { return false; }
            return true;
          });

          const returnedTasks = limit === null ? matchedTasks : matchedTasks.slice(0, limit);
          const tasks = returnedTasks.map(task => ({
            id: task.id.primaryKey,
            name: task.name,
            note: includeNotes ? noteTextToMarkdown(task.noteText) : undefined,
            notePlain: includeNotes ? (task.note || "") : undefined,
            project: task.containingProject ? task.containingProject.name : null,
            inInbox: task.inInbox,
            tags: task.tags.map(tag => tag.name),
            deferDate: iso(task.deferDate),
            plannedDate: iso(task.plannedDate),
            dueDate: iso(task.dueDate),
            effectiveDeferDate: iso(task.effectiveDeferDate),
            effectivePlannedDate: iso(task.effectivePlannedDate),
            effectiveDueDate: iso(task.effectiveDueDate),
            estimatedMinutes: task.estimatedMinutes,
            flagged: task.flagged,
            completed: task.completed,
            dropped: task.dropDate !== null,
            path: pathForTask(task)
          }));

          return JSON.stringify({
            tasks,
            meta: {
              total: matchedTasks.length,
              count: tasks.length,
              limit,
              truncated: limit !== null && matchedTasks.length > limit
            }
          }, null, 2);
        })();
        """
    }

    static func addTask(_ task: AddTask) throws -> String {
        let name = try jsonLiteral(task.name)
        let project = try jsonLiteral(task.project)
        let tags = try jsonLiteral(task.tags)
        let deferDate = try jsonLiteral(task.deferDate)
        let plannedDate = try jsonLiteral(task.plannedDate)
        let dueDate = try jsonLiteral(task.dueDate)
        let note = try jsonLiteral(task.note)
        let estimatedMinutes = task.estimatedMinutes.map(String.init) ?? "null"

        return """
        (() => {
          \(markdownNoteSupport)

          const input = {
            name: \(name),
            project: \(project),
            tags: \(tags),
            deferDate: \(deferDate),
            plannedDate: \(plannedDate),
            dueDate: \(dueDate),
            estimatedMinutes: \(estimatedMinutes),
            note: \(note),
            dryRun: \(task.dryRun ? "true" : "false")
          };

          function parseDate(value) {
            if (!value) { return null; }
            const date = new Date(value);
            if (Number.isNaN(date.valueOf())) {
              throw new Error(`Invalid date: ${value}`);
            }
            return date;
          }

          function tagNamed(name) {
            return flattenedTags.byName(name) || new Tag(name);
          }

          function projectNamed(name) {
            if (!name) { return null; }
            const project = flattenedProjects.byName(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, task: input }, null, 2);
          }

          const project = projectNamed(input.project);
          const insertion = project ? project.ending : inbox.ending;
          const task = new Task(input.name, insertion);
          setMarkdownNote(task, input.note || "");
          task.deferDate = parseDate(input.deferDate);
          task.plannedDate = parseDate(input.plannedDate);
          task.dueDate = parseDate(input.dueDate);
          task.estimatedMinutes = input.estimatedMinutes;
          input.tags.forEach(name => task.addTag(tagNamed(name)));

          return JSON.stringify({
            task: {
              id: task.id.primaryKey,
              name: task.name,
              project: task.containingProject ? task.containingProject.name : null,
              tags: task.tags.map(tag => tag.name),
              deferDate: task.deferDate ? task.deferDate.toISOString() : null,
              plannedDate: task.plannedDate ? task.plannedDate.toISOString() : null,
              dueDate: task.dueDate ? task.dueDate.toISOString() : null,
              estimatedMinutes: task.estimatedMinutes
            }
          }, null, 2);
        })();
        """
    }

    static func updateTask(_ task: UpdateTask) throws -> String {
        let id = try jsonLiteral(task.id)
        let name = try jsonLiteral(task.name)
        let project = try jsonLiteral(task.project)
        let tags = try jsonLiteral(task.tags)
        let clearTags = task.clearTags ? "true" : "false"
        let deferDate = optionalJSONAssignment(task.deferDate)
        let plannedDate = optionalJSONAssignment(task.plannedDate)
        let dueDate = optionalJSONAssignment(task.dueDate)
        let estimatedMinutes = optionalIntAssignment(task.estimatedMinutes)
        let note = try jsonLiteral(task.note)

        return """
        (() => {
          \(markdownNoteSupport)

          const input = {
            id: \(id),
            name: \(name),
            project: \(project),
            tags: \(tags),
            clearTags: \(clearTags),
            deferDate: \(deferDate),
            plannedDate: \(plannedDate),
            dueDate: \(dueDate),
            estimatedMinutes: \(estimatedMinutes),
            note: \(note),
            dryRun: \(task.dryRun ? "true" : "false")
          };

          function parseDate(value) {
            if (value === null) { return null; }
            const date = new Date(value);
            if (Number.isNaN(date.valueOf())) {
              throw new Error(`Invalid date: ${value}`);
            }
            return date;
          }

          function tagNamed(name) {
            return flattenedTags.byName(name) || new Tag(name);
          }

          function projectNamed(name) {
            if (!name) { return null; }
            const project = flattenedProjects.byName(name);
            if (!project) {
              throw new Error(`Project not found: ${name}`);
            }
            return project;
          }

          const task = Task.byIdentifier(input.id);
          if (!task) {
            throw new Error(`Task not found: ${input.id}`);
          }

          if (input.dryRun) {
            return JSON.stringify({ dryRun: true, task: input }, null, 2);
          }

          if (input.name !== null) { task.name = input.name; }
          if (input.note !== null) { setMarkdownNote(task, input.note); }
          if (input.project !== null) { moveTasks([task], projectNamed(input.project).ending); }
          if (input.deferDate !== undefined) { task.deferDate = parseDate(input.deferDate); }
          if (input.plannedDate !== undefined) { task.plannedDate = parseDate(input.plannedDate); }
          if (input.dueDate !== undefined) { task.dueDate = parseDate(input.dueDate); }
          if (input.estimatedMinutes !== undefined) { task.estimatedMinutes = input.estimatedMinutes; }
          if (input.clearTags) { task.tags.forEach(tag => task.removeTag(tag)); }
          input.tags.forEach(name => task.addTag(tagNamed(name)));

          return JSON.stringify({
            task: {
              id: task.id.primaryKey,
              name: task.name,
              project: task.containingProject ? task.containingProject.name : null,
              tags: task.tags.map(tag => tag.name),
              deferDate: task.deferDate ? task.deferDate.toISOString() : null,
              plannedDate: task.plannedDate ? task.plannedDate.toISOString() : null,
              dueDate: task.dueDate ? task.dueDate.toISOString() : null,
              estimatedMinutes: task.estimatedMinutes
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
}

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
  const tokenPattern = /(\[([^\]\n]+)\]\(([^)\n]+)\))|(\*\*([^*\n]+)\*\*)|(`([^`\n]+)`)|(?<!\*)\*([^*\n]+)\*(?!\*)/g;
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
      text = match[2];
      style.link = match[3];
    } else if (match[4]) {
      text = match[5];
      style.bold = true;
    } else if (match[6]) {
      text = match[7];
      style.code = true;
    } else {
      text = match[8];
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
    if (run.style.link) {
      const url = URL.fromString(run.style.link);
      if (url) {
        style.set(Style.Attribute.Link, url);
      }
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
      text = markdownLinkRun(raw, link.string);
    }

    return text;
  }).join("");

  return normalizeOmniMarkdown(markdown);
}
"""#
