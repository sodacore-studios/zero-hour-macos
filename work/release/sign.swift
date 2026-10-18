import Foundation
import CryptoKit

// Private key input is a file outside the repository, never a command-line value.
let args = CommandLine.arguments
if args.count == 3 && args[1] == "generate" {
    let key = Curve25519.Signing.PrivateKey()
    let url = URL(fileURLWithPath: args[2])
    guard !FileManager.default.fileExists(atPath: url.path) else { fatalError("Key already exists") }
    try key.rawRepresentation.write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    print(key.publicKey.rawRepresentation.base64EncodedString())
} else if args.count == 5 && args[1] == "sign" {
    let key = try Curve25519.Signing.PrivateKey(rawRepresentation: Data(contentsOf: URL(fileURLWithPath: args[2])))
    let data = try Data(contentsOf: URL(fileURLWithPath: args[3]))
    try key.signature(for: data).write(to: URL(fileURLWithPath: args[4]))
} else { fatalError("Usage: sign generate KEY_PATH | sign sign KEY_PATH MANIFEST SIGNATURE") }
