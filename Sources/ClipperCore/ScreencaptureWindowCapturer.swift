import AppKit
import Foundation

public protocol WindowScreenshotCapturing {
    func capture(windowID: Int, options: CaptureOptions) throws -> WindowCaptureOutput
}

public struct WindowCaptureOutput: Equatable, Sendable {
    public let copied: Bool
    public let outputPath: String?

    public init(copied: Bool, outputPath: String?) {
        self.copied = copied
        self.outputPath = outputPath
    }
}

public struct ScreencaptureWindowCapturer: WindowScreenshotCapturing {
    public init() {}

    public func capture(windowID: Int, options: CaptureOptions) throws -> WindowCaptureOutput {
        guard Self.commandExists() else {
            throw ClipperError.missingDependency("screencapture")
        }

        if let outputURL = options.outputURL {
            try captureToFile(windowID: windowID, outputURL: outputURL)
            if options.copy {
                try copyPNGToClipboard(outputURL)
            }
            return WindowCaptureOutput(copied: options.copy, outputPath: outputURL.path)
        }

        try runScreencapture(arguments: Self.arguments(windowID: windowID, outputURL: nil, copy: true))
        return WindowCaptureOutput(copied: true, outputPath: nil)
    }

    private func captureToFile(windowID: Int, outputURL: URL) throws {
        let outputDirectory = outputURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: outputDirectory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw ClipperError.outputDirectoryMissing(outputDirectory.path)
        }

        try runScreencapture(arguments: Self.arguments(windowID: windowID, outputURL: outputURL, copy: false))
    }

    private func runScreencapture(arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.screencapturePath)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorText = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw ClipperError.captureFailed(errorText)
        }
    }

    private func copyPNGToClipboard(_ url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            guard pasteboard.setData(data, forType: .png) else {
                throw ClipperError.clipboardFailed("NSPasteboard rejected PNG data.")
            }
        } catch let error as ClipperError {
            throw error
        } catch {
            throw ClipperError.clipboardFailed(error.localizedDescription)
        }
    }

    static func arguments(windowID: Int, outputURL: URL?, copy: Bool) -> [String] {
        var args = ["-x", "-l\(windowID)"]
        if copy {
            args.append("-c")
        }
        if let outputURL {
            args.append(outputURL.path)
        }
        return args
    }

    public static func commandExists() -> Bool {
        FileManager.default.isExecutableFile(atPath: screencapturePath)
    }

    static let screencapturePath = "/usr/sbin/screencapture"
}
