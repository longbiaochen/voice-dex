import AppKit
import ApplicationServices
import Foundation

enum InjectionError: LocalizedError {
    case keyEventFailed

    var errorDescription: String? {
        switch self {
        case .keyEventFailed:
            return "生成 Cmd+V 事件失败。"
        }
    }
}

enum InjectionOutcome: Sendable {
    case pasted
    case copiedToClipboard
}

@MainActor
final class TextInjector {
    func inject(text: String, preserveClipboard: Bool, restoreDelayMilliseconds: UInt64) throws -> InjectionOutcome {
        let pasteboard = NSPasteboard.general
        let snapshot = preserveClipboard ? PasteboardSnapshot.capture(from: pasteboard) : nil

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard FocusedElementInspector.hasEditableTextFocus(), AXIsProcessTrusted() else {
            return .copiedToClipboard
        }

        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else {
            throw InjectionError.keyEventFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        if let snapshot {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: restoreDelayMilliseconds * 1_000_000)
                snapshot.restore(to: pasteboard)
            }
        }

        return .pasted
    }
}

private struct PasteboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let snapshot = pasteboard.pasteboardItems?.map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
        } ?? []
        return PasteboardSnapshot(items: snapshot)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        for item in items {
            let pasteboardItem = NSPasteboardItem()
            for (type, data) in item {
                pasteboardItem.setData(data, forType: type)
            }
            pasteboard.writeObjects([pasteboardItem])
        }
    }
}
