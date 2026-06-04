import AppKit
import CoreGraphics
import Darwin
import Foundation

public protocol WindowListing {
    func listCaptureTargets() throws -> [WindowRecord]
    func currentWindow() throws -> WindowRecord?
}

public struct SystemWindowLister: WindowListing {
    struct YabaiWindowInfo {
        let space: Int?
        let title: String?
    }

    public init() {}

    public func listCaptureTargets() throws -> [WindowRecord] {
        WindowCaptureTargetFilter.candidates(from: listRawWindows())
    }

    public func currentWindow() throws -> WindowRecord? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return nil
        }

        return listRawWindows()
            .filter { $0.pid == pid }
            .filter(WindowCaptureTargetFilter.isBaseCandidate)
            .sorted { lhs, rhs in
                if lhs.layer != rhs.layer { return lhs.layer < rhs.layer }
                return area(lhs.frame) > area(rhs.frame)
            }
            .first
    }

    public static func optionalSpaceMetadataProviderName() -> String? {
        commandPath("yabai") == nil ? nil : "yabai"
    }

    private func listRawWindows() -> [WindowRecord] {
        let yabaiInfoByWindowID = Self.yabaiWindowInfoByWindowID()
        let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
        let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

        return Self.sort(rawWindows.compactMap { window in
            Self.makeRecord(window, yabaiInfoByWindowID: yabaiInfoByWindowID)
        })
    }

    private static func makeRecord(
        _ window: [String: Any],
        yabaiInfoByWindowID: [Int: YabaiWindowInfo]
    ) -> WindowRecord? {
        guard let id = intValue(window[kCGWindowNumber as String]) else { return nil }

        let app = stringValue(window[kCGWindowOwnerName as String])
        guard !app.isEmpty, app != "Window Server" else { return nil }

        let yabaiInfo = yabaiInfoByWindowID[id]
        let title = preferredTitle(
            coreGraphicsTitle: stringValue(window[kCGWindowName as String]),
            yabaiTitle: yabaiInfo?.title
        )
        let pid = Int32(intValue(window[kCGWindowOwnerPID as String]) ?? 0)
        let layer = intValue(window[kCGWindowLayer as String]) ?? 0
        let alpha = doubleValue(window[kCGWindowAlpha as String]) ?? 1
        guard alpha > 0 else { return nil }

        guard let bounds = window[kCGWindowBounds as String] as? [String: Any] else {
            return nil
        }

        let width = doubleValue(bounds["Width"]) ?? 0
        let height = doubleValue(bounds["Height"]) ?? 0

        return WindowRecord(
            id: id,
            app: app,
            title: title,
            pid: pid,
            layer: layer,
            visible: true,
            frame: WindowFrame(
                x: doubleValue(bounds["X"]) ?? 0,
                y: doubleValue(bounds["Y"]) ?? 0,
                width: width,
                height: height
            ),
            space: yabaiInfo?.space
        )
    }

    static func sort(_ windows: [WindowRecord]) -> [WindowRecord] {
        windows.sorted { lhs, rhs in
            let lhsSpace = lhs.space ?? Int.max
            let rhsSpace = rhs.space ?? Int.max
            if lhsSpace != rhsSpace { return lhsSpace < rhsSpace }
            if lhs.app != rhs.app { return lhs.app < rhs.app }
            if lhs.title != rhs.title { return lhs.title < rhs.title }
            return lhs.id < rhs.id
        }
    }

    private func area(_ frame: WindowFrame) -> Double {
        frame.width * frame.height
    }

    private static func preferredTitle(coreGraphicsTitle: String, yabaiTitle: String?) -> String {
        if !coreGraphicsTitle.isEmpty {
            return coreGraphicsTitle
        }

        return yabaiTitle ?? ""
    }

    private static func yabaiWindowInfoByWindowID() -> [Int: YabaiWindowInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["yabai", "-m", "query", "--windows"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return [:]
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return [:]
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return [:]
        }

        var windows: [Int: YabaiWindowInfo] = [:]
        for row in rows {
            guard let id = intValue(row["id"]) else {
                continue
            }

            windows[id] = YabaiWindowInfo(
                space: intValue(row["space"]),
                title: stringValue(row["title"])
            )
        }

        return windows
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let int = value as? Int { return int }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String {
        value as? String ?? ""
    }

    private static func commandPath(_ name: String) -> String? {
        guard let path = ProcessInfo.processInfo.environment["PATH"] else {
            return nil
        }

        return path
            .split(separator: ":")
            .compactMap { directory -> String? in
                let candidate = "\(directory)/\(name)"
                return access(candidate, X_OK) == 0 ? candidate : nil
            }
            .first
    }
}
