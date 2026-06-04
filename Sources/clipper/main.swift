import ClipperCore
import Darwin

let cli = CLI(
    lister: SystemWindowLister(),
    picker: FzfCapturePicker(),
    capturer: ScreencaptureWindowCapturer()
)

exit(cli.run(Array(CommandLine.arguments.dropFirst())))
