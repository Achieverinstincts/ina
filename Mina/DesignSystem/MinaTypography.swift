import SwiftUI

// MARK: - Mina Typography System
// SF Pro based type scale for iOS 17+

extension Font {
    
    // MARK: - Display
    
    /// Large title - 34pt bold
    static let minaLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Title 1 - 28pt bold
    static let minaTitle1 = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Title 2 - 22pt bold
    static let minaTitle2 = Font.system(size: 22, weight: .bold, design: .default)
    
    /// Title 3 - 20pt semibold
    static let minaTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body
    
    /// Headline - 17pt semibold (entry titles)
    static let minaHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Body - 17pt regular
    static let minaBody = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Callout - 16pt regular
    static let minaCallout = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Subheadline - 15pt regular (preview text)
    static let minaSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    // MARK: - Small
    
    /// Footnote - 13pt regular
    static let minaFootnote = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Caption 1 - 12pt regular (timestamps)
    static let minaCaption1 = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Caption alias
    static let minaCaption = minaCaption1
    
    /// Caption 2 - 11pt regular
    static let minaCaption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Special
    
    /// Pill label - 15pt semibold
    static let minaPill = Font.system(size: 15, weight: .semibold, design: .default)
    
    /// Streak counter - 16pt bold
    static let minaStreak = Font.system(size: 16, weight: .bold, design: .default)
    
    /// Input bar icons - 22pt
    static let minaInputIcon = Font.system(size: 22, weight: .regular, design: .default)
}

// MARK: - Text Style Modifiers

extension View {
    /// Primary text style
    func minaPrimaryText() -> some View {
        self
            .font(.minaBody)
            .foregroundStyle(Color.minaPrimary)
    }
    
    /// Secondary text style
    func minaSecondaryText() -> some View {
        self
            .font(.minaSubheadline)
            .foregroundStyle(Color.minaSecondary)
    }
    
    /// Headline text style (entry titles)
    func minaHeadlineText() -> some View {
        self
            .font(.minaHeadline)
            .foregroundStyle(Color.minaPrimary)
    }
    
    /// Caption text style (timestamps)
    func minaCaptionText() -> some View {
        self
            .font(.minaCaption1)
            .foregroundStyle(Color.minaSecondary)
    }
    
    /// Placeholder text style
    func minaPlaceholderText() -> some View {
        self
            .font(.minaTitle3)
            .foregroundStyle(Color.minaTertiary)
    }
}

// MARK: - Line Spacing

extension View {
    /// Standard body line spacing
    func minaBodySpacing() -> some View {
        self.lineSpacing(4)
    }
    
    /// Compact line spacing for lists
    func minaCompactSpacing() -> some View {
        self.lineSpacing(2)
    }
}
