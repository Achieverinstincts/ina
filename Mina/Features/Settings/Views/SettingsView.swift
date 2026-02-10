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
        // Sign In Sheet
        .sheet(isPresented: Binding(
            get: { store.showingSignIn },
            set: { if !$0 { store.send(.dismissSignIn) } }
        )) {
            SignInSheet(store: store)
                .presentationDetents([.medium])
        }
        // Subscription Sheet
        .sheet(isPresented: Binding(
            get: { store.showingSubscription },
            set: { if !$0 { store.send(.dismissSubscription) } }
        )) {
            SubscriptionSheet(store: store)
                .presentationDetents([.medium, .large])
        }
        // Mood Picker Sheet
        .sheet(isPresented: Binding(
            get: { store.showingMoodPicker },
            set: { if !$0 { store.send(.dismissMoodPicker) } }
        )) {
            MoodPickerSheet(store: store)
                .presentationDetents([.medium])
        }
        // Export Options Sheet
        .sheet(isPresented: Binding(
            get: { store.showingExportOptions },
            set: { if !$0 { store.send(.dismissExportOptions) } }
        )) {
            ExportOptionsSheet(store: store)
                .presentationDetents([.medium])
        }
        // Share Sheet
        .sheet(isPresented: Binding(
            get: { store.showingShareSheet },
            set: { if !$0 { store.send(.dismissShareSheet) } }
        )) {
            ShareSheetView(items: ["Check out Mina - a beautiful journaling app!", URL(string: "https://apps.apple.com/app/mina") as Any])
                .presentationDetents([.medium])
        }
        // Sign Out Confirmation Alert
        .alert("Sign Out?", isPresented: Binding(
            get: { store.showingSignOutConfirmation },
            set: { if !$0 { store.send(.dismissSignOutConfirmation) } }
        )) {
            Button("Cancel", role: .cancel) {
                store.send(.dismissSignOutConfirmation)
            }
            Button("Sign Out", role: .destructive) {
                store.send(.confirmSignOut)
            }
        } message: {
            Text("Your data will remain on this device, but syncing will stop until you sign in again.")
        }
        // Clear Cache Confirmation Alert
        .alert("Clear Cache?", isPresented: Binding(
            get: { store.showingClearCacheConfirmation },
            set: { if !$0 { store.send(.dismissClearCacheConfirmation) } }
        )) {
            Button("Cancel", role: .cancel) {
                store.send(.dismissClearCacheConfirmation)
            }
            Button("Clear Cache", role: .destructive) {
                store.send(.confirmClearCache)
            }
        } message: {
            Text("This will remove cached images and temporary files. Your journal entries will not be affected.")
        }
        // Change Passcode Alert
        .alert("Change Passcode", isPresented: Binding(
            get: { store.showingChangePasscodeAlert },
            set: { if !$0 { store.send(.dismissChangePasscodeAlert) } }
        )) {
            Button("OK") {
                store.send(.dismissChangePasscodeAlert)
            }
        } message: {
            Text("Passcode management is coming in a future update. Stay tuned!")
        }
        // Cache Cleared Overlay
        .overlay {
            if store.cacheClearedFeedback {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("Cache cleared successfully")
                            .font(.minaSubheadline)
                            .foregroundStyle(Color.minaPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: store.cacheClearedFeedback)
            }
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
                // Signed in state - profile row
                SettingsRow(
                    icon: "person.circle.fill",
                    iconColor: .blue,
                    title: store.userName ?? "User",
                    subtitle: store.userEmail
                ) {
                    // No-op, just displays info
                }
                
                Divider()
                    .padding(.leading, 56)
                
                // Sign Out button
                Button {
                    store.send(.signOutTapped)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)
                            .frame(width: 28, height: 28)
                        
                        Text("Sign Out")
                            .font(.minaBody)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
            
            Divider()
                .padding(.leading, 56)
            
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
            
            Divider()
                .padding(.leading, 56)
            
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
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(
                    icon: "clock.fill",
                    iconColor: .purple,
                    title: "Reminder Time",
                    value: formattedTime(store.reminderTime)
                ) {
                    store.send(.reminderTimeTapped)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Divider()
                .padding(.leading, 56)
            
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
        .animation(.easeInOut(duration: 0.25), value: store.dailyReminderEnabled)
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
            
            Divider()
                .padding(.leading, 56)
            
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
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(
                    icon: "key.fill",
                    iconColor: .orange,
                    title: "Change Passcode"
                ) {
                    store.send(.changePasscodeTapped)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.passcodeEnabled)
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
            
            Divider()
                .padding(.leading, 56)
            
            SettingsRow(
                icon: "trash.fill",
                iconColor: .gray,
                title: "Clear Cache",
                subtitle: store.storageUsed
            ) {
                store.send(.clearCacheTapped)
            }
            
            Divider()
                .padding(.leading, 56)
            
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
            
            Divider()
                .padding(.leading, 56)
            
            SettingsRow(
                icon: "square.and.arrow.up",
                iconColor: .blue,
                title: "Share Mina"
            ) {
                store.send(.shareAppTapped)
            }
            
            Divider()
                .padding(.leading, 56)
            
            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .gray,
                title: "Terms of Service"
            ) {
                store.send(.termsOfServiceTapped)
            }
            
            Divider()
                .padding(.leading, 56)
            
            SettingsRow(
                icon: "hand.raised.fill",
                iconColor: .green,
                title: "Privacy Policy"
            ) {
                store.send(.privacyPolicyTapped)
            }
            
            Divider()
                .padding(.leading, 56)
            
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .purple,
                title: "Help & Support"
            ) {
                store.send(.helpAndSupportTapped)
            }
            
            Divider()
                .padding(.leading, 56)
            
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

