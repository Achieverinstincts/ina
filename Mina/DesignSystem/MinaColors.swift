import SwiftUI

// MARK: - Mina Color Palette
// Design tokens matching the warm, minimalist aesthetic from reference

extension Color {
    
    // MARK: - Background Colors
    
    /// Primary app background - warm cream (#FDF8F3)
    static let minaBackground = Color(hex: "FDF8F3")
    
    /// Card/surface background - translucent white
    static let minaCardBackground = Color.white.opacity(0.6)
    
    /// Solid card background for elevated elements
    static let minaCardSolid = Color.white
    
    // MARK: - Text Colors
    
    /// Primary text - near black
    static let minaPrimary = Color(hex: "1A1A1A")
    
    /// Secondary text - muted gray
    static let minaSecondary = Color(hex: "8E8E93")
    
    /// Tertiary/placeholder text
    static let minaTertiary = Color(hex: "C7C7CC")
    
    // MARK: - Accent Colors
    
    /// Warm orange accent (streak, highlights)
    static let minaAccent = Color(hex: "FF6B35")
    
    /// AI sparkle color - purple gradient base
    static let minaAI = Color(hex: "8B5CF6")
    
    /// Success/positive - soft green
    static let minaSuccess = Color(hex: "34C759")
    
    /// Warning - amber
    static let minaWarning = Color(hex: "FF9500")
    
    /// Error/destructive - soft red
    static let minaError = Color(hex: "FF3B30")
    
    // MARK: - Semantic Colors
    
    /// Streak fire color
    static let minaStreak = Color(hex: "FF6B35")
    
    /// Divider/separator
    static let minaDivider = Color(hex: "E5E5EA")
    
    /// Shadow color
    static let minaShadow = Color.black.opacity(0.05)
}

// MARK: - Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Scheme Support

extension Color {
    /// Returns appropriate color for current color scheme
    /// For now, Mina uses light mode only (matching reference aesthetic)
    static func minaAdaptive(light: Color, dark: Color) -> Color {
        // TODO: Implement dark mode support
        return light
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// AI sparkle gradient
    static let minaAIGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Warm accent gradient
    static let minaAccentGradient = LinearGradient(
        colors: [Color(hex: "FF6B35"), Color(hex: "FF8C42")],
        startPoint: .leading,
        endPoint: .trailing
    )
}
