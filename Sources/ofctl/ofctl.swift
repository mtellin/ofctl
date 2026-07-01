import Foundation
import OFCTLCore

@main
struct OFCTL {
    static func main() {
        do {
            let options = try CLI.parse(CommandLine.arguments)
            let client = OmniFocusClient(runner: OmniJavaScriptRunner())

            switch options.command {
            case .help:
                print(CLI.help)
            case .perspectives(let format):
                let output = try client.perspectives()
                printPerspectives(output, format: format)
            case .task(let lookup):
                let output = try client.task(lookup)
                printTaskLookup(output, format: lookup.format)
            case .tasks(let query):
                let output = try client.tasks(matching: query)
                printTasks(output, format: query.format)
            case .add(let task):
                print(try client.add(task))
            case .addGroup(let task):
                print(try client.add(task))
            case .update(let task):
                print(try client.update(task))
            case .taskRename(let rename):
                print(try client.renameTask(rename))
            case .taskMove(let move):
                print(try client.moveTasks(move))
            case .projectStatus(let update):
                print(try client.updateProjectStatus(update))
            case .projectMove(let move):
                print(try client.moveProject(move))
            case .projectRename(let rename):
                print(try client.renameProject(rename))
            case .projectNote(let update):
                print(try client.updateProjectNote(update))
            case .projectCompletion(let update):
                print(try client.updateProjectCompletion(update))
            case .projectCreate(let create):
                print(try client.createProject(create))
            case .folderCreate(let create):
                print(try client.createFolder(create))
            case .tags(let query):
                let output = try client.tags(query)
                printTags(output, format: query.format)
            case .tagCreate(let create):
                print(try client.createTag(create))
            case .tagRename(let rename):
                print(try client.renameTag(rename))
            case .tagDelete(let delete):
                print(try client.deleteTag(delete))
            case .tagMove(let move):
                print(try client.moveTag(move))
            case .taskDelete(let delete):
                print(try client.deleteTasks(delete))
            case .projectDelete(let delete):
                print(try client.deleteProject(delete))
            case .projects(let query):
                let output = try client.projects(query)
                printProjects(output, format: query.format)
            case .projectReview(let review):
                print(try client.reviewProject(review))
            case .taskState(let state):
                printState(try client.taskState(state), format: state.format)
            case .projectState(let state):
                printState(try client.projectState(state), format: state.format)
            }
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func printTasks(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tasks = object["tasks"] as? [[String: Any]]
        else {
            print(json)
            return
        }

        tasks.forEach { print(formatTaskLine($0)) }
    }

    private static func printTaskLookup(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let task = object["task"] as? [String: Any]
        else {
            print(json)
            return
        }

        print(formatTaskLine(task))
    }

    private static func formatTaskLine(_ task: [String: Any]) -> String {
        let name = task["name"] as? String ?? "(unnamed)"
        let tags = (task["tags"] as? [String] ?? []).joined(separator: ", ")
        let location: String
        if task["inInbox"] as? Bool == true {
            location = "Inbox"
        } else if let project = task["project"] as? String, !project.isEmpty {
            location = project
        } else {
            location = "No Project"
        }
        let planned = task["plannedDate"] as? String ?? "none"
        let deferDate = task["deferDate"] as? String ?? "none"
        let due = task["dueDate"] as? String ?? "none"
        let repeatRule = task["repeatRule"] as? String ?? "none"
        let completion = task["completionDate"] as? String
        let base = "- \(name) [project: \(location)] [tags: \(tags)] [defer: \(deferDate)] [planned: \(planned)] [due: \(due)] [repeat: \(repeatRule)]"
        guard let completion else { return base }
        return "\(base) [completed: \(completion)]"
    }

    private static func printProjects(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projectList = object["projects"] as? [[String: Any]]
        else {
            print(json)
            return
        }

        for project in projectList {
            let name = project["name"] as? String ?? "(unnamed)"
            let status = project["status"] as? String ?? "unknown"
            let folder = (project["folder"] as? [String] ?? []).joined(separator: "/")
            let nextReview = project["nextReviewDate"] as? String ?? "none"
            let location = folder.isEmpty ? "library" : folder
            print("- \(name) [status: \(status)] [folder: \(location)] [next review: \(nextReview)]")
            if let note = project["note"] as? String {
                let firstLine = note.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
                print("    note: \(firstLine.isEmpty ? "(empty)" : firstLine)")
            }
        }
    }

    private static func printTags(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagList = object["tags"] as? [[String: Any]]
        else {
            print(json)
            return
        }

        for tag in tagList {
            let path = tag["path"] as? String ?? (tag["name"] as? String ?? "(unnamed)")
            let childCount = tag["childCount"] as? Int ?? 0
            if childCount > 0 {
                print("- \(path) [children: \(childCount)]")
            } else {
                print("- \(path)")
            }
        }
    }

    private static func printState(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            print(json)
            return
        }

        if object["dryRun"] as? Bool == true {
            print("[dry-run] resulting state block:")
        }
        guard let state = object["state"] as? [String: Any], !state.isEmpty else {
            print("(no state block)")
            return
        }
        // Preserve write order when provided; otherwise sort for stable output.
        let order = object["order"] as? [String] ?? state.keys.sorted()
        for key in order {
            guard let value = state[key] else { continue }
            print("\(key): \(value)")
        }
    }

    private static func printPerspectives(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let perspectives = object["perspectives"] as? [[String: Any]]
        else {
            print(json)
            return
        }

        for perspective in perspectives {
            let name = perspective["name"] as? String ?? "(unnamed)"
            let type = perspective["type"] as? String ?? "unknown"
            if let identifier = perspective["identifier"] as? String, !identifier.isEmpty {
                print("- \(name) [\(type)] [id: \(identifier)]")
            } else {
                print("- \(name) [\(type)]")
            }
        }
    }
}
