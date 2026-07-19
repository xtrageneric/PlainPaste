import AppKit

final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    static let hasOnboardedKey = "PlainPasteHasOnboarded"

    private var shortcutLabel: NSTextField!
    private var recorderView: ShortcutRecorderView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 470),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to PlainPaste"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        window.delegate = self

        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 100),
            iconView.heightAnchor.constraint(equalToConstant: 100)
        ])

        let titleLabel = NSTextField(labelWithString: "Welcome to PlainPaste")
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.alignment = .center

        let bodyLabel = NSTextField(wrappingLabelWithString: "PlainPaste is a magic formatting eraser that lives in your menu bar. Press your keyboard shortcut anywhere to clear formatting from the most recent item on your clipboard and paste as plain text — no fonts, colors, or links. Regular ⌘V still pastes normally. You can always change the shortcut later from the menu bar icon.")
        bodyLabel.alignment = .center
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.widthAnchor.constraint(equalToConstant: 360).isActive = true

        let instructions = NSTextField(labelWithString: "Press your preferred shortcut now, or keep the default:")
        instructions.alignment = .center
        instructions.font = NSFont.systemFont(ofSize: 12)
        instructions.textColor = .secondaryLabelColor

        let shortcut = NSTextField(labelWithString: ShortcutStore.shared.current.displayString)
        shortcut.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        shortcut.alignment = .center
        shortcutLabel = shortcut

        let getStartedButton = NSButton(title: "Get Started", target: nil, action: nil)
        getStartedButton.bezelStyle = .rounded
        getStartedButton.keyEquivalent = "\r"

        let stack = NSStackView(views: [iconView, titleLabel, bodyLabel, instructions, shortcut, getStartedButton])
        stack.orientation = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(20, after: bodyLabel)
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        stack.alignment = .centerX

        let view = ShortcutRecorderView(frame: NSRect(x: 0, y: 0, width: 420, height: 470))
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        recorderView = view
        window.contentView = view

        getStartedButton.target = self
        getStartedButton.action = #selector(getStartedTapped)

        view.onLiveUpdate = { [weak self] text in
            self?.shortcutLabel.stringValue = text
        }
        view.onCandidateReady = { [weak self] ready in
            guard ready, let view = self?.recorderView, let keyCode = view.pendingKeyCode else { return }
            ShortcutStore.shared.current = Shortcut(flags: view.pendingFlags, keyCode: keyCode)
        }
        view.onConfirm = { [weak self] in
            self?.getStartedTapped()
        }
    }

    @objc private func getStartedTapped() {
        UserDefaults.standard.set(true, forKey: OnboardingWindowController.hasOnboardedKey)
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        HotkeyManager.isRecordingShortcut = false
    }

    func show() {
        HotkeyManager.isRecordingShortcut = true
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        if let view = recorderView {
            window?.makeFirstResponder(view)
        }
    }
}