// MARK: - Sign In Sheet

struct SignInSheet: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "icloud.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.minaAccent)
                
                VStack(spacing: 8) {
                    Text("Sign in to Mina")
                        .font(.minaTitle2)
                        .foregroundStyle(Color.minaPrimary)
                    
                    Text("Sync your journal entries across all your devices securely.")
                        .font(.minaBody)
                        .foregroundStyle(Color.minaSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Apple Sign In placeholder
                Button {
                    // Apple Sign In requires Apple Developer Program entitlements and ASAuthorizationController setup.
                    // For now, dismiss the sheet. Wire up AuthenticationServices when credentials are configured.
                    store.send(.dismissSignIn)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .font(.minaHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.minaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            .background(Color.minaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { store.send(.dismissSignIn) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Sign In")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
    }
}

// MARK: - Subscription Sheet

struct SubscriptionSheet: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Plan
                    VStack(spacing: 12) {
                        Image(systemName: store.subscriptionStatus.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(Color.minaAccent)
                        
                        Text("Current Plan")
                            .font(.minaCaption)
                            .foregroundStyle(Color.minaSecondary)
                        
                        Text(store.subscriptionStatus.displayName)
                            .font(.minaTitle2)
                            .foregroundStyle(Color.minaPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.minaCardSolid)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Premium features list
                    VStack(alignment: .leading, spacing: 0) {
                        subscriptionFeatureRow(icon: "infinity", title: "Unlimited Entries", included: true)
                        Divider().padding(.leading, 56)
                        subscriptionFeatureRow(icon: "photo.on.rectangle.angled", title: "Photo Attachments", included: true)
                        Divider().padding(.leading, 56)
                        subscriptionFeatureRow(icon: "lock.icloud.fill", title: "Cloud Sync", included: store.subscriptionStatus != .free)
                        Divider().padding(.leading, 56)
                        subscriptionFeatureRow(icon: "chart.bar.fill", title: "Advanced Insights", included: store.subscriptionStatus == .premiumPlus)
                        Divider().padding(.leading, 56)
                        subscriptionFeatureRow(icon: "paintbrush.fill", title: "Custom Themes", included: store.subscriptionStatus == .premiumPlus)
                    }
                    .background(Color.minaCardSolid)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    if store.subscriptionStatus == .free {
                        // Upgrade button
                        Button {
                            // StoreKit 2 subscription purchase requires App Store Connect product setup.
                            // Wire up Product.purchase() when subscription products are configured.
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                Text("Upgrade to Premium")
                            }
                            .font(.minaHeadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.minaAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
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
                    Button(action: { store.send(.dismissSubscription) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Subscription")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
    }
    
    private func subscriptionFeatureRow(icon: String, title: String, included: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(included ? Color.minaAccent : Color.minaSecondary)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.minaBody)
                .foregroundStyle(Color.minaPrimary)
            
            Spacer()
            
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 18))
                .foregroundStyle(included ? Color.green : Color.minaSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Mood Picker Sheet

struct MoodPickerSheet: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Choose a default mood for new entries")
                        .font(.minaBody)
                        .foregroundStyle(Color.minaSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(SettingsFeature.availableMoods, id: \.name) { mood in
                            Button {
                                store.send(.moodSelected(mood.name))
                            } label: {
                                VStack(spacing: 6) {
                                    if mood.emoji.isEmpty {
                                        Image(systemName: "circle.dashed")
                                            .font(.system(size: 32))
                                            .foregroundStyle(Color.minaSecondary)
                                            .frame(height: 40)
                                    } else {
                                        Text(mood.emoji)
                                            .font(.system(size: 32))
                                            .frame(height: 40)
                                    }
                                    
                                    Text(mood.name)
                                        .font(.minaCaption)
                                        .foregroundStyle(store.defaultMood == mood.name ? Color.minaAccent : Color.minaSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    store.defaultMood == mood.name
                                        ? Color.minaAccent.opacity(0.1)
                                        : Color.minaCardSolid
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(store.defaultMood == mood.name ? Color.minaAccent : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.minaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { store.send(.dismissMoodPicker) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Default Mood")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Choose a format to export your journal entries")
                        .font(.minaBody)
                        .foregroundStyle(Color.minaSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(SettingsFeature.ExportFormat.allCases) { format in
                            Button {
                                store.send(.exportFormatSelected(format))
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: format.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.minaAccent)
                                        .frame(width: 28, height: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(format.rawValue)
                                            .font(.minaBody)
                                            .foregroundStyle(Color.minaPrimary)
                                        
                                        Text(format.description)
                                            .font(.minaCaption)
                                            .foregroundStyle(Color.minaSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.minaTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if format != SettingsFeature.ExportFormat.allCases.last {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.minaCardSolid)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    
                    // Info footer
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("Exported data includes all journal entries and associated metadata.")
                            .font(.minaCaption)
                    }
                    .foregroundStyle(Color.minaSecondary)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.minaBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { store.send(.dismissExportOptions) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.minaPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Export Data")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
            }
        }
    }
}

// MARK: - Share Sheet (UIKit Wrapper)

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
