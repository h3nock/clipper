# Clipper

Keyboard-first macOS screenshots for developer workflows.

Clipper is a small native CLI for capturing the UI target you care about without
reaching for the mouse. It lists macOS windows with CoreGraphics, lets you pick
with `fzf`, and captures by window ID with macOS `screencapture`.

## Status

Implemented:

- `clipper`
- `clipper pick`
- `clipper current`
- `clipper doctor`
- `--output PATH`
- `--copy`
- `--quiet`
- `--json`

Planned:

- visual window slots

## Install

After a release is published to the Homebrew tap:

```sh
brew install h3nock/tap/clipper
```

From source:

```sh
swift build -c release
install -m 0755 .build/release/clipper ~/.local/bin/clipper
```

The installed binary is standalone at runtime. It does not shell out to
`winpick` or depend on `winpick`.

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

Captures need Screen Recording permission for the host app.
