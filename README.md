# Clipper

Keyboard-first macOS screenshots for developer workflows.

Clipper is a small native CLI for capturing the UI target you care about without
reaching for the mouse. It lists macOS windows with CoreGraphics, lets you pick
with `fzf`, and captures by window ID with macOS `screencapture`.

## Install

Install with Homebrew:

```sh
brew install h3nock/tap/clipper
```

From source:

```sh
swift build -c release
install -m 0755 .build/release/clipper ~/.local/bin/clipper
```

## Usage

Pick a window with `fzf` and copy its screenshot to the clipboard:

```sh
clipper
```

This captures by macOS window ID and does not move focus.

Capture the currently focused window to the clipboard:

```sh
clipper current
```

This is most useful from a global hotkey. If you type it in a terminal, the
terminal is the focused window.

Save a picked window to a file:

```sh
clipper pick --output ~/Desktop/window.png
```

Save and copy:

```sh
clipper pick --output ~/Desktop/window.png --copy
```

Check setup:

```sh
clipper doctor
```

Machine-readable success/error output:

```sh
clipper pick --json
```

## Requirements

- macOS 14 or newer
- `screencapture`
- `fzf` for `clipper pick`
- `yabai` is optional; when present, Clipper uses it only for Space labels
- Swift toolchain for local builds

macOS Screen Recording permission is required for the app that launches
`clipper`, such as your terminal or hotkey app.
