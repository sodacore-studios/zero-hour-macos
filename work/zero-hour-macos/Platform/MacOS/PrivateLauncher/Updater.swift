import Cocoa
import Security

final class GitHubTransport: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let url = request.url, GitHubPolicy.allowedRedirect(url) else { completionHandler(nil); return }
        var safe = request
        // Never forward the private repository credential to the asset CDN.
        if url.host != "api.github.com" { safe.setValue(nil, forHTTPHeaderField: "Authorization") }
        completionHandler(safe)
    }
    func data(_ url: URL, token: String?, binary: Bool = false, maximum: Int) async throws -> Data {
        guard url == GitHubPolicy.latest || GitHubPolicy.isAssetAPI(url) else { throw UpdateFailure("Invalid update address.") }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 45; config.timeoutIntervalForResource = 600
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url)
        request.setValue(binary ? "application/octet-stream" : "application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("ZeroHour-macOS-Updater", forHTTPHeaderField: "User-Agent")
        if let token = token, !token.isEmpty { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        let (file, response) = try await session.download(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw UpdateFailure("GitHub updates are unavailable. Check your Internet connection. Private repositories also require a read-only token under Updates.")
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard (attributes[.size] as? NSNumber)?.intValue ?? Int.max <= maximum else { throw UpdateFailure("The update file is too large.") }
        return try Data(contentsOf: file, options: .mappedIfSafe)
    }
}

enum UpdateCredential {
    static let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "net.sodacore.zerohour.github-updates", kSecAttrAccount as String: GitHubPolicy.repository]
    static func read() throws -> String? {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let result = SecItemCopyMatching(q as CFDictionary, &value)
        if result == errSecItemNotFound { return nil }
        guard result == errSecSuccess, let data = value as? Data else { throw UpdateFailure("Could not read GitHub credentials from the Keychain.") }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ token: String) throws {
        if token.isEmpty {
            let result = SecItemDelete(query as CFDictionary)
            guard result == errSecSuccess || result == errSecItemNotFound else { throw UpdateFailure("Could not remove the Keychain entry.") }
            return
        }
        let value = [kSecValueData as String: Data(token.utf8)]
        var result = SecItemUpdate(query as CFDictionary, value as CFDictionary)
        if result == errSecItemNotFound {
            var q = query.merging(value) { _, new in new }
            q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            result = SecItemAdd(q as CFDictionary, nil)
        }
        guard result == errSecSuccess else { throw UpdateFailure("Could not save GitHub credentials in the Keychain.") }
    }
}

