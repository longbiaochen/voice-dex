# voice-dex Repo Rules

- Keep the app lightweight and macOS-native. Do not add Electron, Tauri, or webview layers for core dictation UI.
- Preserve the single-trigger workflow: `F5` starts recording and `F5` stops recording.
- Treat `script/build_and_run.sh` and `scripts/check.sh` as the canonical local harness.
- Validate user-facing behavior through the real packaged app path in `dist/VoiceDex.app`, not only `swift build`.
- Keep paste behavior conservative: paste only when a focused editable target is detected; otherwise leave the final text in the clipboard.
- Prefer stable public APIs over private ChatGPT endpoints for default production flows.
- Keep docs current when changing product behavior, startup scripts, permissions, or provider configuration.
