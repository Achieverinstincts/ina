import Foundation
import ComposableArchitecture

// MARK: - Active Input Feature
// Reducer for the floating input bar / keyboard accessory

@Reducer
struct ActiveInputFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Whether voice recording is active
        var isRecording: Bool = false
        
        /// Recording duration in seconds
        var recordingDuration: TimeInterval = 0
        
        /// Pulse animation state
        var recordingPulse: Bool = false
        
        /// Whether AI menu is expanded
        var isAIMenuExpanded: Bool = false
        
        /// Currently showing picker
        var activeSheet: InputSheet?
        
        /// Transcribed text from voice
        var transcribedText: String = ""
        
        /// Whether transcription is in progress
        var isTranscribing: Bool = false
        
        /// Error message
        var errorMessage: String?
    }
    
    enum InputSheet: Equatable {
        case camera
        case scanner
        case filePicker
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Input bar button taps
        case aiSparkleTapped
        case micTapped
        case cameraTapped
        case scanTapped
        case attachTapped
        case dismissKeyboardTapped
        
        // AI menu actions
        case aiMenuDismissed
        case generateTitleSelected
        case writingPromptSelected
        case continueWritingSelected
        
        // Voice recording
        case startRecording
        case stopRecording
        case recordingTick
        case recordingCompleted(Data)
        case recordingFailed(String)
        
        // Transcription
        case transcriptionStarted
        case transcriptionUpdated(String)
        case transcriptionCompleted(String)
        case transcriptionFailed(String)
        
        // Sheet actions
        case showSheet(InputSheet)
        case sheetDismissed
        case photoCapture(Data)
        case scanCompleted(Data, String?) // Data + OCR text
        case fileSelected(Data, String)   // Data + filename
        
        // Entry creation trigger
        case startNewEntry
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            // MARK: Button Taps
                
            case .aiSparkleTapped:
                state.isAIMenuExpanded.toggle()
                return .none
                
            case .micTapped:
                if state.isRecording {
                    return .send(.stopRecording)
                } else {
                    return .send(.startRecording)
                }
                
            case .cameraTapped:
                return .send(.showSheet(.camera))
                
            case .scanTapped:
                return .send(.showSheet(.scanner))
                
            case .attachTapped:
                return .send(.showSheet(.filePicker))
                
            case .dismissKeyboardTapped:
                // Handled by view (resignFirstResponder)
                return .none
                
            // MARK: AI Menu
                
            case .aiMenuDismissed:
                state.isAIMenuExpanded = false
                return .none
                
            case .generateTitleSelected:
                state.isAIMenuExpanded = false
                // Parent reducer handles this
                return .none
                
            case .writingPromptSelected:
                state.isAIMenuExpanded = false
                // Parent reducer handles this
                return .none
                
            case .continueWritingSelected:
                state.isAIMenuExpanded = false
                // Parent reducer handles this
                return .none
                
            // MARK: Voice Recording
                
            case .startRecording:
                state.isRecording = true
                state.recordingDuration = 0
                state.recordingPulse = true
                state.transcribedText = ""
                
                // Start recording timer
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.recordingTick)
                    }
                }
                .cancellable(id: CancelID.recordingTimer, cancelInFlight: true)
                
            case .stopRecording:
                state.isRecording = false
                state.recordingPulse = false
                
                return .merge(
                    .cancel(id: CancelID.recordingTimer),
                    // Parent JournalFeature handles actual audio recording stop
                    .run { send in
                        // Simulated recording data
                        await send(.recordingCompleted(Data()))
                    }
                )
                
            case .recordingTick:
                state.recordingDuration += 1
                state.recordingPulse.toggle()
                return .none
                
            case let .recordingCompleted(data):
                state.isRecording = false
                // Parent JournalFeature handles transcription of the recorded audio
                return .send(.transcriptionStarted)
                
            case let .recordingFailed(message):
                state.isRecording = false
                state.recordingPulse = false
                state.errorMessage = message
                return .cancel(id: CancelID.recordingTimer)
                
            // MARK: Transcription
                
            case .transcriptionStarted:
                state.isTranscribing = true
                return .none
                
            case let .transcriptionUpdated(text):
                state.transcribedText = text
                return .none
                
            case let .transcriptionCompleted(text):
                state.isTranscribing = false
                state.transcribedText = text
                return .none
                
            case let .transcriptionFailed(message):
                state.isTranscribing = false
                state.errorMessage = message
                return .none
                
            // MARK: Sheet Actions
                
            case let .showSheet(sheet):
                state.activeSheet = sheet
                return .none
                
            case .sheetDismissed:
                state.activeSheet = nil
                return .none
                
            case let .photoCapture(data):
                state.activeSheet = nil
                // Parent handles attachment
                return .none
                
            case let .scanCompleted(data, ocrText):
                state.activeSheet = nil
                // Parent handles attachment
                return .none
                
            case let .fileSelected(data, filename):
                state.activeSheet = nil
                // Parent handles attachment
                return .none
                
            // MARK: Entry Creation
                
            case .startNewEntry:
                // Parent reducer handles this
                return .none
            }
        }
    }
    
    // MARK: - Cancel IDs
    
    enum CancelID {
        case recordingTimer
        case transcription
    }
}

// MARK: - Recording Duration Formatter

extension TimeInterval {
    var recordingFormatted: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
