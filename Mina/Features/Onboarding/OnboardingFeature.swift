import Foundation
import ComposableArchitecture

// MARK: - Onboarding Feature
// Parent reducer managing the complete onboarding flow

@Reducer
struct OnboardingFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Current step in onboarding
        var currentStep: OnboardingStep = .welcome
        
        /// Collected user data
        var data: OnboardingData = OnboardingData()
        
        /// Whether onboarding is complete
        var isComplete: Bool = false
        
        /// Animation direction for transitions
        var transitionDirection: TransitionDirection = .forward
        
        /// Loading state (for account creation)
        var isLoading: Bool = false
        
        /// Error message if any
        var errorMessage: String?
        
        /// Custom time picker visibility
        var showingTimePicker: Bool = false
        
        /// AI slider value (0.0 - 1.0)
        var aiSliderValue: Double = 0.5
        
        // MARK: Computed Properties
        
        /// Progress as percentage (0.0 - 1.0)
        var progress: Double {
            Double(currentStep.rawValue) / Double(OnboardingStep.totalSteps - 1)
        }
        
        /// Whether back button should be shown
        var showBackButton: Bool {
            currentStep != .welcome
        }
        
        /// Whether next button should be enabled
        var canProceed: Bool {
            switch currentStep {
            case .welcome:
                return true
            case .whyJournal:
                return data.motivation != nil
            case .experienceLevel:
                return data.experienceLevel != nil
            case .journalingGoal:
                return data.frequency != nil
            case .preferredTime, .topics, .privacySecurity, 
                 .healthSync, .notifications, .setupSummary:
                return true
            case .aiAssistance:
                return true // Always has a default value
            case .createAccount:
                return false // Handled separately by auth buttons
            }
        }
        
        /// Text for next button
        var nextButtonText: String {
            switch currentStep {
            case .welcome:
                return "Get Started"
            case .setupSummary:
                return "Continue"
            case .createAccount:
                return "" // No next button, auth buttons instead
            default:
                return "Next"
            }
        }
    }
    
    enum TransitionDirection: Equatable {
        case forward
        case backward
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Navigation
        case nextTapped
        case backTapped
        case skipTapped
        case goToStep(OnboardingStep)
        
        // Step 1: Welcome
        case getStartedTapped
        case signInTapped
        
        // Step 2: Why Journal
        case motivationSelected(JournalingMotivation)
        
        // Step 3: Experience Level
        case experienceLevelSelected(ExperienceLevel)
        
        // Step 4: Journaling Goal
        case frequencySelected(JournalingFrequency)
        
        // Step 5: Preferred Time
        case timePresetSelected(TimePreset)
        case customTimeChanged(Date)
        case showTimePicker(Bool)
        
        // Step 6: Topics
        case topicToggled(JournalTopic)
        case customTopicChanged(String)
        
        // Step 7: AI Assistance
        case aiSliderChanged(Double)
        
        // Step 8: Privacy & Security
        case passcodeToggled(Bool)
        
        // Step 9: Health Sync
        case healthSyncToggled(Bool)
        
        // Step 10: Notifications
        case notificationsToggled(Bool)
        case reminderTimeChanged(Date)
        
        // Step 11: Setup Summary
        case editPreferencesTapped
        
        // Step 12: Create Account
        case continueWithAppleTapped
        case continueWithGoogleTapped
        case continueWithEmailTapped
        case skipAccountTapped
        
        // Completion
        case completeOnboarding
        case onboardingCompleted
        
        // Error handling
        case errorOccurred(String)
        case clearError
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.notificationClient) var notificationClient
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            // MARK: Navigation
                
            case .nextTapped:
                return navigateForward(&state)
                
            case .backTapped:
                return navigateBackward(&state)
                
            case .skipTapped:
                // Skip optional steps
                return navigateForward(&state)
                
            case let .goToStep(step):
                state.transitionDirection = step.rawValue > state.currentStep.rawValue ? .forward : .backward
                state.currentStep = step
                return .none
                
            // MARK: Step 1: Welcome
                
            case .getStartedTapped:
                return navigateForward(&state)
                
            case .signInTapped:
                state.currentStep = .createAccount
                state.transitionDirection = .forward
                return .none
                
            // MARK: Step 2: Why Journal
                
            case let .motivationSelected(motivation):
                state.data.motivation = motivation
                return .none
                
            // MARK: Step 3: Experience Level
                
            case let .experienceLevelSelected(level):
                state.data.experienceLevel = level
                return .none
                
            // MARK: Step 4: Journaling Goal
                
            case let .frequencySelected(frequency):
                state.data.frequency = frequency
                return .none
                
            // MARK: Step 5: Preferred Time
                
            case let .timePresetSelected(preset):
                state.data.preferredTimePreset = preset.rawValue
                if preset != .custom {
                    state.data.preferredTime = preset.defaultTime
                }
                state.showingTimePicker = preset == .custom
                return .none
                
            case let .customTimeChanged(time):
                state.data.preferredTime = time
                state.data.reminderTime = time
                return .none
                
            case let .showTimePicker(show):
                state.showingTimePicker = show
                return .none
                
            // MARK: Step 6: Topics
                
            case let .topicToggled(topic):
                if state.data.topics.contains(topic) {
                    state.data.topics.remove(topic)
                } else {
                    state.data.topics.insert(topic)
                }
                return .none
                
            case let .customTopicChanged(text):
                state.data.customTopic = text
                return .none
                
            // MARK: Step 7: AI Assistance
                
            case let .aiSliderChanged(value):
                state.aiSliderValue = value
                state.data.aiLevel = AIAssistanceLevel.from(sliderValue: value)
                return .none
                
            // MARK: Step 8: Privacy & Security
                
            case let .passcodeToggled(enabled):
                state.data.enablePasscode = enabled
                return .none
                
            // MARK: Step 9: Health Sync
                
            case let .healthSyncToggled(enabled):
                state.data.syncHealth = enabled
                // HealthKit authorization is deferred to first use. The preference is saved here
                // during onboarding, and actual HKHealthStore.requestAuthorization() will be called
                // when the app first attempts to read/write health data (e.g., mood correlation).
                return .none
                
            // MARK: Step 10: Notifications
                
            case let .notificationsToggled(enabled):
                state.data.enableNotifications = enabled
                if enabled {
                    return .run { send in
                        let status = await notificationClient.requestAuthorization()
                        if !status.isAuthorized {
                            await send(.notificationsToggled(false))
                        }
                    }
                }
                return .none
                
            case let .reminderTimeChanged(time):
                state.data.reminderTime = time
                return .none
                
            // MARK: Step 11: Setup Summary
                
            case .editPreferencesTapped:
                state.currentStep = .whyJournal
                state.transitionDirection = .backward
                return .none
                
            // MARK: Step 12: Create Account
                
            case .continueWithAppleTapped:
                state.isLoading = true
                // Apple Sign In requires Apple Developer account setup with Sign in with Apple
                // capability, an associated App ID, and AuthenticationServices entitlement.
                // Using simulated flow until production entitlements are configured.
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.completeOnboarding)
                }
                
            case .continueWithGoogleTapped:
                state.isLoading = true
                // Google Sign In requires the GoogleSignIn SDK (via SPM/CocoaPods) and a
                // configured OAuth 2.0 client ID from the Google Cloud Console. The GIDSignIn
                // flow will replace this simulated delay once the SDK is integrated.
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.completeOnboarding)
                }
                
            case .continueWithEmailTapped:
                // Email auth requires a backend (Firebase Auth, custom server, etc.).
                // For now, skip directly to completing onboarding.
                return .send(.completeOnboarding)
                
            case .skipAccountTapped:
                return .send(.completeOnboarding)
                
            // MARK: Completion
                
            case .completeOnboarding:
                state.isLoading = false
                state.data.save()
                state.isComplete = true
                return .send(.onboardingCompleted)
                
            case .onboardingCompleted:
                // Parent reducer handles this
                return .none
                
            // MARK: Error Handling
                
            case let .errorOccurred(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateForward(_ state: inout State) -> Effect<Action> {
        guard let nextStep = OnboardingStep(rawValue: state.currentStep.rawValue + 1) else {
            return .send(.completeOnboarding)
        }
        state.transitionDirection = .forward
        state.currentStep = nextStep
        return .none
    }
    
    private func navigateBackward(_ state: inout State) -> Effect<Action> {
        guard let prevStep = OnboardingStep(rawValue: state.currentStep.rawValue - 1) else {
            return .none
        }
        state.transitionDirection = .backward
        state.currentStep = prevStep
        return .none
    }
}
