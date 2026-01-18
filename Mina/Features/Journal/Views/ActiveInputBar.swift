import SwiftUI
import ComposableArchitecture

// MARK: - Active Input Bar
// Keyboard accessory with AI, mic, camera, scan, attach, and dismiss buttons

struct ActiveInputBar: View {
    
    @Bindable var store: StoreOf<ActiveInputFeature>
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT: AI Sparkle Menu
            AISparkleButton(store: store)
            
            Spacer()
            
            // CENTER: Input action buttons
            HStack(spacing: 20) {
                // Mic button
                MicButton(store: store)
                
                // Camera button
                Button {
                    store.send(.cameraTapped)
                } label: {
                    Text("📷")
                        .font(.title2)
                }
                
                // Scan button
                Button {
                    store.send(.scanTapped)
                } label: {
                    Text("📄")
                        .font(.title2)
                }
                
                // Attach button
                Button {
                    store.send(.attachTapped)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            Spacer()
            
            // RIGHT: Dismiss keyboard
            Button {
                store.send(.dismissKeyboardTapped)
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.title2)
                    .foregroundStyle(Color.minaSecondary)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - AI Sparkle Button

private struct AISparkleButton: View {
    
    @Bindable var store: StoreOf<ActiveInputFeature>
    
    var body: some View {
        Menu {
            Button {
                store.send(.generateTitleSelected)
            } label: {
                Label("Generate Title", systemImage: "textformat")
            }
            
            Button {
                store.send(.writingPromptSelected)
            } label: {
                Label("Writing Prompt", systemImage: "lightbulb")
            }
            
            Button {
                store.send(.continueWritingSelected)
            } label: {
                Label("Continue Writing", systemImage: "text.append")
            }
        } label: {
            Text("✨")
                .font(.title2)
                .padding(8)
        }
    }
}

// MARK: - Mic Button

private struct MicButton: View {
    
    @Bindable var store: StoreOf<ActiveInputFeature>
    
    var body: some View {
        Button {
            store.send(.micTapped)
        } label: {
            ZStack {
                Text("🎙️")
                    .font(.title2)
                
                // Recording indicator
                if store.isRecording {
                    Circle()
                        .stroke(Color.minaError, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .scaleEffect(store.recordingPulse ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                            value: store.recordingPulse
                        )
                }
            }
        }
    }
}

// MARK: - Standalone Active Input Bar (for non-keyboard use)

struct StandaloneActiveInputBar: View {
    
    @Bindable var store: StoreOf<ActiveInputFeature>
    
    var body: some View {
        HStack(spacing: 0) {
            // AI Sparkle
            AISparkleButton(store: store)
            
            Spacer()
            
            // Center actions
            HStack(spacing: 20) {
                MicButton(store: store)
                
                Button { store.send(.cameraTapped) } label: {
                    Text("📷").font(.title2)
                }
                
                Button { store.send(.scanTapped) } label: {
                    Text("📄").font(.title2)
                }
                
                Button { store.send(.attachTapped) } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            Spacer()
            
            // Dismiss (hidden in standalone mode)
            Color.clear
                .frame(width: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.minaCardSolid)
                .shadow(color: .minaShadow, radius: 4, y: 2)
        )
    }
}

// MARK: - Preview

#Preview("Keyboard Accessory") {
    VStack {
        Spacer()
        
        ActiveInputBar(
            store: Store(
                initialState: ActiveInputFeature.State()
            ) {
                ActiveInputFeature()
            }
        )
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Recording") {
    VStack {
        Spacer()
        
        ActiveInputBar(
            store: Store(
                initialState: ActiveInputFeature.State(
                    isRecording: true,
                    recordingDuration: 5,
                    recordingPulse: true
                )
            ) {
                ActiveInputFeature()
            }
        )
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Standalone") {
    ZStack {
        Color.minaBackground
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            StandaloneActiveInputBar(
                store: Store(
                    initialState: ActiveInputFeature.State()
                ) {
                    ActiveInputFeature()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}