@MainActor final class AppUpdater {
    var busy = false
    var pending: (URL, String)?
    var idle: () -> Bool = { true }
    var status: (String) -> Void = { _ in }
    var prepare: () throws -> Void = {}
    var lock: () -> Void = {}
    var automatic: Bool {
        get { UserDefaults.standard.object(forKey: "AutomaticGitHubUpdates") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "AutomaticGitHubUpdates") }
    }
    func check(manual: Bool = false) {
        guard !busy, pending == nil, manual || automatic else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let transport = GitHubTransport(), token = try UpdateCredential.read()
                let data = try await transport.data(GitHubPolicy.latest, token: token, maximum: 1024 * 1024)
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                guard !release.draft, !release.prerelease else { return }
                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
                let version = String(release.tag_name.dropFirst())
                guard release.tag_name.hasPrefix("v"), try ReleaseVersion(version) > ReleaseVersion(current) else {
                    if manual { status("You are running the latest version \(current).") }; return
                }
                guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "ZeroHourUpdatePublicKey") as? String else { throw UpdateFailure("The update verification key is missing.") }
                status("Update \(version) is being verified and downloaded …")
                let manifestAsset = try release.asset("update.json"), signatureAsset = try release.asset("update.sig")
                let manifestData = try await transport.data(manifestAsset.url, token: token, binary: true, maximum: 64 * 1024)
                let signature = try await transport.data(signatureAsset.url, token: token, binary: true, maximum: 64)
                let manifest = try UpdateManifest.authenticated(manifestData, signature: signature, publicKey: publicKey)
                try manifest.validate(current: current, tag: release.tag_name, system: ProcessInfo.processInfo.operatingSystemVersion)
                let archive = try release.asset(manifest.archive)
                guard archive.size == manifest.size else { throw UpdateFailure("The archive size does not match the signed manifest.") }
                let bytes = try await transport.data(archive.url, token: token, binary: true, maximum: manifest.size)
                try manifest.verifyArchive(bytes)
                let fm = FileManager.default
                let cache = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("net.sodacore.zerohour/Updates/\(UUID().uuidString)")
                try fm.createDirectory(at: cache, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
                let zip = cache.appendingPathComponent("update.zip"), expanded = cache.appendingPathComponent("expanded")
                try bytes.write(to: zip)
                try await Task.detached {
                    try runUpdateTool("/usr/bin/ditto", ["-x", "-k", zip.path, expanded.path])
                    let app = expanded.appendingPathComponent("Zero Hour.app")
                    try UpdateInstaller.validateBundle(app, version: version)
                    try runUpdateTool("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
                }.value
                try fm.removeItem(at: zip)
                pending = (expanded.appendingPathComponent("Zero Hour.app"), version)
                installIfIdle()
            } catch { status("Update: " + error.localizedDescription) }
        }
    }
    func installIfIdle() {
        guard let (source, version) = pending else { return }
        guard idle() else { status("Update \(version) will be installed after the game exits."); return }
        do {
            let destination = Bundle.main.bundleURL
            guard !destination.path.hasPrefix("/Volumes/"), !destination.path.contains("/AppTranslocation/"),
                  FileManager.default.isWritableFile(atPath: destination.deletingLastPathComponent().path) else {
                throw UpdateFailure("Copy the app to Applications before installing updates.")
            }
            try prepare()
            let cache = source.deletingLastPathComponent().deletingLastPathComponent()
            let helper = cache.appendingPathComponent("ZeroHourUpdateHelper")
            try FileManager.default.copyItem(at: Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/ZeroHourUpdateHelper"), to: helper)
            let plan = InstallPlan(source: source, destination: destination, parentPID: ProcessInfo.processInfo.processIdentifier, version: version)
            let planURL = cache.appendingPathComponent("install.json")
            try JSONEncoder().encode(plan).write(to: planURL, options: .atomic)
            let process = Process(); process.executableURL = helper; process.arguments = [planURL.path]
            try process.run()
            lock(); status("Update \(version) is being installed. The app will restart shortly.")
            NSApp.terminate(nil)
        } catch { status("Update: " + error.localizedDescription); pending = nil }
    }
    func settings() {
        let alert = NSAlert(); alert.messageText = "GitHub updates"
        alert.informativeText = "Public releases update without a token. For private access only: use a fine-grained GitHub token for this repository with Contents: Read-only. It stays in the macOS Keychain. Updates never prevent offline play."
        let token = NSSecureTextField(frame: NSRect(x: 0, y: 36, width: 420, height: 24))
        token.placeholderString = "Optional GitHub token (blank: keep existing credentials)"
        let automaticBox = NSButton(checkboxWithTitle: "Download updates automatically and install when no game is running", target: nil, action: nil)
        automaticBox.frame = NSRect(x: 0, y: 0, width: 450, height: 28); automaticBox.state = automatic ? .on : .off
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 65)); view.addSubview(token); view.addSubview(automaticBox); alert.accessoryView = view
        alert.addButton(withTitle: "Save and check"); alert.addButton(withTitle: "Cancel"); alert.addButton(withTitle: "Remove credentials")
        let result = alert.runModal()
        do {
            if result == .alertFirstButtonReturn {
                automatic = automaticBox.state == .on
                if !token.stringValue.isEmpty { try UpdateCredential.save(token.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) }
                check(manual: true)
            } else if result == .alertThirdButtonReturn { try UpdateCredential.save(""); status("GitHub credentials removed.") }
        } catch { status(error.localizedDescription) }
    }
}

func runUpdateTool(_ executable: String, _ arguments: [String]) throws {
    let process = Process(); process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice; process.standardError = FileHandle.nullDevice
    try process.run(); process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw UpdateFailure("Update validation failed (\(URL(fileURLWithPath: executable).lastPathComponent)).") }
}
