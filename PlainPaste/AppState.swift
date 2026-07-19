import Foundation

final class AppState {
    private var recorderController: ShortcutRecorderWindowController?
    private var onboardingController: OnboardingWindowController?
    private var hasAttemptedOnboarding = false

    func showShortcutRecorder() {
        let controller = ShortcutRecorderWindowController()
        recorderController = controller
        controller.show()
    }

    func showOnboardingIfNeeded() {
        guard !hasAttemptedOnboarding else { return }
        guard !UserDefaults.standard.bool(forKey: OnboardingWindowController.hasOnboardedKey) else { return }
        hasAttemptedOnboarding = true
        let controller = OnboardingWindowController()
        onboardingController = controller
        controller.show()
    }

    func resetToDefaults() {
        ShortcutStore.shared.current = Shortcut.defaultShortcut
        IconStore.shared.current = IconStore.defaultSymbolName
        SparkleSettings.shared.isEnabled = true
        SparkleSettings.shared.colorName = "Magenta"
        SparkleSettings.shared.style = .burst
    }
}
