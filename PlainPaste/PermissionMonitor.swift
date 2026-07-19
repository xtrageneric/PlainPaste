import AppKit
import ApplicationServices
import Combine

final class PermissionMonitor: ObservableObject {
    static let shared = PermissionMonitor()

    @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()
    private var timer: Timer?

    private init() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.isTrusted = AXIsProcessTrusted()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
