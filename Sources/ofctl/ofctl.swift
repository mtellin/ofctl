import Foundation
import OFCTLCore

@main
struct OFCTL {
    static func main() {
        do {
            let options = try CLI.parse(CommandLine.arguments)
            let client = OmniFocusClient(runner: OsaScriptRunner())

            switch options.command {
            case .help:
                print(CLI.help)
            case .tasks(let query):
                let output = try client.tasks(matching: query)
                printOutput(output, format: query.format)
            case .add(let task):
                print(try client.add(task))
            case .update(let task):
                print(try client.update(task))
            }
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func printOutput(_ json: String, format: OutputFormat) {
        guard format == .text,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tasks = object["tasks"] as? [[String: Any]]
        else {
            print(json)
            return
        }

        for task in tasks {
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
            print("- \(name) [project: \(location)] [tags: \(tags)] [defer: \(deferDate)] [planned: \(planned)] [due: \(due)]")
        }
    }
}
