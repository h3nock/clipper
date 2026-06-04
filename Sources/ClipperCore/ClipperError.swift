import Foundation

public enum ClipperError: Error, CustomStringConvertible, Equatable {
    case cancelled
    case invalidArguments(String)
    case noCurrentWindow
    case noWindows
    case fzfUnavailable
    case pickerRequiresTerminal
    case missingDependency(String)
    case outputDirectoryMissing(String)
    case captureFailed(String)
    case clipboardFailed(String)

    public var description: String {
        switch self {
        case .cancelled:
            return "Selection cancelled."
        case .invalidArguments(let message):
            return message
        case .noCurrentWindow:
            return "No current window found."
        case .noWindows:
            return "No windows found."
        case .fzfUnavailable:
            return """
            fzf is required for interactive selection but was not found on PATH.
            Install fzf with Homebrew:
              brew install fzf
            """
        case .pickerRequiresTerminal:
            return "Window picker requires an interactive terminal."
        case .missingDependency(let name):
            return "\(name) is required but was not found."
        case .outputDirectoryMissing(let path):
            return "Output directory does not exist: \(path)"
        case .captureFailed(let details):
            if details.isEmpty {
                return "Window capture failed. Check Screen Recording permission for the host app."
            }
            return "Window capture failed: \(details)"
        case .clipboardFailed(let details):
            return "Captured file but could not copy it to the clipboard: \(details)"
        }
    }
}
