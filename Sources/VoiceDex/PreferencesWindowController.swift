import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    init(
        config: AppConfig,
        onSave: @escaping (AppConfig) -> Void,
        onOpenConfigFolder: @escaping () -> Void
    ) {
        let view = PreferencesView(
            initialConfig: config,
            onSave: onSave,
            onOpenConfigFolder: onOpenConfigFolder
        )
        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "voice-dex Settings"
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.center()
        window.contentViewController = hostingController

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct PreferencesView: View {
    @State private var config: AppConfig
    let onSave: (AppConfig) -> Void
    let onOpenConfigFolder: () -> Void

    init(
        initialConfig: AppConfig,
        onSave: @escaping (AppConfig) -> Void,
        onOpenConfigFolder: @escaping () -> Void
    ) {
        _config = State(initialValue: initialConfig)
        self.onSave = onSave
        self.onOpenConfigFolder = onOpenConfigFolder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("voice-dex")
                .font(.system(size: 28, weight: .semibold))

            Text("Press F5 to start. Press F5 again to finish. voice-dex transcribes, optionally polishes, then pastes or copies the final text.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Form {
                Section("Trigger") {
                    HStack {
                        Text("Hotkey")
                        Spacer()
                        Text("F5")
                            .monospaced()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Transcription") {
                    Picker("Provider", selection: $config.transcription.provider) {
                        ForEach(TranscriptionProvider.allCases) { provider in
                            Text(provider.title).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(config.transcription.provider.caption)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if config.transcription.provider == .openAICompatible {
                        TextField("Transcription Endpoint", text: $config.transcription.openAITranscriptionURL)
                        TextField("Model", text: $config.transcription.openAIModel)
                        TextField("API Key Env", text: $config.transcription.openAIAuthTokenEnv)
                    }
                }

                Section("Cleanup") {
                    Toggle("Enable AI Cleanup", isOn: $config.cleanup.enabled)

                    if config.cleanup.enabled {
                        TextField("Cleanup Endpoint", text: $config.cleanup.endpoint)
                        TextField("Cleanup Model", text: $config.cleanup.model)
                        TextField("Cleanup API Key Env", text: $config.cleanup.authTokenEnv)
                        TextField("Cleanup Auth Prefix", text: $config.cleanup.authHeaderPrefix)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cleanup Prompt")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextEditor(text: $config.cleanup.systemPrompt)
                                .font(.system(size: 13))
                                .frame(minHeight: 120)
                        }
                    }
                }

                Section("Insertion") {
                    Toggle("Restore clipboard after paste", isOn: $config.injection.preserveClipboard)
                }
            }

            HStack {
                Button("Open Config Folder", action: onOpenConfigFolder)
                Spacer()
                Button("Save Settings") {
                    onSave(config)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 560)
    }
}
