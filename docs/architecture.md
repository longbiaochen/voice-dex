# Architecture

## Overview

`voice-dex` is a native macOS menu bar app with a narrow operator workflow:

1. User presses `F5`
2. App starts recording and shows a floating HUD
3. User presses `F5` again
4. Audio is transcribed
5. Optional cleanup runs on the transcript
6. Final text is pasted or copied

## Runtime Components

- `AppCoordinator`
  - owns the product workflow
  - bridges hotkey, recording, transcription, cleanup, HUD, notifications, and insertion
- `HotkeyMonitor`
  - registers the global hotkey
- `AudioRecorder`
  - records mono WAV audio for short dictation sessions
- `ChatGPTTranscriber`
  - runs the transcription request using the configured provider
- `CodexAuthClient`
  - fetches local Codex auth state when the experimental bridge path is used
- `TextPostProcessor`
  - applies optional AI cleanup
- `TextInjector`
  - copies text and pastes only when the focused target is editable
- `OverlayController`
  - renders the HUD shown during recording and processing
- `PreferencesWindowController`
  - renders the settings surface

## Provider Strategy

Two transcription paths exist:

- `codexChatGPTBridge`
  - useful for experimentation
  - depends on the local Codex login state
  - should not be treated as the default durable production path
- `openAICompatible`
  - preferred for production use
  - uses `/v1/audio/transcriptions`
  - supports stable OpenAI-compatible providers

## Packaging

- `scripts/package_app.sh` creates `dist/VoiceDex.app`
- the app bundle is ad-hoc signed locally for development runs
- `script/build_and_run.sh` packages then launches
- `scripts/install_launch_agent.sh` installs the LaunchAgent
