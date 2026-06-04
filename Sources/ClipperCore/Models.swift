import Foundation

public struct WindowFrame: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct WindowRecord: Codable, Equatable, Sendable {
    public let id: Int
    public let app: String
    public let title: String
    public let pid: Int32
    public let layer: Int
    public let visible: Bool
    public let frame: WindowFrame
    public let space: Int?

    public init(
        id: Int,
        app: String,
        title: String,
        pid: Int32,
        layer: Int,
        visible: Bool,
        frame: WindowFrame,
        space: Int? = nil
    ) {
        self.id = id
        self.app = app
        self.title = title
        self.pid = pid
        self.layer = layer
        self.visible = visible
        self.frame = frame
        self.space = space
    }

    public var displayTitle: String {
        title.isEmpty ? app : "\(app) - \(title)"
    }

    public var spaceLabel: String {
        guard let space else {
            return "-"
        }
        return "S\(space)"
    }
}
