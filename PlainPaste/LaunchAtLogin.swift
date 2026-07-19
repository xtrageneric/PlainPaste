import Foundation
import Combine
import ServiceManagement

final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            // If registration fails, isEnabled below will simply reflect the unchanged state.
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
