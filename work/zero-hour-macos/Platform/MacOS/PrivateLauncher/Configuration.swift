import Foundation

struct LaunchSettings: Codable {
    var gameFolder = ""
    var server = ""
    var playerName = "Player"
    var invitation = ""
    var relay = ""
    var wasd = true
    var fullscreen = true
    // Optional for backward-compatible decoding of existing settings files.
    var rightClickOrders: Bool? = nil
    var usesRightClickOrders: Bool { rightClickOrders ?? true }
    var resolution = "1920 x 1080"

    static let resolutions = ["1280 x 720", "1280 x 800", "1600 x 900", "1920 x 1080", "1920 x 1200", "2560 x 1440", "2560 x 1600", "3840 x 2160", "2560 x 1080", "3440 x 1440", "3840 x 1600", "2560 x 720", "3200 x 900", "3840 x 1080", "5120 x 1440", "5120 x 2160", "6016 x 3384", "7680 x 2160"]

    func gameOptions() -> [String: String] {
        var values = ["Resolution": resolution.replacingOccurrences(of: " x ", with: " "),
                      "WASDMapScroll": wasd ? "yes" : "no", "Windowed": "yes",
                      "UseAlternateMouse": usesRightClickOrders ? "yes" : "no"]
        if usesRightClickOrders { values["UseRightMouseScrollWithAlternateMouse"] = "no" }
        return values
    }

    func endpoint() throws -> String {
        let value = server.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return "http://127.0.0.1:9/env/prod/contract/1" }
        guard let u = URLComponents(string: value), let host = u.host, !host.isEmpty,
              (u.scheme == "https" || (u.scheme == "http" && host == "127.0.0.1" && u.port != nil)),
              u.user == nil, u.password == nil, u.query == nil, u.fragment == nil,
              !value.contains("\\"), !value.contains(where: { $0.isWhitespace }) else {
            throw SetupError.message("Enter an HTTPS server address without credentials, query parameters or a fragment.")
        }
        let base = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return base.hasSuffix("/env/prod/contract/1") ? base : base + "/env/prod/contract/1"
    }

    func relayAddress() throws -> String {
        let value = relay.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            guard !server.isEmpty, let host = URLComponents(string: server)?.host else { return "" }
            return host.contains(":") ? "[\(host)]:3478" : "\(host):3478"
        }
        guard let u = URLComponents(string: "turn://" + value), let host = u.host, !host.isEmpty,
              let port = u.port, (1...65535).contains(port), u.path.isEmpty,
              u.user == nil, u.password == nil, u.query == nil, u.fragment == nil,
              !value.contains(where: { $0.isWhitespace }) else {
            throw SetupError.message("Enter the relay as hostname:port, for example relay.example.org:3478.")
        }
        return value
    }

    func validate() throws {
        _ = try endpoint(); _ = try relayAddress()
        guard playerName.range(of: #"^[\p{L}\p{N} _.-]{2,24}$"#, options: .regularExpression) != nil else {
            throw SetupError.message("Player names must contain 2–24 letters, numbers, spaces, periods, hyphens or underscores.")
        }
        guard Self.resolutions.contains(resolution) else { throw SetupError.message("Please select a resolution.") }
    }

    static func bundledGameRoot(in resources: URL?) -> URL? {
        guard let candidate = resources?.appendingPathComponent("Spieldaten", isDirectory: true) else { return nil }
        var probe = LaunchSettings(); probe.gameFolder = candidate.path
        return try? probe.gameRoot()
    }

    func gameRoot(bundledRoot: URL? = nil) throws -> URL {
        if let bundledRoot = bundledRoot {
            var probe = self; probe.gameFolder = bundledRoot.path
            return try probe.gameRoot()
        }
        let selected = URL(fileURLWithPath: gameFolder, isDirectory: true)
        guard !gameFolder.isEmpty else { throw SetupError.message("Please select the folder containing your installed game files first.") }
        let fm = FileManager.default
        func names(_ folder: URL) -> Set<String> {
            Set(((try? fm.contentsOfDirectory(atPath: folder.path)) ?? []).map { $0.lowercased() })
        }
        // Accept either the common installation root or the Zero Hour folder itself.
        let root = names(selected).contains("inizh.big") ? selected.deletingLastPathComponent() : selected
        let children = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        guard children.contains(where: { names($0).contains("inizh.big") }) else {
            throw SetupError.message("No Zero Hour installation found. Select the folder containing INIZH.big or the common parent of the Generals and Zero Hour folders.")
        }
        return root
    }
}

enum SetupError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(s) = self { return s }; return nil }
}

func updateOptions(_ text: String, values: [String: String]) -> String {
    var remaining = values
    var lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
    lines = lines.compactMap { line in
        let key = line.split(separator: "=", maxSplits: 1).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
        guard values[key] != nil else { return line }
        guard let value = remaining.removeValue(forKey: key) else { return nil }
        return "\(key) = \(value)"
    }
    lines += remaining.keys.sorted().map { "\($0) = \(remaining[$0]!)" }
    return lines.joined(separator: "\n") + "\n"
}
