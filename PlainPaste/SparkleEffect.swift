import AppKit
import Combine
import QuartzCore

func tintedSymbolImage(_ image: NSImage?, color: NSColor) -> NSImage? {
    guard let image = image else { return nil }
    let tinted = NSImage(size: image.size)
    tinted.lockFocus()
    color.set()
    let rect = NSRect(origin: .zero, size: image.size)
    rect.fill()
    image.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1.0)
    tinted.unlockFocus()
    return tinted
}

func sparklePreviewImage(color: NSColor, pointSize: CGFloat = 13) -> NSImage? {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
    let symbol = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
    let tinted = tintedSymbolImage(symbol, color: color)
    // Explicitly non-template so menu chrome doesn't flatten it to a monochrome silhouette.
    tinted?.isTemplate = false
    return tinted
}

enum SparkleAnimationStyle: String, CaseIterable, Codable {
    case burst = "Burst"
    case rise = "Rising Dust"
    case twinkle = "Twinkle"
}

struct SparkleColorOption {
    let name: String
    let color: NSColor
}

final class SparkleSettings: ObservableObject {
    static let shared = SparkleSettings()
    static let customColorName = "Custom"

    private let enabledKey = "PlainPasteSparkleEnabled"
    private let colorKey = "PlainPasteSparkleColorName"
    private let styleKey = "PlainPasteSparkleStyle"
    private let customRedKey = "PlainPasteSparkleCustomRed"
    private let customGreenKey = "PlainPasteSparkleCustomGreen"
    private let customBlueKey = "PlainPasteSparkleCustomBlue"

    static let colorOptions: [SparkleColorOption] = [
        SparkleColorOption(name: "Magenta", color: NSColor(calibratedRed: 0.90, green: 0.20, blue: 0.68, alpha: 1.0)),
        SparkleColorOption(name: "Gold", color: NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.25, alpha: 1.0)),
        SparkleColorOption(name: "Silver", color: NSColor(calibratedRed: 0.82, green: 0.84, blue: 0.90, alpha: 1.0)),
        SparkleColorOption(name: "Black", color: NSColor(calibratedWhite: 0.05, alpha: 1.0))
    ]

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }
    @Published var colorName: String {
        didSet { UserDefaults.standard.set(colorName, forKey: colorKey) }
    }
    @Published var style: SparkleAnimationStyle {
        didSet { UserDefaults.standard.set(style.rawValue, forKey: styleKey) }
    }
    @Published var customRed: Double {
        didSet { UserDefaults.standard.set(customRed, forKey: customRedKey) }
    }
    @Published var customGreen: Double {
        didSet { UserDefaults.standard.set(customGreen, forKey: customGreenKey) }
    }
    @Published var customBlue: Double {
        didSet { UserDefaults.standard.set(customBlue, forKey: customBlueKey) }
    }

    var currentColor: NSColor {
        if colorName == SparkleSettings.customColorName {
            return NSColor(calibratedRed: customRed, green: customGreen, blue: customBlue, alpha: 1.0)
        }
        return SparkleSettings.colorOptions.first(where: { $0.name == colorName })?.color
            ?? SparkleSettings.colorOptions[0].color
    }

    func setCustomColor(_ color: NSColor) {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        customRed = Double(rgb.redComponent)
        customGreen = Double(rgb.greenComponent)
        customBlue = Double(rgb.blueComponent)
        colorName = SparkleSettings.customColorName
    }

    private init() {
        if UserDefaults.standard.object(forKey: enabledKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }
        colorName = UserDefaults.standard.string(forKey: colorKey) ?? "Magenta"
        style = SparkleAnimationStyle(rawValue: UserDefaults.standard.string(forKey: styleKey) ?? "") ?? .burst
        customRed = UserDefaults.standard.object(forKey: customRedKey) as? Double ?? 0.90
        customGreen = UserDefaults.standard.object(forKey: customGreenKey) as? Double ?? 0.20
        customBlue = UserDefaults.standard.object(forKey: customBlueKey) as? Double ?? 0.68
    }
}

final class ColorPickerBridge: NSObject {
    static let shared = ColorPickerBridge()

    func showPicker() {
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.color = SparkleSettings.shared.currentColor
        panel.isContinuous = true
        panel.center()
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        SparkleSettings.shared.setCustomColor(sender.color)
    }
}

func showMagicSparkleEffect(at screenPoint: NSPoint, styleOverride: SparkleAnimationStyle? = nil, colorOverride: NSColor? = nil) {
    guard styleOverride != nil || SparkleSettings.shared.isEnabled else { return }

    let size: CGFloat = 140
    let windowRect = NSRect(
        x: screenPoint.x - size / 2,
        y: screenPoint.y - size / 2,
        width: size,
        height: size
    )

    let window = NSWindow(
        contentRect: windowRect,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .screenSaver
    window.ignoresMouseEvents = true
    window.hasShadow = false
    window.isReleasedWhenClosed = false
    window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

    let contentView = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
    contentView.wantsLayer = true
    window.contentView = contentView

    guard let rootLayer = contentView.layer else { return }

    let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .bold)
    let sparkleSymbol = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
    let tinted = tintedSymbolImage(sparkleSymbol, color: colorOverride ?? SparkleSettings.shared.currentColor)
    let sparkleCGImage = tinted?.cgImage(forProposedRect: nil, context: nil, hints: nil)

    let center = CGPoint(x: size / 2, y: size / 2)
    let sparkleCount = 8
    let style = styleOverride ?? SparkleSettings.shared.style

    for i in 0..<sparkleCount {
        let startPoint: CGPoint
        let endPoint: CGPoint

        switch style {
        case .burst:
            let angle = (CGFloat(i) / CGFloat(sparkleCount)) * 2 * .pi + CGFloat.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 40...55)
            startPoint = center
            endPoint = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
        case .rise:
            let startXJitter = CGFloat.random(in: -15...15)
            let driftX = CGFloat.random(in: -25...25)
            startPoint = CGPoint(x: center.x + startXJitter, y: center.y - 15)
            endPoint = CGPoint(x: center.x + driftX, y: center.y + CGFloat.random(in: 50...70))
        case .twinkle:
            let jitterX = CGFloat.random(in: -18...18)
            let jitterY = CGFloat.random(in: -18...18)
            startPoint = CGPoint(x: center.x + jitterX, y: center.y + jitterY)
            endPoint = startPoint
        }

        let sparkleSize = CGFloat.random(in: 14...24)
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: sparkleSize, height: sparkleSize)
        layer.position = startPoint
        layer.contents = sparkleCGImage
        layer.opacity = 0
        rootLayer.addSublayer(layer)

        let moveAnim = CABasicAnimation(keyPath: "position")
        moveAnim.fromValue = NSValue(point: startPoint)
        moveAnim.toValue = NSValue(point: endPoint)

        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = [0, 1, 1, 0]
        opacityAnim.keyTimes = [0, 0.15, 0.6, 1]

        let scaleAnim = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnim.values = [0.3, 1.2, 1.0, 0.5]
        scaleAnim.keyTimes = [0, 0.3, 0.7, 1]

        let group = CAAnimationGroup()
        group.animations = [moveAnim, opacityAnim, scaleAnim]
        group.duration = 0.6
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.beginTime = CACurrentMediaTime() + Double(i) * 0.02

        layer.add(group, forKey: "sparkle")
    }

    window.orderFrontRegardless()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
        window.close()
    }
}
