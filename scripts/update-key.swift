// Makes the Ed25519 key pair that signs FloatPiP's updates.
// Usage: swift scripts/update-key.swift <folder>   (writes update-signing-key.txt there; prints the public key)
// The private key goes into the GitHub secret UPDATE_SIGNING_KEY and a password manager; the public key goes into
// Sources/FloatPiP/Updater.swift. Run once: a new key means older versions can't verify newer updates.
import CryptoKit
import Foundation

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let key = Curve25519.Signing.PrivateKey()
let file = dir.appendingPathComponent("update-signing-key.txt")
guard !FileManager.default.fileExists(atPath: file.path) else { print("A key already exists at \(file.path); not replacing it."); exit(1) }
try! key.rawRepresentation.base64EncodedString().write(to: file, atomically: true, encoding: .utf8)
try! FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
print("public key: \(key.publicKey.rawRepresentation.base64EncodedString())")
