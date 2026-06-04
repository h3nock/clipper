import Foundation

public struct CaptureOptions: Equatable, Sendable {
    public let outputURL: URL?
    public let copy: Bool
    public let quiet: Bool
    public let json: Bool

    public init(
        outputURL: URL? = nil,
        copy: Bool? = nil,
        quiet: Bool = false,
        json: Bool = false
    ) {
        self.outputURL = outputURL
        self.copy = copy ?? (outputURL == nil)
        self.quiet = quiet
        self.json = json
    }

    static func parse(_ args: [String]) throws -> CaptureOptions {
        var outputPath: String?
        var copy: Bool?
        var quiet = false
        var json = false
        var remaining = args

        while !remaining.isEmpty {
            let arg = remaining.removeFirst()
            switch arg {
            case "--output":
                guard let path = remaining.first, !path.hasPrefix("-") else {
                    throw ClipperError.invalidArguments("--output requires a path.")
                }
                outputPath = path
                remaining.removeFirst()
            case "--copy":
                copy = true
            case "--quiet":
                quiet = true
            case "--json":
                json = true
            case "-h", "--help":
                throw ClipperError.invalidArguments(CLI.help)
            default:
                throw ClipperError.invalidArguments("Unknown option: \(arg)")
            }
        }

        return CaptureOptions(
            outputURL: outputPath.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) },
            copy: copy,
            quiet: quiet,
            json: json
        )
    }

    static func hasJSONFlag(_ args: [String]) -> Bool {
        args.contains("--json")
    }

    static func hasHelpFlag(_ args: [String]) -> Bool {
        args.contains("-h") || args.contains("--help")
    }
}
