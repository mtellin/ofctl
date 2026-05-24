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
            case .projectStatus(let update):
                print(try client.updateProjectStatus(update))
            case .projectMove(let move):
                print(try client.moveProject(move))
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
