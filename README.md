# Clipper

Keyboard-first macOS screenshots for developer workflows.

Clipper is a small CLI for capturing the UI target you care about without
reaching for the mouse. The first slice supports focused-window capture through
`yabai` and macOS `screencapture`.

## Status

Implemented:

- `clipper front`
- `--output PATH`
- `--copy`
- `--quiet`
- `--json`

Planned:

- `clipper window` with an `fzf` picker
- Combined `yabai` + native system window discovery
- `clipper sim` for booted Simulator screenshots
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

Machine-readable output:

```sh
clipper front --json
```

## Requirements

- macOS
- `yabai`
- `jq`
- `screencapture`

Your terminal needs macOS Screen Recording permission for actual captures.

