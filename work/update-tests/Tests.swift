import Foundation
import CryptoKit

@main enum UpdateTests {
    static func expect(_ value: Bool) { precondition(value) }
    static func rejected(_ operation: () throws -> Void) {
        do { try operation(); fatalError("Expected rejection") } catch { }
    }
    static func main() throws {
        expect(try ReleaseVersion("0.10.0") > ReleaseVersion("0.9.99"))
        expect(try ReleaseVersion("1.0.0") == ReleaseVersion("1.0.0"))
        for invalid in ["", "v1.0.0", "1.2", "1.2.3-beta", "-1.2.3", "1.2.３", "999999999999999999999.0.0"] {
            rejected { _ = try ReleaseVersion(invalid) }
        }
        let system = OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0)
        let bytes = Data("verified update fixture".utf8)
        let manifest = UpdateManifest(version: "0.3.0", architecture: "arm64", minimumSystemVersion: "13.3.0",
            bundleIdentifier: "net.sodacore.zerohour", archive: "Zero-Hour-0.3.0-macOS-arm64.zip",
            sha256: UpdateManifest.digest(bytes), size: bytes.count)
        let key = Curve25519.Signing.PrivateKey()
        let data = try JSONEncoder().encode(manifest)
        let signature = try key.signature(for: data)
        let publicKey = key.publicKey.rawRepresentation.base64EncodedString()
        let decoded = try UpdateManifest.authenticated(data, signature: signature, publicKey: publicKey)
        try decoded.validate(current: "0.2.2", tag: "v0.3.0", system: system)
        try decoded.verifyArchive(bytes)
        rejected { try decoded.verifyArchive(Data("tampered".utf8)) }
        rejected { _ = try UpdateManifest.authenticated(data + Data([0]), signature: signature, publicKey: publicKey) }
        rejected { _ = try UpdateManifest.authenticated(data, signature: Data(repeating: 0, count: 64), publicKey: publicKey) }
        rejected { _ = try UpdateManifest.authenticated(data, signature: signature, publicKey: "bad") }
        rejected { try decoded.validate(current: "0.3.0", tag: "v0.3.0", system: system) }
        rejected { try decoded.validate(current: "0.4.0", tag: "v0.3.0", system: system) }
        rejected { try decoded.validate(current: "0.2.0", tag: "v9.0.0", system: system) }
        rejected { try decoded.validate(current: "0.2.0", tag: "v0.3.0", system: OperatingSystemVersion(majorVersion: 12, minorVersion: 0, patchVersion: 0)) }
        expect(GitHubPolicy.isAssetAPI(URL(string: "https://api.github.com/repos/sodacore-studios/zero-hour-macos/releases/assets/123")!))
        for bad in ["http://api.github.com/repos/sodacore-studios/zero-hour-macos/releases/assets/123", "https://api.github.com/other", "https://evil.example/123", "https://api.github.com/repos/sodacore-studios/zero-hour-macos/releases/assets/123?token=abc", "https://user@api.github.com/repos/sodacore-studios/zero-hour-macos/releases/assets/123"] {
            expect(!GitHubPolicy.isAssetAPI(URL(string: bad)!))
        }
        expect(GitHubPolicy.allowedRedirect(URL(string: "https://release-assets.githubusercontent.com/file?sig=example")!))
        expect(!GitHubPolicy.allowedRedirect(URL(string: "https://github.evil.example/file")!))
        expect(!GitHubPolicy.allowedRedirect(URL(string: "http://objects.githubusercontent.com/file")!))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("new.app"), destination = root.appendingPathComponent("installed.app")
        for directory in [source, destination] { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        try Data("old".utf8).write(to: destination.appendingPathComponent("marker"))
        try Data("new".utf8).write(to: source.appendingPathComponent("marker"))
        rejected { try UpdateInstaller.replace(source: source, destination: destination, validate: { _ in throw UpdateFailure("bad signature") }, reopen: { _ in }) }
        expect(try String(contentsOf: destination.appendingPathComponent("marker"), encoding: .utf8) == "old")
        rejected { try UpdateInstaller.replace(source: source, destination: destination, validate: { _ in }, reopen: { _ in throw UpdateFailure("launch failure") }) }
        expect(try String(contentsOf: destination.appendingPathComponent("marker"), encoding: .utf8) == "old")
        try UpdateInstaller.replace(source: source, destination: destination, validate: { _ in }, reopen: { _ in })
        expect(try String(contentsOf: destination.appendingPathComponent("marker"), encoding: .utf8) == "new")
        expect(try String(contentsOf: destination.appendingPathExtension("previous").appendingPathComponent("marker"), encoding: .utf8) == "old")
        rejected { try UpdateInstaller.validateBundle(source, version: "0.3.0") }
        print("Updater tests passed: signatures, hashes, versions, host policy, failed validation, rollback, successful replacement.")
    }
}
