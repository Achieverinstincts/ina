import SwiftUI

// MARK: - Empty State View
// Shown when no entries exist for today
// Matches reference: "Start journaling..." placeholder text

struct EmptyStateView: View {
    
    /// Action when user taps to start writing
    var onStartWriting: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Placeholder text (matches reference)
            Text("Start journaling...")
                .font(.minaTitle3)
                .foregroundStyle(Color.minaTertiary)
            
            // Optional: Subtle hint
            Text("Tap below to write your first entry")
                .font(.minaCaption1)
                .foregroundStyle(Color.minaTertiary.opacity(0.7))
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onStartWriting?()
        }
    }
}

// MARK: - First Time User Empty State

struct FirstTimeEmptyStateView: View {
    
    var onStartWriting: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Welcome illustration placeholder
            ZStack {
                Circle()
                    .fill(Color.minaAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.pages")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.minaAccent)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Mina")
                    .font(.minaTitle2)
                    .foregroundStyle(Color.minaPrimary)
                
                Text("Your thoughts, captured beautifully.\nStart your journaling journey today.")
                    .font(.minaBody)
                    .foregroundStyle(Color.minaSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: onStartWriting) {
                Text("Write First Entry")
                    .font(.minaHeadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.minaAccent)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview("Empty State") {
    EmptyStateView {
        print("Start writing tapped")
    }
    .background(Color.minaBackground)
}

#Preview("First Time User") {
    FirstTimeEmptyStateView {
        print("Write first entry tapped")
    }
    .background(Color.minaBackground)
}
