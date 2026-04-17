import ApplicationServices
import Foundation

enum FocusedElementInspector {
    private static let textRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
    ]

    static func hasEditableTextFocus() -> Bool {
        guard AXIsProcessTrusted() else {
            return false
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard
            focusedStatus == .success,
            let focusedElement
        else {
            return false
        }

        let element = focusedElement as! AXUIElement
        var roleValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String,
           textRoles.contains(role) {
            return true
        }

        var selectedTextRange: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedTextRange
        ) == .success {
            return true
        }

        var selectedText: CFTypeRef?
        return AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        ) == .success
    }
}
