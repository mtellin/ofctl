import Foundation

public protocol AutomationRunning {
    func runOmniJavaScript(_ javascript: String) throws -> String
}

public struct OsaScriptRunner: AutomationRunning {
    public init() {}

    public func runOmniJavaScript(_ javascript: String) throws -> String {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofctl-\(UUID().uuidString).js")
        try javascript.write(to: scriptURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let appleScript = """
        tell application "OmniFocus"
            tell default document
                evaluate javascript (read POSIX file \(appleScriptStringLiteral(scriptURL.path)) as «class utf8»)
            end tell
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw CLIError.automation("Failed to run osascript: \(error.localizedDescription)")
        }

        let stdout = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw CLIError.automation(stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public func appleScriptStringLiteral(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
    return "\"\(escaped)\""
}
