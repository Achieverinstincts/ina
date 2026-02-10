import SwiftUI
import UIKit

// MARK: - Mina Color Palette
// Design tokens matching the warm, minimalist aesthetic from reference
// Supports both light and dark mode via UIColor trait collection

extension Color {
    
    // MARK: - Background Colors
    
    /// Primary app background - warm cream (light) / near black (dark)
    static let minaBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x1A/255, green: 0x1A/255, blue: 0x1E/255, alpha: 1)
            : UIColor(red: 0xFD/255, green: 0xF8/255, blue: 0xF3/255, alpha: 1)
    })
    
    /// Card/surface background - translucent white (light) / translucent white (dark)
    static let minaCardBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor.white.withAlphaComponent(0.6)
    })
    
    /// Solid card background for elevated elements
    static let minaCardSolid = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x2C/255, green: 0x2C/255, blue: 0x2E/255, alpha: 1)
            : UIColor.white
    })
    
    // MARK: - Text Colors
    
    /// Primary text - near black (light) / near white (dark)
    static let minaPrimary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF5/255, alpha: 1)
            : UIColor(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255, alpha: 1)
    })
    
    /// Secondary text - muted gray
    static let minaSecondary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0xAE/255, green: 0xAE/255, blue: 0xB2/255, alpha: 1)
            : UIColor(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255, alpha: 1)
    })
    
    /// Tertiary/placeholder text
    static let minaTertiary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x48/255, green: 0x48/255, blue: 0x4A/255, alpha: 1)
            : UIColor(red: 0xC7/255, green: 0xC7/255, blue: 0xCC/255, alpha: 1)
    })
    
    // MARK: - Accent Colors
    
    /// Warm orange accent (streak, highlights) - same both modes
    static let minaAccent = Color(hex: "FF6B35")
    
    /// AI sparkle color - purple gradient base - same both modes
    static let minaAI = Color(hex: "8B5CF6")
    
    /// Success/positive - soft green - same both modes
    static let minaSuccess = Color(hex: "34C759")
    
    /// Warning - amber - same both modes
    static let minaWarning = Color(hex: "FF9500")
    
    /// Error/destructive - soft red - same both modes
    static let minaError = Color(hex: "FF3B30")
    
    // MARK: - Semantic Colors
    
    /// Streak fire color - same both modes
    static let minaStreak = Color(hex: "FF6B35")
    
    /// Divider/separator
    static let minaDivider = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x38/255, green: 0x38/255, blue: 0x3A/255, alpha: 1)
            : UIColor(red: 0xE5/255, green: 0xE5/255, blue: 0xEA/255, alpha: 1)
    })
    
    /// Shadow color
    static let minaShadow = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.20)
            : UIColor.black.withAlphaComponent(0.05)
    })
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
    /// Returns the appropriate color for the current interface style.
    /// Uses UIColor's dynamic provider to resolve at render time.
    static func minaAdaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
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
