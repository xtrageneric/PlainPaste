import SwiftUI

@main
struct PlainPasteApp: App {
    @ObservedObject private var shortcutStore = ShortcutStore.shared
    @ObservedObject private var iconStore = IconStore.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager()
    @ObservedObject private var sparkleSettings = SparkleSettings.shared
    @ObservedObject private var permissionMonitor = PermissionMonitor.shared
    let hotkeyManager = HotkeyManager()
    let appState = AppState()

    init() {
        hotkeyManager.start()
        let appState = self.appState

        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            appState.showOnboardingIfNeeded()
        }
    }

    var body: some Scene {
        MenuBarExtra("PlainPaste", systemImage: iconStore.current) {
            if !permissionMonitor.isTrusted {
                Text("⚠️ Accessibility access is missing — the shortcut won't work.")
                Button("Open Accessibility Settings...") {
                    permissionMonitor.openAccessibilitySettings()
                }
                Divider()
            }

            Text("Shortcut: \(shortcutStore.current.displayString)")

            Button("Customize Shortcut...") {
                appState.showShortcutRecorder()
            }

            Divider()

            Menu("Menu Bar Icon") {
                ForEach(IconStore.iconOptions, id: \.symbolName) { option in
                    Button {
                        iconStore.current = option.symbolName
                    } label: {
                        Label(option.displayName, systemImage: option.symbolName)
                    }
                    .labelStyle(.titleAndIcon)
                }
            }

            Button(launchAtLogin.isEnabled ? "✓ Launch at Login" : "Launch at Login") {
                launchAtLogin.toggle()
            }

            Divider()

            Button(sparkleSettings.isEnabled ? "✓ Sparkle Effect" : "Sparkle Effect") {
                sparkleSettings.isEnabled.toggle()
            }

            Menu("Sparkle Color") {
                ForEach(SparkleSettings.colorOptions, id: \.name) { option in
                    Button {
                        sparkleSettings.colorName = option.name
                    } label: {
                        Label {
                            Text(option.name == sparkleSettings.colorName ? "✓ \(option.name)" : option.name)
                        } icon: {
                            if let preview = sparklePreviewImage(color: option.color) {
                                Image(nsImage: preview)
                            }
                        }
                    }
                    .labelStyle(.titleAndIcon)
                }

                Divider()

                Button {
                    ColorPickerBridge.shared.showPicker()
                } label: {
                    Text(sparkleSettings.colorName == SparkleSettings.customColorName ? "✓ Custom Color..." : "Custom Color...")
                }
            }

            Menu("Sparkle Animation") {
                ForEach(SparkleAnimationStyle.allCases, id: \.self) { style in
                    Button(style == sparkleSettings.style ? "✓ \(style.rawValue)" : style.rawValue) {
                        sparkleSettings.style = style
                    }
                    .onHover { hovering in
                        if hovering {
                            showMagicSparkleEffect(at: NSEvent.mouseLocation, styleOverride: style)
                        }
                    }
                }
            }

            Divider()

            Button("Reset to Defaults") {
                appState.resetToDefaults()
            }

            Divider()

            Text("PlainPaste v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                .foregroundStyle(.secondary)

            Button("Quit PlainPaste") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
