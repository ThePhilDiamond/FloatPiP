// Signs a release zip with the update key, for FloatPiP's in-app updater.
// Usage: UPDATE_SIGNING_KEY=<base64 private key> swift scripts/sign-update.swift <zip>   (writes <zip>.sig)
import CryptoKit
import Foundation

guard CommandLine.arguments.count > 1, let raw = ProcessInfo.processInfo.environment["UPDATE_SIGNING_KEY"],
      let keyData = Data(base64Encoded: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
      let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData) else {
    print("sign-update: needs UPDATE_SIGNING_KEY and a zip path"); exit(1)
}
let zip = URL(fileURLWithPath: CommandLine.arguments[1])
let sig = try! key.signature(for: Data(contentsOf: zip))
try! sig.base64EncodedString().write(to: URL(fileURLWithPath: zip.path + ".sig"), atomically: true, encoding: .utf8)
print("signed \(zip.lastPathComponent)")
