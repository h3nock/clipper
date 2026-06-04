struct WindowCaptureTargetFilter {
    static func candidates(from windows: [WindowRecord]) -> [WindowRecord] {
        let baseWindows = windows.filter(isBaseCandidate)

        guard baseWindows.contains(where: { $0.space != nil }) else {
            return baseWindows
        }

        return baseWindows.filter { $0.space != nil }
    }

    static func isBaseCandidate(_ window: WindowRecord) -> Bool {
        window.visible
            && window.layer == 0
            && window.frame.width >= 160
            && window.frame.height >= 120
    }
}
