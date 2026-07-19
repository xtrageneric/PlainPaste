import AppKit

final class ShortcutRecorderView: NSView {
    var onLiveUpdate: ((String) -> Void)?
    var onCandidateReady: ((Bool) -> Void)?
    var onConfirm: (() -> Void)?

    private(set) var pendingFlags: CGEventFlags = []
    private(set) var pendingKeyCode: Int64?

    override var acceptsFirstResponder: Bool { true }

    override func flagsChanged(with event: NSEvent) {
        guard pendingKeyCode == nil else { return }
        let flags = Shortcut.cgFlags(from: event.modifierFlags)
        onLiveUpdate?(flags.isEmpty ? "…" : Shortcut.modifierSymbols(for: flags))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape cancels entirely
            window?.close()
            return
        }

        if event.keyCode == 36, pendingKeyCode != nil { // Return confirms a staged candidate
            onConfirm?()
            return
        }

        let flags = Shortcut.cgFlags(from: event.modifierFlags)
        guard !flags.isEmpty else { return } // require at least one modifier

        pendingFlags = flags
        pendingKeyCode = Int64(event.keyCode)
        onLiveUpdate?(Shortcut.modifierSymbols(for: flags) + Shortcut.keyName(for: Int64(event.keyCode)))
        onCandidateReady?(true)
    }
}

final class ShortcutRecorderWindowController: NSWindowController, NSWindowDelegate {
    private var recorderView: ShortcutRecorderView!
    private var previewLabel: NSTextField!
    private var confirmButton: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Set Shortcut"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        self.init(window: window)
        window.delegate = self

        let instructions = NSTextField(labelWithString: "Hold your modifier keys, then press a key.\nPress a new combo any time to change it.\nPress Return to confirm, Esc to cancel.")
        instructions.alignment = .center
        instructions.maximumNumberOfLines = 0

        let preview = NSTextField(labelWithString: "…")
        preview.alignment = .center
        preview.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        previewLabel = preview

        let confirm = NSButton(title: "Confirm", target: nil, action: nil)
        confirm.bezelStyle = .rounded
        confirm.isEnabled = false
        confirm.keyEquivalent = "\r"
        confirmButton = confirm

        let stack = NSStackView(views: [instructions, preview, confirm])
        stack.orientation = .vertical
        stack.spacing = 18
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.alignment = .centerX
        stack.setHuggingPriority(.defaultHigh, for: .vertical)

        let view = ShortcutRecorderView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        recorderView = view
        window.contentView = view

        view.onLiveUpdate = { [weak self] text in
            self?.previewLabel.stringValue = text
        }
        view.onCandidateReady = { [weak self] ready in
            self?.confirmButton.isEnabled = ready
        }
        view.onConfirm = { [weak self] in
            self?.confirmTapped()
        }

        confirm.target = self
        confirm.action = #selector(confirmTapped)
    }

    @objc private func confirmTapped() {
        guard let keyCode = recorderView.pendingKeyCode else { return }
        ShortcutStore.shared.current = Shortcut(flags: recorderView.pendingFlags, keyCode: keyCode)
        window?.close()
    }

    func show() {
        HotkeyManager.isRecordingShortcut = true
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let view = recorderView {
            window?.makeFirstResponder(view)
        }
    }

    func windowWillClose(_ notification: Notification) {
        HotkeyManager.isRecordingShortcut = false
    }
}
