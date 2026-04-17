# voice-dex

`voice-dex` is a native macOS dictation app built for a fast `F5 -> speak -> AI cleanup -> paste or clipboard` workflow.

It is designed as a lightweight operator tool:

- global `F5` hotkey
- floating HUD during recording and processing
- optional AI cleanup prompt
- paste directly into the focused editor when possible
- fall back to clipboard when there is no editable target
- local Codex bridge support plus a stable OpenAI-compatible transcription path

## Project Status

`voice-dex` is actively developed on macOS and is currently optimized for the maintainer's Apple Silicon desktop workflow.

## Features

- Native menu bar app built with Swift and AppKit/SwiftUI
- Toggle recording on `F5`
- Floating HUD inspired by modern macOS dictation utilities
- Configurable transcription provider:
  - `codexChatGPTBridge`
  - `openAICompatible`
- Optional second-pass cleanup prompt through any OpenAI-compatible chat endpoint
- Smart insertion:
  - paste when an editable field is focused
  - otherwise keep the result in the clipboard
- Settings window for runtime configuration
- LaunchAgent install script for background startup

## Repository Layout

```text
Sources/VoiceDex/        App source
Tests/VoiceDexTests/     Swift tests
script/build_and_run.sh  Local build and launch entrypoint
scripts/check.sh         Build + test harness
scripts/package_app.sh   Build a signed local app bundle
scripts/install_launch_agent.sh  Install background startup
docs/                    Architecture and release docs
```

## Requirements

- macOS 13+
- Apple Silicon recommended
- Accessibility permission for automatic paste
- Microphone permission for recording

## Build

```bash
swift build --package-path .
```

## Test

```bash
swift test --package-path .
./scripts/check.sh
```

## Run

```bash
./script/build_and_run.sh
```

This builds `dist/VoiceDex.app`, signs it locally with an ad-hoc signature, and launches it.

## Install Background Startup

```bash
./scripts/install_launch_agent.sh
```

## Config

The app stores config at:

```text
~/Library/Application Support/VoiceDex/config.json
```

If an older `HotkeyVoice` config exists, `voice-dex` migrates it on first launch.

## Publishing Notes

See:

- [Architecture](docs/architecture.md)
- [Release Process](docs/release.md)
- [Contributing](CONTRIBUTING.md)

## License

MIT. See [LICENSE](LICENSE).
