import Foundation
import Combine

struct MenuBarIconOption {
    let symbolName: String
    let displayName: String
}

final class IconStore: ObservableObject {
    static let shared = IconStore()
    static let defaultSymbolName = "wand.and.stars"
    private let defaultsKey = "PlainPasteMenuBarIcon"

    static let iconOptions: [MenuBarIconOption] = [
        MenuBarIconOption(symbolName: "wand.and.stars", displayName: "Poof, No Formatting"),
        MenuBarIconOption(symbolName: "doc.plaintext", displayName: "Plain Jane"),
        MenuBarIconOption(symbolName: "clipboard", displayName: "Clippy"),
        MenuBarIconOption(symbolName: "scissors", displayName: "Snip Snip"),
        MenuBarIconOption(symbolName: "face.smiling", displayName: "Happy Paste"),
        MenuBarIconOption(symbolName: "flame.fill", displayName: "Spicy Paste"),
        MenuBarIconOption(symbolName: "sparkles", displayName: "Magic Paste"),
        MenuBarIconOption(symbolName: "ladybug.fill", displayName: "Squash the Formatting")
    ]

    @Published var current: String {
        didSet { UserDefaults.standard.set(current, forKey: defaultsKey) }
    }

    private init() {
        current = UserDefaults.standard.string(forKey: defaultsKey) ?? IconStore.defaultSymbolName
    }
}
