# Clipper

Keyboard-first macOS screenshots for developer workflows.

Clipper is a small CLI for capturing the UI target you care about without
reaching for the mouse. The first slice supports focused-window capture through
`yabai` and macOS `screencapture`.

## Status

Implemented:

- `clipper front`
- `clipper window --source yabai`
- `clipper window --source system`
- `--output PATH`
- `--copy`
- `--quiet`
- `--json`

Planned:

- Combined `yabai` + native system window discovery
- `clipper menu`

## Install Locally

From the repo:

```sh
./bin/clipper --help
```

Optionally put it on your `PATH`:

```sh
ln -s "$PWD/bin/clipper" /usr/local/bin/clipper
```

## Usage

Capture the focused window to the clipboard:

```sh
clipper front
```

Save the focused window to a file:

```sh
clipper front --output ~/Desktop/window.png
```

Save and copy:

```sh
clipper front --output ~/Desktop/window.png --copy
```

Pick a yabai window with `fzf`:

```sh
clipper window --source yabai
```

Pick a native macOS window with `fzf`:

```sh
clipper window --source system
```

Machine-readable output:

```sh
clipper front --json
```

## Requirements

- macOS
- `yabai`
- `jq`
- `fzf`
- `screencapture`
- Swift toolchain for the native system window provider

Your terminal needs macOS Screen Recording permission for actual captures.
