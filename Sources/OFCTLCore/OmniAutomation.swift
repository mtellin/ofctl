import Foundation
import AppKit

public protocol AutomationRunning {
    func runOmniJavaScript(_ javascript: String) throws -> String
}

private struct AppleEventSendFailure: Error {
    let message: String
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
        if let app = runningApplication() {
            return NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
        }

        guard launchOmniFocus() else {
            throw CLIError.automation("""
            \((originalError as? AppleEventSendFailure)?.message ?? originalError.localizedDescription)
            Also failed to launch OmniFocus with bundle id \(bundleIdentifier), app name \(applicationName), or path \(applicationPath)
            """)
        }

        for _ in 0..<50 {
            if let app = runningApplication() {
                return NSAppleEventDescriptor(processIdentifier: app.processIdentifier)
            }
            usleep(100_000)
        }

        throw CLIError.automation("OmniFocus did not become available after launch")
    }

    private func launchOmniFocus() -> Bool {
        if launchOpen(arguments: ["-b", bundleIdentifier]) {
            return true
        }
        if launchOpen(arguments: ["-a", applicationName]) {
            return true
        }

        for path in candidateApplicationPaths() {
            if launchOpen(arguments: [path]) {
                return true
            }
        }

        return false
    }

    private func launchOpen(arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = arguments
        return launch(process)
    }

    private func candidateApplicationPaths() -> [String] {
        var paths: [String] = []

        func append(_ path: String?) {
            guard let path, !path.isEmpty, !paths.contains(path) else { return }
            paths.append(path)
        }

        append(applicationPath)
        append(NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)?.path)
        mdfindApplicationPaths().forEach { append($0) }

        return paths
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
