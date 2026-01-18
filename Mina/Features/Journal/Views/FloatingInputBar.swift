import SwiftUI

// MARK: - Floating Input Bar
// Bottom floating pill that triggers entry creation
// Matches reference: floating pill at bottom of screen

struct FloatingInputBar: View {
    
    /// Action when user taps to start writing
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Hint text
                Text("What's on your mind?")
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
                
                Spacer()
                
                // Quick action icons
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(Color.minaSecondary)
                    
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.minaSecondary)
                }
                .font(.system(size: 16))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.minaCardSolid)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expanded Floating Input Bar
// Alternative version with more visible actions

struct ExpandedFloatingInputBar: View {
    
    var onWriteTap: () -> Void
    var onMicTap: () -> Void
    var onCameraTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Write button (primary)
            Button(action: onWriteTap) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Write")
                }
                .font(.minaSubheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.minaPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            // Divider
            Rectangle()
                .fill(Color.minaDivider)
                .frame(width: 1, height: 24)
            
            // Mic button
            Button(action: onMicTap) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.minaSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            
            // Camera button
            Button(action: onCameraTap) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.minaSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .background(
            Capsule()
                .fill(Color.minaCardSolid)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Floating Bar
// Alternative: Shows quick stats like in reference (streak, count, etc.)

struct StatsFloatingBar: View {
    
    let streak: Int
    let todayCount: Int
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Streak
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(streak)")
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 16)
                
                // Today's entries
                HStack(spacing: 4) {
                    Text("E")
                        .foregroundStyle(Color.minaAccent)
                    Text("\(todayCount)")
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Add button
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.minaAccent)
            }
            .font(.minaSubheadline)
            .foregroundStyle(Color.minaPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.minaCardSolid)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Floating Input Bar") {
    ZStack {
        Color.minaBackground
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            FloatingInputBar {
                print("Tapped")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

#Preview("Expanded") {
    ZStack {
        Color.minaBackground
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ExpandedFloatingInputBar(
                onWriteTap: {},
                onMicTap: {},
                onCameraTap: {}
            )
            .padding(.bottom, 8)
        }
    }
}

#Preview("Stats Bar") {
    ZStack {
        Color.minaBackground
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            StatsFloatingBar(streak: 7, todayCount: 3) {
                print("Tapped")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}
