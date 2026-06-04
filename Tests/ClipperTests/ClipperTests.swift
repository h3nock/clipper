import Foundation
import Testing
@testable import ClipperCore

@Test func captureOptionsCopyToClipboardByDefault() throws {
    let options = try CaptureOptions.parse([])

    #expect(options.outputURL == nil)
    #expect(options.copy)
}

@Test func commandDefaultsToPickForNoArguments() {
    let parsed = ClipperCore.CLI.commandAndArguments([])

    #expect(parsed.command == "pick")
    #expect(parsed.arguments.isEmpty)
}

@Test func commandDefaultsToPickWhenFirstArgumentIsAnOption() {
    let parsed = ClipperCore.CLI.commandAndArguments(["--output", "/tmp/window.png"])

    #expect(parsed.command == "pick")
    #expect(parsed.arguments == ["--output", "/tmp/window.png"])
}

@Test func commandKeepsExplicitCommandArguments() {
    let parsed = ClipperCore.CLI.commandAndArguments(["current", "--json"])

    #expect(parsed.command == "current")
    #expect(parsed.arguments == ["--json"])
}

@Test func pickUsesCaptureTargetsWithoutFocusingContract() {
    let picker = RecordingPicker()
    let cli = testCLI(picker: picker)

    let status = cli.run(["pick"])

    #expect(status == 130)
    #expect(picker.windows.map(\.id) == [1])
}

@Test func captureOptionsDoNotCopySavedFilesUnlessRequested() throws {
    let options = try CaptureOptions.parse(["--output", "/tmp/window.png"])

    #expect(options.outputURL?.path == "/tmp/window.png")
    #expect(!options.copy)
}

@Test func captureOptionsCanSaveAndCopy() throws {
    let options = try CaptureOptions.parse(["--output", "/tmp/window.png", "--copy"])

    #expect(options.outputURL?.path == "/tmp/window.png")
    #expect(options.copy)
}

@Test func captureOptionsRejectMissingOutputPath() {
    #expect(throws: ClipperError.invalidArguments("--output requires a path.")) {
        _ = try CaptureOptions.parse(["--output"])
    }
}

@Test func screencaptureArgumentsCopyToClipboard() {
    let args = ScreencaptureWindowCapturer.arguments(windowID: 42, outputURL: nil, copy: true)

    #expect(args == ["-x", "-l42", "-c"])
}

@Test func screencaptureArgumentsSaveToFile() {
    let url = URL(fileURLWithPath: "/tmp/window.png")
    let args = ScreencaptureWindowCapturer.arguments(windowID: 42, outputURL: url, copy: false)

    #expect(args == ["-x", "-l42", "/tmp/window.png"])
}

@Test func fzfDisplayLineShowsOnlySpaceAppAndTitle() {
    let window = WindowRecord(
        id: 42,
        app: "Ghostty",
        title: "ta kbolt",
        pid: 10,
        layer: 0,
        visible: true,
        frame: WindowFrame(x: 12, y: 34, width: 900, height: 700),
        space: 2
    )

    let line = FzfCapturePicker.displayLine(for: window, appWidth: 7)

    #expect(line == "S2  Ghostty  ta kbolt")
    #expect(!line.contains("42"))
    #expect(!line.contains("900x700"))
}

@Test func fzfAppColumnWidthIsCapped() {
    let windows = [
        testWindow(app: "VeryLongApplicationNameThatShouldClip"),
        testWindow(app: "App"),
    ]

    #expect(FzfCapturePicker.appColumnWidth(for: windows) == 24)
}

@Test func captureTargetFilterKeepsUnknownSpaceWindowsWhenNoSpaceMetadataExists() {
    let windows = [
        testWindow(id: 1, space: nil),
        testWindow(id: 2, space: nil),
    ]

    let filtered = WindowCaptureTargetFilter.candidates(from: windows)

    #expect(filtered.map(\.id) == [1, 2])
}

@Test func captureTargetFilterDropsUnknownSpaceSurfacesWhenSpaceMetadataExists() {
    let windows = [
        testWindow(id: 1, space: 1),
        testWindow(id: 2, space: nil),
    ]

    let filtered = WindowCaptureTargetFilter.candidates(from: windows)

    #expect(filtered.map(\.id) == [1])
}

private func testWindow(app: String) -> WindowRecord {
    testWindow(id: 1, app: app)
}

private func testWindow(
    id: Int,
    app: String = "Ghostty",
    space: Int? = nil
) -> WindowRecord {
    WindowRecord(
        id: id,
        app: app,
        title: "",
        pid: 10,
        layer: 0,
        visible: true,
        frame: WindowFrame(x: 0, y: 0, width: 200, height: 160),
        space: space
    )
}

private func testCLI(picker: RecordingPicker) -> ClipperCore.CLI {
    ClipperCore.CLI(
        lister: TestWindowLister(),
        picker: picker,
        capturer: NoopCapturer()
    )
}

private struct TestWindowLister: WindowListing {
    func listCaptureTargets() throws -> [WindowRecord] {
        [testWindow(id: 1)]
    }

    func currentWindow() throws -> WindowRecord? {
        testWindow(id: 2)
    }
}

private final class RecordingPicker: WindowPicking, @unchecked Sendable {
    private(set) var windows: [WindowRecord] = []

    func execCapturePicker(
        from windows: [WindowRecord],
        binaryPath: String,
        arguments: [String]
    ) throws -> Never {
        self.windows = windows
        throw ClipperError.cancelled
    }
}

private struct NoopCapturer: WindowScreenshotCapturing {
    func capture(windowID: Int, options: CaptureOptions) throws -> WindowCaptureOutput {
        WindowCaptureOutput(copied: false, outputPath: nil)
    }
}
