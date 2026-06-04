import Foundation

public struct CLI {
    private let lister: WindowListing
    private let picker: WindowPicking
    private let capturer: WindowScreenshotCapturing

    public init(
        lister: WindowListing,
        picker: WindowPicking,
        capturer: WindowScreenshotCapturing
    ) {
        self.lister = lister
        self.picker = picker
        self.capturer = capturer
    }

    public func run(_ arguments: [String]) -> Int32 {
        let wantsJSON = CaptureOptions.hasJSONFlag(arguments)

        do {
            try runThrowing(arguments)
            return 0
        } catch ClipperError.cancelled {
            if wantsJSON {
                writeErrorJSON("Selection cancelled.", code: "cancelled")
            }
            return 130
        } catch let error as ClipperError {
            writeError(error.description, json: wantsJSON)
            return 1
        } catch {
            writeError(error.localizedDescription, json: wantsJSON)
            return 1
        }
    }

    private func runThrowing(_ arguments: [String]) throws {
        let parsed = Self.commandAndArguments(arguments)
        let command = parsed.command
        let args = parsed.arguments

        switch command {
        case "pick":
            try capturePickedWindow(args)
        case "capture-record":
            try captureWindowRecord(args)
        case "current":
            try captureCurrentWindow(args)
        case "doctor":
            try doctor(args)
        case "help", "-h", "--help":
            print(Self.help)
        case "version", "--version":
            print("clipper 0.1.0")
        default:
            throw ClipperError.invalidArguments("Unknown command: \(command)")
        }
    }

    private func capturePickedWindow(_ args: [String]) throws {
        if CaptureOptions.hasHelpFlag(args) {
            print(Self.help)
            return
        }

        _ = try CaptureOptions.parse(args)
        let windows = try lister.listCaptureTargets()

        try picker.execCapturePicker(
            from: windows,
            binaryPath: Bundle.main.executablePath ?? CommandLine.arguments[0],
            arguments: args
        )
    }

    private func captureWindowRecord(_ args: [String]) throws {
        guard let payload = args.first,
              let data = Data(base64Encoded: payload)
        else {
            throw ClipperError.invalidArguments("Usage: clipper capture-record <encoded-window-record>")
        }

        let window = try JSONDecoder().decode(WindowRecord.self, from: data)
        let options = try CaptureOptions.parse(Array(args.dropFirst()))
        try capture(window, mode: "pick", options: options)
    }

    private func captureCurrentWindow(_ args: [String]) throws {
        if CaptureOptions.hasHelpFlag(args) {
            print(Self.help)
            return
        }

        let options = try CaptureOptions.parse(args)
        guard let window = try lister.currentWindow() else {
            throw ClipperError.noCurrentWindow
        }

        try capture(window, mode: "current", options: options)
    }

    private func capture(
        _ window: WindowRecord,
        mode: String,
        options: CaptureOptions
    ) throws {
        let output = try capturer.capture(windowID: window.id, options: options)
        let result = CaptureResult(
            ok: true,
            mode: mode,
            target: window.displayTitle,
            windowID: window.id,
            copied: output.copied,
            output: output.outputPath
        )

        if options.json {
            try writeJSON(result)
            return
        }

        guard !options.quiet else { return }

        switch (output.outputPath, output.copied) {
        case (.some(let path), true):
            print("Saved and copied screenshot: \(window.displayTitle) -> \(path)")
        case (.some(let path), false):
            print("Saved screenshot: \(window.displayTitle) -> \(path)")
        case (.none, true):
            print("Copied screenshot: \(window.displayTitle)")
        case (.none, false):
            print("Captured screenshot: \(window.displayTitle)")
        }
    }

    private func doctor(_ args: [String]) throws {
        let json = CaptureOptions.hasJSONFlag(args)
        let allowedArgs = Set(["--json"])
        if let invalidArg = args.first(where: { !allowedArgs.contains($0) }) {
            throw ClipperError.invalidArguments("Unknown option for doctor: \(invalidArg)")
        }

        let report = DoctorReport(
            screencaptureFound: ScreencaptureWindowCapturer.commandExists(),
            fzfFound: FzfCapturePicker.commandExists(),
            spaceMetadataProvider: SystemWindowLister.optionalSpaceMetadataProviderName()
        )

        if json {
            try writeJSON(report)
            return
        }

        print("clipper doctor")
        print("screencapture: \(report.screencaptureFound ? "found" : "missing")")
        print("fzf: \(report.fzfFound ? "found" : "missing")")
        if !report.fzfFound {
            print("  Install: brew install fzf")
            print("  Then make sure `fzf` is on PATH.")
        }
        if let provider = report.spaceMetadataProvider {
            print("Space metadata: \(provider) (optional)")
        } else {
            print("Space metadata: unavailable")
        }
        print("Screen Recording: verified when a capture runs")
    }

    private func writeError(_ message: String, json: Bool) {
        if json {
            writeErrorJSON(message, code: "error")
        } else {
            FileHandle.standardError.write(Data("clipper: \(message)\n".utf8))
        }
    }

    private func writeJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    private func writeErrorJSON(_ message: String, code: String) {
        do {
            try writeJSON(ErrorResponse(ok: false, code: code, error: message))
        } catch {
            FileHandle.standardError.write(Data("clipper: \(message)\n".utf8))
        }
    }

    private struct ErrorResponse: Encodable {
        let ok: Bool
        let code: String
        let error: String
    }

    private struct DoctorReport: Encodable {
        let screencaptureFound: Bool
        let fzfFound: Bool
        let spaceMetadataProvider: String?
    }

    static func commandAndArguments(_ arguments: [String]) -> (command: String, arguments: [String]) {
        var args = arguments
        if let first = args.first, Self.globalCommands.contains(first) {
            args.removeFirst()
            return (first, args)
        }

        if let first = args.first, !first.hasPrefix("-") {
            args.removeFirst()
            return (first, args)
        }

        return ("pick", args)
    }

    public static let help = """
    clipper - keyboard-first macOS window screenshots

    Usage:
      clipper                         Pick a window and copy its screenshot
      clipper pick [options]          Pick a window and capture it
      clipper current [options]       Capture the currently focused window
      clipper doctor [--json]         Check setup
      clipper help
      clipper version

    Options:
      --output PATH                   Save screenshot to PATH
      --copy                          Copy when --output is also used
      --quiet                         Suppress success output
      --json                          Print machine-readable output

    Notes:
      - Default output is the clipboard.
      - `pick` captures by window id without moving focus.
      - `pick` requires fzf.
      - `current` is best from a global hotkey; typed in a terminal it captures that terminal.
      - Capturing requires Screen Recording permission for the host app.
    """

    private static let globalCommands = Set([
        "help",
        "-h",
        "--help",
        "version",
        "--version",
    ])
}

private struct CaptureResult: Encodable {
    let ok: Bool
    let mode: String
    let target: String
    let windowID: Int
    let copied: Bool
    let output: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case mode
        case target
        case windowID = "window_id"
        case copied
        case output
    }
}
