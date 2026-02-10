import SwiftUI
import ComposableArchitecture

// MARK: - Settings View
// Main settings screen matching reference design

struct SettingsView: View {
    
    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeader
                    
                    // Account Section
                    accountSection
                    
                    // Journal Preferences Section
                    journalPreferencesSection
                    
                    // Privacy & Security Section
                    privacySecuritySection
                    
                    // Data & Storage Section
                    dataStorageSection
                    
                    // About Section
                    aboutSection
                    
                    // Version footer
                    versionFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.minaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: Binding(
            get: { store.showingTimePicker },
            set: { if !$0 { store.send(.dismissTimePicker) } }
        )) {
            TimePickerSheet(
                selectedTime: Binding(
                    get: { store.reminderTime },
                    set: { store.send(.reminderTimeChanged($0)) }
                ),
                onDismiss: { store.send(.dismissTimePicker) }
            )
            .presentationDetents([.height(300)])
        }
        .alert("Clear All Data?", isPresented: Binding(
            get: { store.showingClearDataConfirmation },
            set: { if !$0 { store.send(.dismissClearDataConfirmation) } }
        )) {
            Button("Cancel", role: .cancel) {
                store.send(.dismissClearDataConfirmation)
            }
            Button("Clear All", role: .destructive) {
                store.send(.confirmClearData)
            }
        } message: {
            Text("This will permanently delete all your journal entries and data. This action cannot be undone.")
        }
        .sheet(isPresented: Binding(
            get: { store.showingFeedback },
            set: { if !$0 { store.send(.dismissFeedback) } }
        )) {
            FeedbackSheet(store: store)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - App Header
    
    private var appHeader: some View {
        HStack(spacing: 16) {
            // App Icon
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.minaAccent, Color.minaAccent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay(
                    Text("🦫")
                        .font(.system(size: 36))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mina")
                    .font(.minaTitle2)
                    .foregroundStyle(Color.minaPrimary)
                
                Text("Version \(store.appVersion)")
                    .font(.minaCaption)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        SettingsSection(title: "Account") {
            if store.isSignedIn {
                // Signed in state
                SettingsRow(
                    icon: "person.circle.fill",
                    iconColor: .blue,
                    title: store.userName ?? "User",
                    subtitle: store.userEmail
                ) {
                    store.send(.signInTapped)
                }
            } else {
                // Sign in button
                SettingsRow(
                    icon: "person.circle",
                    iconColor: .blue,
                    title: "Sign In",
                    subtitle: "Sync your data across devices"
                ) {
                    store.send(.signInTapped)
                }
            }
            
            SettingsRow(
                icon: store.subscriptionStatus.icon,
                iconColor: .orange,
                title: "Subscription",
                value: store.subscriptionStatus.displayName
            ) {
                store.send(.subscriptionTapped)
            }
        }
    }
    
    // MARK: - Journal Preferences Section
    
    private var journalPreferencesSection: some View {
        SettingsSection(title: "Journal Preferences") {
            SettingsRow(
                icon: "face.smiling",
                iconColor: .yellow,
                title: "Default Mood",
                value: store.defaultMood
            ) {
                store.send(.defaultMoodTapped)
            }
            
            SettingsToggleRow(
                icon: "bell.fill",
                iconColor: .red,
                title: "Daily Reminder",
                isOn: Binding(
                    get: { store.dailyReminderEnabled },
                    set: { store.send(.reminderToggled($0)) }
                )
            )
            
            if store.dailyReminderEnabled {
                SettingsRow(
                    icon: "clock.fill",
                    iconColor: .purple,
                    title: "Reminder Time",
                    value: formattedTime(store.reminderTime)
                ) {
                    store.send(.reminderTimeTapped)
                }
            }
            
            SettingsToggleRow(
                icon: "calendar.badge.clock",
                iconColor: .green,
                title: "Weekly Reflection",
                isOn: Binding(
                    get: { store.weeklyReflectionEnabled },
                    set: { store.send(.weeklyReflectionToggled($0)) }
                )
            )
        }
    }
    
    // MARK: - Privacy & Security Section
    
    private var privacySecuritySection: some View {
        SettingsSection(title: "Privacy & Security") {
            SettingsToggleRow(
                icon: "faceid",
                iconColor: .blue,
                title: "Face ID",
                isOn: Binding(
                    get: { store.faceIDEnabled },
                    set: { store.send(.faceIDToggled($0)) }
                )
            )
            
            SettingsToggleRow(
                icon: "lock.fill",
                iconColor: .gray,
                title: "Passcode",
                isOn: Binding(
                    get: { store.passcodeEnabled },
                    set: { store.send(.passcodeToggled($0)) }
                )
            )
            
            if store.passcodeEnabled {
                SettingsRow(
                    icon: "key.fill",
                    iconColor: .orange,
                    title: "Change Passcode"
                ) {
                    store.send(.changePasscodeTapped)
                }
            }
        }
    }
    
    // MARK: - Data & Storage Section
    
    private var dataStorageSection: some View {
        SettingsSection(title: "Data & Storage") {
            SettingsRow(
                icon: "square.and.arrow.up.fill",
                iconColor: .blue,
                title: "Export Data",
                subtitle: "Download your journal entries"
            ) {
                store.send(.exportDataTapped)
            }
            
            SettingsRow(
                icon: "trash.fill",
                iconColor: .gray,
                title: "Clear Cache",
                subtitle: store.storageUsed
            ) {
                store.send(.clearCacheTapped)
            }
            
            SettingsRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Clear All Data",
                subtitle: "\(store.totalEntries) entries"
            ) {
                store.send(.clearAllDataTapped)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(
                icon: "star.fill",
                iconColor: .yellow,
                title: "Rate Mina"
            ) {
                store.send(.rateAppTapped)
            }
            
            SettingsRow(
                icon: "square.and.arrow.up",
                iconColor: .blue,
                title: "Share Mina"
            ) {
                store.send(.shareAppTapped)
            }
            
            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .gray,
                title: "Terms of Service"
            ) {
                store.send(.termsOfServiceTapped)
            }
            
            SettingsRow(
                icon: "hand.raised.fill",
                iconColor: .green,
                title: "Privacy Policy"
            ) {
                store.send(.privacyPolicyTapped)
            }
            
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .purple,
                title: "Help & Support"
            ) {
                store.send(.helpAndSupportTapped)
            }
            
            SettingsRow(
                icon: "envelope.fill",
                iconColor: .minaAccent,
                title: "Send Feedback",
                subtitle: "Help us improve Mina"
            ) {
                store.send(.sendFeedbackTapped)
            }
        }
    }
    
    // MARK: - Version Footer
    
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("Mina v\(store.appVersion) (\(store.buildNumber))")
                .font(.minaCaption)
                .foregroundStyle(Color.minaSecondary)
            
            Text("Made with 💜 for journalers")
                .font(.minaCaption)
                .foregroundStyle(Color.minaTertiary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.minaCaption)
                .foregroundStyle(Color.minaSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.minaCardSolid)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .blue
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.minaBody)
                        .foregroundStyle(Color.minaPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.minaCaption)
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
                
                Spacer()
                
                // Value
                if let value = value {
                    Text(value)
                        .font(.minaBody)
                        .foregroundStyle(Color.minaSecondary)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.minaTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    var iconColor: Color = .blue
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
            
            // Title
            Text(title)
                .font(.minaBody)
                .foregroundStyle(Color.minaPrimary)
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .tint(Color.minaAccent)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Reminder Time")
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .font(.minaBody)
                .foregroundStyle(Color.minaAccent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Time Picker
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Spacer()
        }
        .background(Color.minaBackground)
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheet: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @FocusState private var isMessageFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.minaCaption)
                            .foregroundStyle(Color.minaSecondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            ForEach(SettingsFeature.FeedbackCategory.allCases) { category in
                                Button {
                                    store.send(.feedbackCategoryChanged(category))
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(store.feedbackCategory == category ? Color.minaAccent : Color.minaSecondary)
                                            .frame(width: 28, height: 28)
                                        
                                        Text(category.rawValue)
                                            .font(.minaBody)
                                            .foregroundStyle(Color.minaPrimary)
                                        
                                        Spacer()
                                        
                                        if store.feedbackCategory == category {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Color.minaAccent)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if category != SettingsFeature.FeedbackCategory.allCases.last {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color.minaCardSolid)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // Message Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MESSAGE")
                            .font(.minaCaption)
                            .foregroundStyle(Color.minaSecondary)
                            .padding(.horizontal, 4)
                        
                        TextEditor(text: Binding(
                            get: { store.feedbackMessage },
                            set: { store.send(.feedbackMessageChanged($0)) }
                        ))
                        .focused($isMessageFocused)
                        .font(.minaBody)
                        .foregroundStyle(Color.minaPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color.minaCardSolid)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            if store.feedbackMessage.isEmpty {
                                Text("Tell us what's on your mind...")
                                    .font(.minaBody)
                                    .foregroundStyle(Color.minaTertiary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Submit Button
                    Button {
                        store.send(.submitFeedbackTapped)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Send Feedback")
                        }
                        .font(.minaHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            store.feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.minaSecondary
                                : Color.minaAccent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(store.feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    // Success message
                    if store.feedbackSubmitted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("Thank you for your feedback!")
                                .font(.minaSubheadline)
                                .foregroundStyle(Color.minaSecondary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.minaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { store.send(.dismissFeedback) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Send Feedback")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        store: Store(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        }
    )
}

#Preview("With Data") {
    SettingsView(
        store: Store(
            initialState: SettingsFeature.State(
                isSignedIn: true,
                userName: "Jane Doe",
                userEmail: "jane@example.com",
                subscriptionStatus: .premium,
                totalEntries: 127,
                storageUsed: "24.5 MB"
            )
        ) {
            SettingsFeature()
        }
    )
}
