import Foundation
import AppKit

public protocol AutomationRunning {
    func runOmniJavaScript(_ javascript: String) throws -> String
}

private struct AppleEventSendFailure: Error {
    let message: String
}

struct OmniFocusLaunchAttempt: Equatable {
    var label: String
    var arguments: [String]
}

struct OmniFocusLaunchConfiguration: Equatable {
    var bundleIdentifier: String
    var applicationPath: String
    var applicationName: String
}

func omniFocusLaunchAttempts(
    configuration: OmniFocusLaunchConfiguration,
    workspaceApplicationPath: String?,
    spotlightApplicationPaths: [String],
    fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
) -> [OmniFocusLaunchAttempt] {
    var attempts: [OmniFocusLaunchAttempt] = []
    var paths: [String] = []

    func appendPath(_ path: String?) {
        guard let path, !path.isEmpty, !paths.contains(path) else { return }
        paths.append(path)
    }

    appendPath(configuration.applicationPath)
    appendPath(workspaceApplicationPath)
    spotlightApplicationPaths.forEach { appendPath($0) }

    for path in paths where fileExists(path) {
        attempts.append(OmniFocusLaunchAttempt(label: "path \(path)", arguments: [path]))
    }

    attempts.append(OmniFocusLaunchAttempt(
        label: "bundle id \(configuration.bundleIdentifier)",
        arguments: ["-b", configuration.bundleIdentifier]
    ))
    attempts.append(OmniFocusLaunchAttempt(
        label: "application name \(configuration.applicationName)",
        arguments: ["-a", configuration.applicationName]
    ))

    return attempts
}

public struct OmniJavaScriptRunner: AutomationRunning {
    private let bundleIdentifier: String
    private let applicationPath: String
    private let applicationName: String
    private let timeout: TimeInterval

    public init(
        bundleIdentifier: String? = nil,
        applicationPath: String? = nil,
        applicationName: String? = nil,
        timeout: TimeInterval = 60,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.bundleIdentifier = bundleIdentifier ?? environment["OFCTL_OMNIFOCUS_BUNDLE_ID"] ?? "com.omnigroup.OmniFocus4"
        self.applicationPath = applicationPath ?? environment["OFCTL_OMNIFOCUS_APP_PATH"] ?? "/Applications/OmniFocus.app"
        self.applicationName = applicationName ?? environment["OFCTL_OMNIFOCUS_APP_NAME"] ?? "OmniFocus"
        self.timeout = timeout
    }

    public func runOmniJavaScript(_ javascript: String) throws -> String {
        let target = targetDescriptor()
        do {
            return try runOmniJavaScript(javascript, target: target)
        } catch let error as AppleEventSendFailure {
            let launchedTarget = try launchTargetDescriptor(after: error)
            do {
                return try runOmniJavaScript(javascript, target: launchedTarget)
            } catch let retryError as AppleEventSendFailure {
                throw CLIError.automation(retryError.message)
            }
        } catch {
            throw error
        }
    }

    private func runOmniJavaScript(_ javascript: String, target: NSAppleEventDescriptor) throws -> String {
        let event = NSAppleEventDescriptor(
            eventClass: fourCharCode("OFOC"),
            eventID: fourCharCode("OFEJ"),
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setParam(
            NSAppleEventDescriptor(string: javascript),
            forKeyword: AEKeyword(keyDirectObject)
        )

        let reply: NSAppleEventDescriptor
        do {
            reply = try event.sendEvent(options: [.waitForReply], timeout: timeout)
        } catch {
            throw AppleEventSendFailure(message: "Failed to send OmniJS Apple Event to OmniFocus: \(error.localizedDescription)")
        }

        if let errorNumber = reply.paramDescriptor(forKeyword: AEKeyword(keyErrorNumber))?.int32Value,
           errorNumber != 0 {
            let errorMessage = reply.paramDescriptor(forKeyword: AEKeyword(keyErrorString))?.stringValue
            let message = errorMessage?.isEmpty == false ? errorMessage! : "OmniFocus returned Apple Event error \(errorNumber)"
            throw CLIError.automation(message)
        }

        guard let result = reply.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            return ""
        }
        return result.stringValue ?? result.description
    }

    private func targetDescriptor() -> NSAppleEventDescriptor {
        if let app = runningApplication() {
            return NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
        }

        return NSAppleEventDescriptor(bundleIdentifier: bundleIdentifier)
    }

    private func launchTargetDescriptor(after originalError: Error) throws -> NSAppleEventDescriptor {
        if let app = waitForRunningApplication(maxAttempts: 5) {
            return NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
        }

        let failedAttempts = launchOmniFocus()
        guard failedAttempts.isEmpty else {
            let pathStatus = FileManager.default.fileExists(atPath: applicationPath)
                ? "exists"
                : "does not exist"
            throw CLIError.automation("""
            \((originalError as? AppleEventSendFailure)?.message ?? originalError.localizedDescription)
            Also failed to launch OmniFocus. Tried \(failedAttempts.joined(separator: ", ")).
            Configured app path \(applicationPath) \(pathStatus).
            """)
        }

        if let app = waitForRunningApplication(maxAttempts: 50) {
            return NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
        }

        throw CLIError.automation("OmniFocus did not become available after launch")
    }

    private func launchOmniFocus() -> [String] {
        var failedAttempts: [String] = []
        for attempt in launchAttempts() {
            if launchOpen(arguments: attempt.arguments) {
                return []
            }
            failedAttempts.append(attempt.label)
        }

        return failedAttempts
    }

    private func launchOpen(arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = arguments
        return launch(process)
    }

    private func launchAttempts() -> [OmniFocusLaunchAttempt] {
        omniFocusLaunchAttempts(
            configuration: OmniFocusLaunchConfiguration(
                bundleIdentifier: bundleIdentifier,
                applicationPath: applicationPath,
                applicationName: applicationName
            ),
            workspaceApplicationPath: NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)?.path,
            spotlightApplicationPaths: mdfindApplicationPaths()
        )
    }

    private func mdfindApplicationPaths() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemCFBundleIdentifier == '\(bundleIdentifier)'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        guard process.terminationStatus == 0 else { return [] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
            .map(String.init)
            .filter { $0.hasSuffix(".app") }
    }

    private func launch(_ process: Process) -> Bool {
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func waitForRunningApplication(maxAttempts: Int) -> NSRunningApplication? {
        for attempt in 0..<maxAttempts {
            if let app = runningApplication() {
                return app
            }
            if attempt < maxAttempts - 1 {
                usleep(100_000)
            }
        }
        return nil
    }

    private func runningApplication() -> NSRunningApplication? {
        if let app = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first {
            return app
        }

        let normalizedApplicationName = applicationName.lowercased()
        return NSWorkspace.shared.runningApplications.first { app in
            if app.bundleIdentifier?.caseInsensitiveCompare(bundleIdentifier) == .orderedSame {
                return true
            }
            if app.localizedName?.lowercased() == normalizedApplicationName {
                return true
            }
            if app.bundleURL?.deletingPathExtension().lastPathComponent.lowercased() == normalizedApplicationName {
                return true
            }
            if app.executableURL?.lastPathComponent.lowercased() == normalizedApplicationName.lowercased() {
                return true
            }
            return false
        }
    }
}

public func fourCharCode(_ value: String) -> UInt32 {
    precondition(value.utf8.count == 4, "Four-character codes must be exactly four bytes")
    return value.utf8.reduce(UInt32(0)) { ($0 << 8) + UInt32($1) }
}
