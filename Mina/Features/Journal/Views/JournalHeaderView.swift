import SwiftUI

// MARK: - Journal Header View
// Matches reference: Logo (left), "Today" pill (center), Streak+Settings (right)

struct JournalHeaderView: View {
    
    let streak: Int
    let onLogoTap: () -> Void
    let onSettingsTap: () -> Void
    
    var body: some View {
        HStack {
            // LEFT: Logo / App Icon
            Button(action: onLogoTap) {
                LogoView()
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // CENTER: "Today" pill (static, matches reference)
            TodayPillView()
            
            Spacer()
            
            // RIGHT: Streak + Settings (in pill)
            StreakPillView(
                streak: streak,
                onSettingsTap: onSettingsTap
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Logo View

private struct LogoView: View {
    var body: some View {
        // Placeholder logo - replace with actual app icon
        ZStack {
            Circle()
                .fill(Color.minaBackground)
                .frame(width: 44, height: 44)
            
            // Stylized "M" for Mina
            Text("M")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.minaPrimary)
        }
        .overlay(
            Circle()
                .stroke(Color.minaDivider, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        JournalHeaderView(
            streak: 12,
            onLogoTap: { print("Logo tapped") },
            onSettingsTap: { print("Settings tapped") }
        )
        
        Spacer()
    }
    .background(Color.minaBackground)
}

#Preview("Zero Streak") {
    VStack {
        JournalHeaderView(
            streak: 0,
            onLogoTap: {},
            onSettingsTap: {}
        )
        
        Spacer()
    }
    .background(Color.minaBackground)
}
