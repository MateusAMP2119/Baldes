import SwiftUI

extension Color {
    // MARK: - Brand
    static let accentOrange = Color(hex: "F2742E")
    static let accentOrangeLight = Color(hex: "FFF0E8")
    static let shadowOrange = Color(hex: "D4581A")

    // MARK: - Accent Colors
    static let accentGreen = Color(hex: "22C55E")
    static let accentTeal = Color(hex: "14B8A6")
    static let accentBlue = Color(hex: "3B82F6")
    static let accentPurple = Color(hex: "8B5CF6")
    static let accentYellow = Color(hex: "F59E0B")
    static let accentIndigo = Color(hex: "6366F1")
    static let accentPink = Color(hex: "F472B6")

    // MARK: - Light Accent Backgrounds
    static let accentBlueLightBg = Color(hex: "D4E4F7")
    static let accentPurpleLightBg = Color(hex: "E8DEF5")
    static let accentGreenLight = Color(hex: "DCFCE7")

    // MARK: - Text
    static let textPrimary = Color(hex: "1A1A2E")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "B0B0B0")

    // MARK: - Backgrounds
    static let bgPage = Color.white
    static let bgMuted = Color(hex: "EDECEA")
    static let bgCard = Color.white
    static let bgTabBar = Color(hex: "F9F9F9", opacity: 0.91)

    // MARK: - Borders / Dividers
    static let borderStrong = Color(hex: "000000")
    static let borderLight = Color(hex: "E5E5EA")
    static let dividerColor = Color(hex: "E8E6E2")
    static let tabInactive = Color(hex: "A8A7A5")

    // MARK: - Shadows
    static let shadowSoft = Color.black.opacity(0.06)

    // MARK: - Activity Heatmap Levels
    static let heatLevel0 = Color(hex: "EDECEA")
    static let heatLevel1 = Color(hex: "FDD4B8")
    static let heatLevel2 = Color(hex: "F9A870")
    static let heatLevel3 = Color(hex: "F2742E")
}

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255.0
            g = Double((int >> 16) & 0xFF) / 255.0
            b = Double((int >> 8) & 0xFF) / 255.0
            let a = Double(int & 0xFF) / 255.0
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        default:
            r = 0; g = 0; b = 0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
