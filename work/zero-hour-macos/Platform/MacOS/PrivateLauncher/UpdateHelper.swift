import Foundation
import Cocoa
import Darwin

@main enum UpdateHelper {
    static func main() {
        guard CommandLine.arguments.count == 2 else { exit(2) }
        let planURL = URL(fileURLWithPath: CommandLine.arguments[1])
        do {
            let plan = try JSONDecoder().decode(InstallPlan.self, from: Data(contentsOf: planURL))
            guard plan.parentPID > 1 else { throw UpdateFailure("Invalid parent process.") }
            let deadline = Date().addingTimeInterval(120)
            while kill(plan.parentPID, 0) == 0 {
                guard Date() < deadline else { throw UpdateFailure("The app did not exit in time.") }
                Thread.sleep(forTimeInterval: 0.2)
            }
            try UpdateInstaller.replace(source: plan.source, destination: plan.destination, validate: {
                try UpdateInstaller.validateBundle($0, version: plan.version)
                try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", $0.path])
            }, reopen: { try run("/usr/bin/open", [$0.path]) })
            try? FileManager.default.removeItem(at: planURL.deletingLastPathComponent())
        } catch {
            let alert = NSAlert(); alert.messageText = "Zero Hour: update not installed"
            alert.informativeText = error.localizedDescription + " The previous app has been retained. Please reopen it."
            alert.runModal(); exit(1)
        }
    }
    static func run(_ tool: String, _ args: [String]) throws {
        let process = Process(); process.executableURL = URL(fileURLWithPath: tool); process.arguments = args
        try process.run(); process.waitUntilExit()
        if process.terminationStatus != 0 { throw UpdateFailure("Could not verify or launch the update.") }
    }
}
