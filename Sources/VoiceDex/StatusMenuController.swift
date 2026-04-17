import AppKit

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let stateItem = NSMenuItem(title: "State: idle", action: nil, keyEquivalent: "")
    private let detailItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
    private let openSettingsHandler: () -> Void
    private let openConfigHandler: () -> Void
    private let quitHandler: () -> Void

    init(
        openSettingsHandler: @escaping () -> Void,
        openConfigHandler: @escaping () -> Void,
        quitHandler: @escaping () -> Void
    ) {
        self.openSettingsHandler = openSettingsHandler
        self.openConfigHandler = openConfigHandler
        self.quitHandler = quitHandler
        super.init()
        configureMenu()
    }

    func update(stateLabel: String, detail: String) {
        statusItem.button?.title = stateLabel
        stateItem.title = "State: \(detail)"
        detailItem.title = detail
    }

    private func configureMenu() {
        statusItem.button?.title = "vd"

        let menu = NSMenu()
        menu.addItem(stateItem)
        menu.addItem(detailItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let openConfigItem = NSMenuItem(
            title: "Open Config Folder",
            action: #selector(openConfigFolder),
            keyEquivalent: ""
        )
        openConfigItem.target = self
        menu.addItem(openConfigItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func openSettings() {
        openSettingsHandler()
    }

    @objc
    private func openConfigFolder() {
        openConfigHandler()
    }

    @objc
    private func quitApp() {
        quitHandler()
    }
}
