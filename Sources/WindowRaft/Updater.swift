import AppKit
import CryptoKit
import Foundation

/// Checks GitHub for a newer release and installs it, after proving it was signed by the project.
/// The same design as Cool Head's updater (same maintainer); see docs/UPDATES.md.
///
/// What it sends: one request to GitHub's public API for the latest release, and, if you choose to
/// install, the download of that release's zip and signature. Nothing about you or your Mac.
/// How it knows the update is genuine: each release zip is signed with the project's private key in
/// the release workflow; the matching public key is built into this app, and an update whose
/// signature doesn't verify is refused. It never installs on its own: only when you choose to.
/// Used from the main thread only; its two network steps are pinned there.
final class Updater {
    static let shared = Updater()
    /// The public half of the update-signing key (docs/UPDATES.md). Changing it means older versions
    /// can't verify newer updates, so it changes only if the private key is lost or exposed.
    nonisolated static let publicKey = "J3342F7iOUJGsj6g+kOkWe6RonmacKW4KFtHGnafY5M="
    nonisolated static let latestURL = URL(string: "https://api.github.com/repos/ThePhilDiamond/WindowRaft/releases/latest")!

    enum Phase: Equatable { case idle, checking, upToDate, available(String), installing, failed(String) }
    private(set) var phase: Phase = .idle
    private(set) var releasePage: URL?
    /// The latest release's notes, as its Markdown on GitHub (CHANGELOG.md's section for that version).
    private(set) var releaseNotes: String?
    private var zip: URL?
    private var sig: URL?
    private var timer: Timer?

    nonisolated static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// Whether Window Raft checks by itself, a minute after opening and then once a day (on unless turned off).
    var automatic: Bool {
        get { UserDefaults.standard.object(forKey: "checkForUpdates") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "checkForUpdates"); schedule() }
    }

    func schedule() {
        timer?.invalidate()
        guard automatic else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task { @MainActor in await Updater.shared.check(quiet: true) }
        }
        Task { @MainActor in try? await Task.sleep(for: .seconds(60)); await Updater.shared.check(quiet: true) }
    }

    /// `quiet`: an automatic check changes nothing the menu shows unless there is an update.
    @MainActor func check(quiet: Bool) async {
        if case .installing = phase { return }
        if !quiet { phase = .checking }
        do {
            var req = URLRequest(url: Updater.latestURL)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String, let assets = json["assets"] as? [[String: Any]] else {
                throw Problem("GitHub's answer wasn't readable")
            }
            let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            releasePage = (json["html_url"] as? String).flatMap(URL.init(string:))
            releaseNotes = json["body"] as? String
            func asset(_ suffix: String) -> URL? {
                assets.first { ($0["name"] as? String)?.hasSuffix(suffix) == true }
                    .flatMap { $0["browser_download_url"] as? String }.flatMap(URL.init(string:))
            }
            zip = asset(".zip"); sig = asset(".zip.sig")
            // an update already found to need a newer macOS isn't offered again (a later one is)
            let tooNew = UserDefaults.standard.string(forKey: Updater.needsNewerMacOSKey) == version
            if Updater.newer(version, than: Updater.currentVersion) && !tooNew {
                phase = .available(version)
            } else if !quiet {
                phase = .upToDate
            }
        } catch {
            if !quiet { phase = .failed("Couldn't check for updates: \(error.localizedDescription)") }
        }
    }

    /// Downloads, verifies and installs the update, then reopens Window Raft.
    @MainActor func install() async {
        guard case .available(let version) = phase else { return }
        guard let zip, let sig else {
            phase = .failed("This release can't be installed from inside Window Raft. Download it from its release page instead.")
            return
        }
        phase = .installing
        do {
            let (zipFile, _) = try await URLSession.shared.download(from: zip)
            let (sigData, _) = try await URLSession.shared.data(from: sig)
            let zipData = try Data(contentsOf: zipFile)
            // 1. the signature: made with the project's private key, or refused
            guard Updater.verify(zipData, signature: String(decoding: sigData, as: UTF8.self), publicKey: Updater.publicKey) else {
                throw Problem("The update's signature didn't match, so it wasn't installed.")
            }
            // 2. unpack it apart from everything else, and check it is Window Raft at the version expected
            let work = FileManager.default.temporaryDirectory.appendingPathComponent("WindowRaftUpdate-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            try Updater.run("/usr/bin/ditto", ["-x", "-k", zipFile.path, work.path])
            let app = work.appendingPathComponent("Window Raft.app")
            guard let info = Bundle(url: app)?.infoDictionary,
                  info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
                  info["CFBundleShortVersionString"] as? String == version else {
                throw Problem("The download wasn't the expected version of Window Raft.")
            }
            // 2a. it must run on this Mac: otherwise a working copy would be replaced by one macOS
            // refuses to open, so it isn't installed, and isn't offered again
            let minimum = info["LSMinimumSystemVersion"] as? String
            guard Updater.runs(minimum: minimum) else {
                UserDefaults.standard.set(version, forKey: Updater.needsNewerMacOSKey)
                throw Problem("Window Raft \(version) needs macOS \(minimum ?? "?") or later, so it wasn't installed.")
            }
            try Updater.run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
            // 3. replace this copy (the old one goes to the Trash, so it can be put back) and reopen
            let here = Bundle.main.bundleURL
            try FileManager.default.trashItem(at: here, resultingItemURL: nil)
            try FileManager.default.moveItem(at: app, to: here)
            let reopen = Process()
            reopen.executableURL = URL(fileURLWithPath: "/bin/sh")
            reopen.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", here.path]
            try reopen.run()
            NSApp.terminate(nil)
        } catch {
            phase = .failed((error as? Problem)?.message ?? "The update couldn't be installed: \(error.localizedDescription)")
        }
    }

    /// After a failure or an "up to date" has been seen, the menu goes back to plain.
    func acknowledge() {
        switch phase {
        case .upToDate, .failed: phase = .idle
        default: break
        }
    }

    /// What's new, from a release's notes: each "### Added", "### Changed" or "### Fixed" heading with the
    /// "- " items under it, without Markdown's ** and ` marks. Anything else, such as the downloads
    /// paragraph, is left out, and so is a heading with no items.
    nonisolated static func whatsNew(_ markdown: String) -> [(heading: String, items: [String])] {
        var sections: [(heading: String, items: [String])] = []
        for raw in markdown.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("### ") {
                sections.append((String(line.dropFirst(4)), []))
            } else if line.hasPrefix("- "), !sections.isEmpty {
                let item = line.dropFirst(2).replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "`", with: "")
                sections[sections.count - 1].items.append(item)
            }
        }
        return sections.filter { !$0.items.isEmpty }
    }

    static let needsNewerMacOSKey = "updateNeedsNewerMacOS"

    /// Whether `signature` (base64) is the project's signature of `data`, for `publicKey` (base64).
    nonisolated static func verify(_ data: Data, signature: String, publicKey: String) -> Bool {
        guard let keyData = Data(base64Encoded: publicKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              let sig = Data(base64Encoded: signature.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return key.isValidSignature(sig, for: data)
    }

    nonisolated static func newer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }

    /// Whether this Mac's macOS is at least `minimum` (nil: no minimum stated).
    nonisolated static func runs(minimum: String?, on os: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion) -> Bool {
        guard let minimum else { return true }
        let here = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        return !newer(minimum, than: here)
    }

    static func run(_ tool: String, _ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw Problem("A check on the download failed (\((tool as NSString).lastPathComponent)).") }
    }

    struct Problem: Error { let message: String; init(_ m: String) { message = m } }
}
