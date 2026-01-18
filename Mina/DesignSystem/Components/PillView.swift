import SwiftUI

// MARK: - Pill View Component
// Reusable capsule-shaped container matching reference design

struct PillView<Content: View>: View {
    let content: Content
    var backgroundColor: Color
    var shadowEnabled: Bool
    var padding: EdgeInsets
    
    init(
        backgroundColor: Color = .minaCardSolid,
        shadowEnabled: Bool = true,
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.shadowEnabled = shadowEnabled
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .shadow(
                        color: shadowEnabled ? .minaShadow : .clear,
                        radius: shadowEnabled ? 2 : 0,
                        x: 0,
                        y: shadowEnabled ? 1 : 0
                    )
            )
    }
}

// MARK: - Convenience Initializers

extension PillView where Content == Text {
    /// Simple text pill
    init(_ text: String, backgroundColor: Color = .minaCardSolid) {
        self.init(backgroundColor: backgroundColor) {
            Text(text)
                .font(.minaPill)
                .foregroundStyle(Color.minaPrimary)
        }
    }
}

// MARK: - Pill Button Variant

struct PillButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    var backgroundColor: Color
    
    init(
        backgroundColor: Color = .minaCardSolid,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Button(action: action) {
            PillView(backgroundColor: backgroundColor) {
                content
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Pill Component

struct StreakPillView: View {
    let streak: Int
    let onSettingsTap: () -> Void
    
    var body: some View {
        PillView(
            padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        ) {
            HStack(spacing: 8) {
                // Streak counter
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(streak)")
                        .font(.minaStreak)
                        .foregroundStyle(Color.minaPrimary)
                }
                
                // Settings button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.minaSecondary)
                }
            }
        }
    }
}

// MARK: - Today Pill Component

struct TodayPillView: View {
    var body: some View {
        PillView {
            Text("Today")
                .font(.minaPill)
                .foregroundStyle(Color.minaPrimary)
        }
    }
}

// MARK: - Previews

#Preview("Pills") {
    VStack(spacing: 20) {
        TodayPillView()
        
        StreakPillView(streak: 12) {
            print("Settings tapped")
        }
        
        PillView {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("7 day streak!")
            }
        }
        
        PillButton(action: { print("Tapped") }) {
            Text("Tap me")
        }
    }
    .padding()
    .background(Color.minaBackground)
}
