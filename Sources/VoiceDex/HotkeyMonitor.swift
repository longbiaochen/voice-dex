import Carbon
import Foundation

enum HotKeyError: LocalizedError {
    case installHandler(OSStatus)
    case register(OSStatus)

    var errorDescription: String? {
        switch self {
        case .installHandler(let status):
            return "无法安装全局热键处理器，状态码 \(status)。"
        case .register(let status):
            return "无法注册全局热键，状态码 \(status)。"
        }
    }
}

final class HotkeyMonitor {
    private static let signature = OSType(0x56444B59) // VDKY

    private let id: UInt32
    private let onPress: @Sendable () -> Void
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(keyCode: UInt32, modifiers: UInt32 = 0, onPress: @escaping @Sendable () -> Void) throws {
        self.id = UInt32.random(in: 1...UInt32.max)
        self.onPress = onPress

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, eventRef, userData in
            guard
                let eventRef,
                let userData
            else {
                return OSStatus(noErr)
            }

            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr, hotKeyID.id == monitor.id else {
                return OSStatus(noErr)
            }

            monitor.onPress()
            return OSStatus(noErr)
        }

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            throw HotKeyError.installHandler(installStatus)
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            OptionBits(0),
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            throw HotKeyError.register(registerStatus)
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}
