import Darwin
import Foundation

public protocol WindowPicking {
    func execCapturePicker(
        from windows: [WindowRecord],
        binaryPath: String,
        arguments: [String]
    ) throws -> Never
}

public struct FzfCapturePicker: WindowPicking {
    private let encoder = JSONEncoder()
    public init() {}

    public func execCapturePicker(
        from windows: [WindowRecord],
        binaryPath: String,
        arguments: [String]
    ) throws -> Never {
        guard isatty(STDIN_FILENO) == 1 || isatty(STDERR_FILENO) == 1 else {
            throw ClipperError.pickerRequiresTerminal
        }

        guard !windows.isEmpty else {
            throw ClipperError.noWindows
        }

        guard Self.commandExists() else {
            throw ClipperError.fzfUnavailable
        }

        let inputURL = try writeRowsToTemporaryFile(windows)
        let script = """
        trap 'rm -f "$CLIPPER_PICKER_FILE"' EXIT
        selected="$(\(Self.shellFzfCommand) < "$CLIPPER_PICKER_FILE")" || {
          if [[ "$CLIPPER_JSON" == "1" ]]; then
            printf '{"ok":false,"code":"cancelled","error":"Selection cancelled."}\\n'
          fi
          exit 130
        }
        payload="${selected%%$'\\t'*}"
        rm -f "$CLIPPER_PICKER_FILE"
        trap - EXIT
        exec "$CLIPPER_BIN" capture-record "$payload" "$@"
        """

        var environment = ProcessInfo.processInfo.environment
        environment["CLIPPER_PICKER_FILE"] = inputURL.path
        environment["CLIPPER_BIN"] = binaryPath
        environment["CLIPPER_JSON"] = arguments.contains("--json") ? "1" : "0"

        let argvStrings = ["zsh", "-fc", script, "clipper-picker"] + arguments
        var argv: [UnsafeMutablePointer<CChar>?] = argvStrings.map { strdup($0) }
        argv.append(nil)
        var envp: [UnsafeMutablePointer<CChar>?] = environment.map { key, value in
            strdup("\(key)=\(value)")
        }
        envp.append(nil)

        _ = argv.withUnsafeMutableBufferPointer { argvBuffer in
            envp.withUnsafeMutableBufferPointer { envBuffer in
                execve("/bin/zsh", argvBuffer.baseAddress, envBuffer.baseAddress)
            }
        }

        throw ClipperError.invalidArguments("Could not start fzf picker.")
    }

    private func writeRowsToTemporaryFile(_ windows: [WindowRecord]) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipper-\(UUID().uuidString).tsv")
        try Data(try pickerRows(from: windows).utf8).write(to: url, options: [.atomic])
        return url
    }

    private func pickerRows(from windows: [WindowRecord]) throws -> String {
        let appWidth = Self.appColumnWidth(for: windows)
        return try windows.map { window in
            try pickerLine(for: window, appWidth: appWidth)
        }.joined(separator: "\n") + "\n"
    }

    func pickerLine(for window: WindowRecord, appWidth: Int) throws -> String {
        let payload = try encoder.encode(window).base64EncodedString()
        return [
            payload,
            Self.displayLine(for: window, appWidth: appWidth),
            window.spaceLabel,
            sanitized(window.app),
            sanitized(window.title),
        ].joined(separator: "\t")
    }

    static let shellFzfCommand = """
    fzf --delimiter=$'\\t' --with-nth=2 --nth='1..' --prompt='clipper> ' --header='Space  App  Window' --layout=reverse --bind='ctrl-j:down,ctrl-k:up'
    """

    static func displayLine(for window: WindowRecord, appWidth: Int) -> String {
        let app = paddedAppName(sanitized(window.app), width: appWidth)
        let title = sanitized(window.title)
        if title.isEmpty {
            return "\(window.spaceLabel)  \(app)"
        }
        return "\(window.spaceLabel)  \(app)  \(title)"
    }

    static func appColumnWidth(for windows: [WindowRecord]) -> Int {
        let longestApp = windows
            .map { sanitized($0.app).count }
            .max() ?? 3
        return min(max(longestApp, 3), 24)
    }

    public static func commandExists() -> Bool {
        guard let path = ProcessInfo.processInfo.environment["PATH"] else {
            return false
        }

        return path
            .split(separator: ":")
            .contains { directory in
                access("\(directory)/fzf", X_OK) == 0
            }
    }
}

private func paddedAppName(_ app: String, width: Int) -> String {
    let clipped = clippedText(app, width: width)
    if clipped.count >= width {
        return clipped
    }
    return clipped + String(repeating: " ", count: width - clipped.count)
}

private func clippedText(_ text: String, width: Int) -> String {
    guard width > 3, text.count > width else {
        return text
    }
    return String(text.prefix(width - 3)) + "..."
}

private func sanitized(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\t", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
}
