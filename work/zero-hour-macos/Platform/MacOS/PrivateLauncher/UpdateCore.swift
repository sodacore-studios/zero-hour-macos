import Foundation
import CryptoKit

struct UpdateFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

struct ReleaseVersion: Comparable, Equatable {
    let parts: [Int]
    init(_ text: String) throws {
        let fields = text.split(separator: ".", omittingEmptySubsequences: false)
        guard fields.count == 3, fields.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
              fields.allSatisfy({ Int($0) != nil }) else { throw UpdateFailure("Invalid version number.") }
        parts = fields.map { Int($0)! }
    }
    static func < (a: Self, b: Self) -> Bool { a.parts.lexicographicallyPrecedes(b.parts) }
}

struct UpdateManifest: Codable {
    let version: String
    let architecture: String
    let minimumSystemVersion: String
    let bundleIdentifier: String
    let archive: String
    let sha256: String
    let size: Int

    func validate(current: String, tag: String, system: OperatingSystemVersion) throws {
        guard try ReleaseVersion(version) > ReleaseVersion(current), tag == "v" + version,
              architecture == "arm64", bundleIdentifier == "net.sodacore.zerohour",
              archive == "Zero-Hour-\(version)-macOS-arm64.zip", size > 0, size <= 512 * 1024 * 1024,
              sha256.count == 64, sha256.allSatisfy({ "0123456789abcdef".contains($0) }) else {
            throw UpdateFailure("The update does not match this app or is not newer.")
        }
        let minimum = try ReleaseVersion(minimumSystemVersion)
        let actual = try ReleaseVersion("\(system.majorVersion).\(system.minorVersion).\(system.patchVersion)")
        guard actual >= minimum else { throw UpdateFailure("The update requires macOS \(minimumSystemVersion) or newer.") }
    }

    func verifyArchive(_ data: Data) throws {
        guard data.count == size, Self.digest(data) == sha256 else { throw UpdateFailure("The update archive is incomplete or damaged.") }
    }
    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    static func authenticated(_ data: Data, signature: Data, publicKey: String) throws -> Self {
        guard data.count < 64 * 1024, let raw = Data(base64Encoded: publicKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw),
              key.isValidSignature(signature, for: data) else { throw UpdateFailure("The update signature is invalid.") }
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

struct GitHubRelease: Decodable {
    struct Asset: Decodable { let name: String; let url: URL; let size: Int }
    let tag_name: String
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]
    func asset(_ name: String) throws -> Asset {
        let matches = assets.filter { $0.name == name }
        guard matches.count == 1, let asset = matches.first,
              GitHubPolicy.isAssetAPI(asset.url) else { throw UpdateFailure("The release does not contain a unique update package.") }
        return asset
    }
}

enum GitHubPolicy {
    static let repository = "sodacore-studios/zero-hour-macos"
    static let latest = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    static func isAssetAPI(_ url: URL) -> Bool {
        guard url.scheme == "https", url.host == "api.github.com", url.port == nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return false }
        let prefix = "/repos/\(repository)/releases/assets/"
        let suffix = String(url.path.dropFirst(prefix.count))
        return url.path.hasPrefix(prefix) && !suffix.isEmpty && suffix.allSatisfy { $0.isASCII && $0.isNumber }
    }
    static func allowedRedirect(_ url: URL) -> Bool {
        url.scheme == "https" && url.user == nil && url.password == nil && url.port == nil &&
        ["api.github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com"].contains(url.host ?? "")
    }
}

struct InstallPlan: Codable {
    let source: URL
    let destination: URL
    let parentPID: Int32
    let version: String
}

enum UpdateInstaller {
    static func validateBundle(_ url: URL, version: String) throws {
        let plist = url.appendingPathComponent("Contents/Info.plist")
        let info = try PropertyListSerialization.propertyList(from: Data(contentsOf: plist), format: nil) as? [String: Any]
        guard info?["CFBundleIdentifier"] as? String == "net.sodacore.zerohour",
              info?["CFBundleShortVersionString"] as? String == version,
              info?["CFBundleExecutable"] as? String == "ZeroHourLauncher" else { throw UpdateFailure("Unexpected application in the update.") }
    }

    // Stage on the same filesystem, then rename. Keep a recoverable previous app.
    static func replace(source: URL, destination: URL, validate: (URL) throws -> Void,
                        reopen: (URL) throws -> Void) throws {
        let fm = FileManager.default
        guard destination.pathExtension == "app", !destination.path.hasPrefix("/Volumes/"),
              fm.isWritableFile(atPath: destination.deletingLastPathComponent().path),
              (try destination.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true else {
            throw UpdateFailure("Copy the app to a writable Applications folder first.")
        }
        let staged = destination.deletingLastPathComponent().appendingPathComponent(".ZeroHour-update-\(UUID().uuidString).app")
        let backup = destination.appendingPathExtension("previous")
        defer { try? fm.removeItem(at: staged) }
        try fm.copyItem(at: source, to: staged)
        try validate(staged)
        if fm.fileExists(atPath: backup.path) { try fm.removeItem(at: backup) }
        try fm.moveItem(at: destination, to: backup)
        do {
            try fm.moveItem(at: staged, to: destination)
            try reopen(destination)
        } catch {
            if fm.fileExists(atPath: destination.path) { try? fm.removeItem(at: destination) }
            try fm.moveItem(at: backup, to: destination)
            throw error
        }
    }
}
